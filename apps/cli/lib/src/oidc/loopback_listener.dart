/// Loopback HTTP listener for the PKCE authorization-code redirect.
///
/// Spike §A.1 (Python reference) → port to Dart. The listener is
/// **defensive** by design — Zitadel's hosted login UI is a Next.js
/// app that fires RSC prefetches before the user clicks anything, so a
/// naive one-shot HTTP server captures a phantom `code` with empty
/// `state` and the real `code` is then dropped on the floor. The defenses:
///
/// 1. **Multi-hit** — keep listening until a `GET /callback` arrives with
///    `state == expected` AND a non-empty `code`.
/// 2. **`_rsc=...` filter** — Next.js RSC prefetch carries this query
///    parameter; respond `204` and keep listening.
/// 3. **State CSRF guard** — empty or wrong `state` → `204`, keep listening.
/// 4. **Wrong path** → `404`, keep listening (and DO NOT log the query).
/// 5. **Wrong method** → `405`, keep listening.
/// 6. **Authorize error pass-through** — `?error=access_denied` etc. is
///    a terminal failure: surface a 4xx HTML page + complete with `Failure`.
/// 7. **Hard timeout** — 5 minutes default; cancel listener + complete with
///    `Failure`.
///
/// Logging discipline (spike §5.15): the optional logger MUST receive only
/// method + path + reason. Raw query strings, codes, and verifiers MUST
/// NEVER appear in log lines.
library;

import 'dart:async';
import 'dart:io';

import 'package:core_contracts/core_contracts.dart';

import '../config/oidc_config.dart';
import '../errors/cli_error.dart';

/// Defensive loopback HTTP server bound on `127.0.0.1` at an OS-assigned
/// port.
///
/// `class` (not `final class`) per W0 §4.3 — command-level orchestration
/// tests `implements LoopbackListener` to inject canned callback Results.
class LoopbackListener {
  LoopbackListener({
    required this.expectedState,
    this.timeout = OidcConfig.loopbackTimeout,
    void Function(String message)? logger,
  }) : _logger = logger;

  /// CSRF state token expected on the legitimate `/callback?state=...`.
  final String expectedState;

  /// Hard timeout — the listener completes with `Failure` if no
  /// legitimate callback arrives in this window.
  final Duration timeout;

  final void Function(String)? _logger;

  HttpServer? _server;
  bool _bound = false;

  /// Binds `127.0.0.1` with port 0 (OS-assigned) and returns the port.
  ///
  /// Throws [StateError] if called twice on the same instance.
  Future<int> bindEphemeralPort() async {
    if (_bound) {
      throw StateError('LoopbackListener.bindEphemeralPort called twice');
    }
    _bound = true;
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return _server!.port;
  }

  /// Listens for the legitimate `/callback?code=...&state=<expected>` and
  /// returns `Success(code)`. Returns `Failure(CliError)` on authorize
  /// error or timeout. Closes the server on terminal completion.
  Future<Result<String>> awaitCallback() async {
    final server = _server;
    if (server == null) {
      return const Failure(
        InvalidArgError('awaitCallback called before bindEphemeralPort'),
      );
    }

    final completer = Completer<Result<String>>();
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        _log('timeout after ${timeout.inSeconds}s');
        completer.complete(
          Failure<String>(
            NetworkError(
              'loopback callback timed out after ${timeout.inSeconds}s',
            ),
          ),
        );
      }
    });

    final subscription = server.listen((req) async {
      // Per-request handler. Never throws to the outer zone.
      try {
        await _handleRequest(req, completer);
      } on Object {
        // Defensive — any unexpected error closes the connection
        // gracefully and keeps the listener alive for the real callback.
        try {
          req.response.statusCode = HttpStatus.internalServerError;
          await req.response.close();
        } on Object {
          // Best-effort.
        }
      }
    });

    try {
      return await completer.future;
    } finally {
      timer.cancel();
      await subscription.cancel();
      try {
        await server.close(force: true);
      } on Object {
        // Best-effort cleanup.
      }
      _server = null;
    }
  }

  Future<void> _handleRequest(
    HttpRequest req,
    Completer<Result<String>> completer,
  ) async {
    final method = req.method;
    final path = req.uri.path;

    if (method != 'GET') {
      _log('drop $method $path -> wrong_method');
      req.response.statusCode = HttpStatus.methodNotAllowed;
      await req.response.close();
      return;
    }

    if (path != '/callback') {
      _log('drop GET $path -> wrong_path');
      req.response.statusCode = HttpStatus.notFound;
      await req.response.close();
      return;
    }

    final query = req.uri.queryParameters;

    // Next.js RSC prefetch sneaks in `_rsc=...`. Drain.
    if (query.containsKey('_rsc')) {
      _log('drop GET /callback -> rsc_prefetch');
      req.response.statusCode = HttpStatus.noContent;
      await req.response.close();
      return;
    }

    // Authorize error — terminal.
    final error = query['error'];
    if (error != null && error.isNotEmpty) {
      final description = query['error_description'] ?? '';
      _log('terminal GET /callback -> authorize_error');
      req.response.statusCode = HttpStatus.badRequest;
      req.response.headers.contentType = ContentType.html;
      req.response.write(_authorizeErrorPage(error, description));
      await req.response.close();
      if (!completer.isCompleted) {
        completer.complete(
          Failure<String>(
            InvalidArgError(
              description.isEmpty
                  ? 'authorize error: $error'
                  : 'authorize error: $error — $description',
            ),
          ),
        );
      }
      return;
    }

    // CSRF guard — empty state or mismatch.
    final state = query['state'] ?? '';
    final code = query['code'] ?? '';
    if (state.isEmpty || state != expectedState || code.isEmpty) {
      _log('drop GET /callback -> state_or_code_invalid');
      req.response.statusCode = HttpStatus.noContent;
      await req.response.close();
      return;
    }

    // Legitimate callback.
    _log('accept GET /callback -> success');
    req.response.statusCode = HttpStatus.ok;
    req.response.headers.contentType = ContentType.html;
    req.response.write(_successPage());
    await req.response.close();
    if (!completer.isCompleted) {
      completer.complete(Success<String>(code));
    }
  }

  void _log(String reason) {
    final logger = _logger;
    if (logger == null) return;
    // Reason-only — never raw query string, never `code=`.
    logger(reason);
  }

  static String _successPage() => '''
<!doctype html>
<html lang="en"><head><meta charset="utf-8"><title>ACDG CLI</title>
<style>body{font:14px system-ui;color:#222;margin:3rem auto;max-width:32rem;text-align:center}</style>
</head><body>
<h1>Login concluído</h1>
<p>Você pode fechar esta aba e voltar ao terminal.</p>
</body></html>
''';

  static String _authorizeErrorPage(String error, String description) {
    final safeError = _escapeHtml(error);
    final safeDescription = _escapeHtml(description);
    return '''
<!doctype html>
<html lang="en"><head><meta charset="utf-8"><title>ACDG CLI — error</title>
<style>body{font:14px system-ui;color:#222;margin:3rem auto;max-width:32rem;text-align:center}.code{font-family:monospace;background:#f4f4f4;padding:.25rem .5rem;border-radius:.25rem}</style>
</head><body>
<h1>Authorization error</h1>
<p><span class="code">$safeError</span></p>
<p>$safeDescription</p>
<p>Volte ao terminal — o CLI já encerrou esta sessão.</p>
</body></html>
''';
  }

  /// Defense-in-depth: even though the loopback page renders only on the
  /// user's localhost, an attacker who can craft `error_description` query
  /// values still has zero excuse to land unescaped HTML in the user's
  /// browser. Mirrors the Python reference in spike §A.1.
  static String _escapeHtml(String input) => input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}
