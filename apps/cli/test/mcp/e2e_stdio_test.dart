/// W2 RED — End-to-end stdio test (ADR-MCP-008-v2).
///
/// Spawns a subprocess running `dart run apps/cli/bin/acdg.dart mcp serve`,
/// drives the JSON-RPC protocol over stdin/stdout, and verifies:
///   1. Successful `initialize` + `tools/list` + `tools/call health` round
///      trip. Process terminates cleanly after the channel closes.
///   2. Stdout carries ONLY JSON-RPC frames (no log leak). One canary
///      frame is enough — a single non-JSON-RPC line corrupts the AI
///      host's parser.
///   3. Stderr captures the package:logging output (so the operator can
///      still see what the server is doing during a real session).
///
/// IMPORTANT: this test is RED until W3 lands BOTH the `mcp serve` command
/// AND the `dart_mcp` dependency. Until then, `Process.start` will fail
/// with "command not found" / non-zero exit; the assertions trip and
/// surface the missing impl.
///
/// Repo-relative path resolution: tests run from the package root
/// (apps/cli) so `bin/acdg.dart` is the correct invocation. The pipeline
/// asserts this in W5 (`dart compile exe` + invoke).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

const Duration _kStartupBudget = Duration(seconds: 5);
const Duration _kRpcTimeout = Duration(seconds: 10);

void main() {
  group('e2e stdio — acdg mcp serve', () {
    test('completes JSON-RPC handshake (initialize + tools/list + tools/call '
        'health) and shuts down cleanly on stdin close', () async {
      final session = await _MCPSession.start();
      addTearDown(session.dispose);

      // 1) initialize.
      final initResp = await session.request(
        method: 'initialize',
        params: {
          'protocolVersion': '2024-11-05',
          'capabilities': <String, Object?>{},
          'clientInfo': {'name': 'acdg-mcp-test', 'version': '0.0.1'},
        },
      );
      expect(initResp['error'], isNull);
      expect(initResp['result'], isA<Map<String, Object?>>());

      // 2) tools/list — must surface the 5 MVP tools.
      final listResp = await session.request(method: 'tools/list');
      expect(listResp['error'], isNull);
      final result = listResp['result'] as Map<String, Object?>;
      final tools = (result['tools'] as List).cast<Map<String, Object?>>();
      final names = tools.map((t) => t['name']).toSet();
      expect(
        names,
        containsAll(<String>{
          'health',
          'auth.status',
          'patient.list',
          'patient.get',
          'lookup.get',
        }),
      );

      // 3) tools/call health — unauthenticated tool must succeed.
      final callResp = await session.request(
        method: 'tools/call',
        params: {'name': 'health', 'arguments': <String, Object?>{}},
      );
      expect(callResp['error'], isNull);
      // Either content[0].text is the BFF response or `isError` is set —
      // we accept both (the BFF may be unreachable in CI). What we assert
      // is the JSON-RPC envelope round-tripped successfully.
      expect(callResp['result'], isA<Map<String, Object?>>());

      // 4) clean shutdown — closing stdin must let the process exit 0.
      final exitCode = await session.closeAndAwait();
      expect(exitCode, equals(0));
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('stdout carries ONLY JSON-RPC frames — no log leak (single non-JSON '
        'line would corrupt the AI host parser)', () async {
      final session = await _MCPSession.start();
      addTearDown(session.dispose);

      await session.request(
        method: 'initialize',
        params: {
          'protocolVersion': '2024-11-05',
          'capabilities': <String, Object?>{},
          'clientInfo': {'name': 'acdg-mcp-test', 'version': '0.0.1'},
        },
      );

      // Every line drained from stdout must parse as JSON. The MCP
      // wire format is JSON-RPC frames (length-prefixed or
      // newline-delimited depending on transport). Both forms are
      // valid JSON when split per frame.
      for (final line in session.stdoutLines) {
        if (line.isEmpty) continue;
        // Tolerate Content-Length headers (the LSP-style wrapper that
        // some MCP transports use) — only assert that any line that
        // isn't a header is parseable JSON.
        if (line.startsWith('Content-Length:') ||
            line.startsWith('Content-Type:')) {
          continue;
        }
        // Throws FormatException on non-JSON content → log leak.
        final parsed = jsonDecode(line);
        expect(parsed, isA<Map<String, Object?>>());
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('stderr captures package:logging output (operator can still inspect '
        'what the server is doing)', () async {
      final session = await _MCPSession.start();
      addTearDown(session.dispose);

      await session.request(
        method: 'initialize',
        params: {
          'protocolVersion': '2024-11-05',
          'capabilities': <String, Object?>{},
          'clientInfo': {'name': 'acdg-mcp-test', 'version': '0.0.1'},
        },
      );

      // Give logging a moment to flush; then assert at least one line
      // appeared on stderr. DESIGN §2.3 line 244 emits "connected" on
      // start; that single record is enough to prove the redirect
      // pipeline works.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(
        session.stderrLines,
        isNotEmpty,
        reason: 'expected at least one log record to appear on stderr',
      );
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}

// ---------------------------------------------------------------------------
// Test harness: a thin JSON-RPC client over a child process.
// ---------------------------------------------------------------------------

class _MCPSession {
  _MCPSession._(this._process);

  final Process _process;
  int _nextId = 1;
  final List<String> stdoutLines = [];
  final List<String> stderrLines = [];
  // W3 fix: must be a broadcast stream — `request()` calls `firstWhere` on
  // every call, and a single-subscription stream is locked after the first
  // listener resolves (REGRA #2 exception: fixture-invalid bug, fixed per
  // 003-impl/REPORT.md notes).
  final StreamController<Map<String, Object?>> _frames =
      StreamController<Map<String, Object?>>.broadcast();
  late final StreamSubscription<String> _stdoutSub;
  late final StreamSubscription<String> _stderrSub;

  static Future<_MCPSession> start() async {
    final process = await Process.start(
      Platform.executable, // dart
      ['run', 'bin/acdg.dart', 'mcp', 'serve'],
      // Test runs from package root (apps/cli).
      includeParentEnvironment: true,
    );
    final session = _MCPSession._(process);
    session._wireStreams();
    // Allow the process a startup budget — it needs to bind stdio + log
    // "connected" before the first request. If start fails (missing impl,
    // dart_mcp not pinned, etc.), the request below times out RED.
    await Future<void>.delayed(_kStartupBudget);
    return session;
  }

  void _wireStreams() {
    _stdoutSub = _process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          stdoutLines.add(line);
          // Best-effort: if the line looks like JSON, surface it as a
          // frame. Production MCP transport may use length-prefix; this
          // simple split is good enough for the current handshake test
          // because the server flushes one JSON object per write.
          if (line.startsWith('{')) {
            try {
              final decoded = jsonDecode(line);
              if (decoded is Map<String, Object?>) {
                _frames.add(decoded);
              }
            } on FormatException {
              // Ignore — the leak-test will catch it.
            }
          }
        });
    _stderrSub = _process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(stderrLines.add);
  }

  Future<Map<String, Object?>> request({
    required String method,
    Map<String, Object?>? params,
  }) async {
    final id = _nextId++;
    final frame = jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      if (params != null) 'params': params,
    });
    _process.stdin.writeln(frame);
    await _process.stdin.flush();
    // Pull the next frame whose `id` matches; this is a tiny inline
    // matcher that avoids pulling in a JSON-RPC client lib.
    final response = await _frames.stream
        .firstWhere(
          (f) => f['id'] == id,
          orElse: () => <String, Object?>{
            'error': {'message': 'no matching response'},
          },
        )
        .timeout(_kRpcTimeout);
    return response;
  }

  Future<int> closeAndAwait() async {
    await _process.stdin.close();
    return _process.exitCode;
  }

  Future<void> dispose() async {
    await _stdoutSub.cancel();
    await _stderrSub.cancel();
    await _frames.close();
    _process.kill();
    await _process.exitCode.catchError((_) => -1);
  }
}
