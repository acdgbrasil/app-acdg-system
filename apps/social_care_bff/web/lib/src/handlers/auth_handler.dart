import 'dart:convert';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../intents/auth_callback_intent.dart';
import '../intents/login_intent.dart';
import '../intents/logout_intent.dart';
import '../intents/me_intent.dart';
import '../intents/refresh_intent.dart';
import '../middleware/cookie_constants.dart'; // SEC: single-source cookie attrs
import '../observability/observability_context.dart';
import '../use_cases/auth_callback_use_case.dart';
import '../use_cases/login_use_case.dart';
import '../use_cases/logout_use_case.dart';
import '../use_cases/me_use_case.dart';
import '../use_cases/refresh_use_case.dart';

/// Thin OIDC auth HTTP handler.
///
/// Responsibilities:
/// - Parse request → [LoginIntent]/[AuthCallbackIntent]/[LogoutIntent]/
///   [MeIntent]/[RefreshIntent] via P2 if-case (see intents).
/// - Dispatch to the matching UseCase (state matrix — P1 switch on result).
/// - Translate [Result] into sanitized shelf [Response]s.
/// - Set/clear the `__Host-session` cookie.
///
/// Orchestration only — no business logic, no HTTP client code, no OIDC
/// calls. Everything upstream-facing lives behind [AuthContract] which is
/// injected via the UseCases.
///
/// Observability: every handler pulls the per-request [ObservabilityContext]
/// from [Request.context] (falling back to noop for unit tests). UseCases
/// emit the canonical breadcrumbs; the handler does not duplicate them.
final class AuthHandler {
  const AuthHandler({
    required LoginUseCase login,
    required AuthCallbackUseCase callback,
    required LogoutUseCase logout,
    required MeUseCase me,
    required RefreshUseCase refresh,
  }) : _login = login,
       _callback = callback,
       _logout = logout,
       _me = me,
       _refresh = refresh;

  final LoginUseCase _login;
  final AuthCallbackUseCase _callback;
  final LogoutUseCase _logout;
  final MeUseCase _me;
  final RefreshUseCase _refresh;

  Router get router {
    final r = Router();
    r.get('/auth/login', _handleLogin);
    r.get('/auth/callback', _handleCallback);
    r.post('/auth/logout', _handleLogout);
    r.get('/auth/me', _handleMe);
    r.post('/auth/refresh', _handleRefresh);
    return r;
  }

  // ---------------------------------------------------------------------------
  // GET /auth/login
  // ---------------------------------------------------------------------------

  Future<Response> _handleLogin(Request request) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);
    final intent = LoginIntent.parseFromQuery(
      request.requestedUri.queryParameters,
    );

    final result = await _login.execute(intent, obs);

    return switch (result) {
      Success(:final value) => Response(302, headers: {'location': value}),
      Failure(:final error) => _errorResponse(error),
    };
  }

  // ---------------------------------------------------------------------------
  // GET /auth/callback
  // ---------------------------------------------------------------------------

  Future<Response> _handleCallback(Request request) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);
    final parsed = AuthCallbackIntent.parseFromQuery(
      request.requestedUri.queryParameters,
    );

    return switch (parsed) {
      Success(:final value) => await _dispatchCallback(value, obs),
      Failure(:final error) => _badRequest(
        code: 'INVALID_CALLBACK',
        // Use the PII-safe exception message from the intent — it never
        // echoes the raw `code` (verified by Wave 0 tests).
        message: error.toString(),
      ),
    };
  }

  Future<Response> _dispatchCallback(
    AuthCallbackIntent intent,
    ObservabilityContext obs,
  ) async {
    final result = await _callback.execute(intent, obs);

    return switch (result) {
      // SEC: sessionId comes from SessionStore.create() inside the use case.
      // The handler does NOT synthesize a UUID — that was the B3 phantom-
      // session bug. The cookie value here MUST map to a live store entry.
      Success(:final value) => Response(
        302,
        headers: {
          'location': '/',
          // SEC: canonical attrs (Path=/, HttpOnly, Secure, SameSite=Strict,
          // Max-Age=3600) — see cookie_constants.dart.
          'set-cookie': buildSessionSetCookie(value),
        },
      ),
      Failure(:final error) => _errorResponse(error),
    };
  }

  // ---------------------------------------------------------------------------
  // POST /auth/logout
  // ---------------------------------------------------------------------------

  Future<Response> _handleLogout(Request request) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);
    // Logout is idempotent: even without a cookie we clear any residue.
    final sessionId = _readSessionCookie(request) ?? '';
    final intent = LogoutIntent(sessionId: sessionId);

    final result = await _logout.execute(intent, obs);

    return switch (result) {
      Success() => Response.ok(
        jsonEncode({'message': 'Logged out'}),
        headers: {
          'content-type': 'application/json',
          // SEC: canonical clear-cookie attrs (same scope + Max-Age=0).
          'set-cookie': buildClearSessionSetCookie(),
        },
      ),
      Failure(:final error) => _errorResponse(error),
    };
  }

  // ---------------------------------------------------------------------------
  // GET /auth/me
  // ---------------------------------------------------------------------------

  Future<Response> _handleMe(Request request) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);
    final sessionId = _readSessionCookie(request);
    if (sessionId == null) {
      return _unauthorized('No session');
    }

    final result = await _me.execute(MeIntent(sessionId: sessionId), obs);

    return switch (result) {
      Success(:final value) => Response.ok(
        jsonEncode(value.toJson()),
        headers: {'content-type': 'application/json'},
      ),
      Failure(:final error) => _errorResponse(error),
    };
  }

  // ---------------------------------------------------------------------------
  // POST /auth/refresh
  // ---------------------------------------------------------------------------

  Future<Response> _handleRefresh(Request request) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);
    final sessionId = _readSessionCookie(request);
    if (sessionId == null) {
      return _unauthorized('No session');
    }

    final result = await _refresh.execute(
      RefreshIntent(sessionId: sessionId),
      obs,
    );

    return switch (result) {
      Success() => Response.ok(
        jsonEncode({'message': 'Tokens refreshed'}),
        headers: {'content-type': 'application/json'},
      ),
      Failure(:final error) => _errorResponse(error),
    };
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Extracts the [sessionCookieName] value from the Cookie header.
  ///
  /// Returns `null` when the cookie is absent or empty.
  String? _readSessionCookie(Request request) {
    final cookieHeader = request.headers['cookie'];
    if (cookieHeader == null || cookieHeader.isEmpty) return null;
    // SEC: name comes from cookie_constants.dart — writer (Set-Cookie above)
    // and this reader MUST agree. Name drift is a compile-time error now.
    final prefix = '$sessionCookieName=';
    for (final raw in cookieHeader.split(';')) {
      final trimmed = raw.trim();
      if (trimmed.startsWith(prefix)) {
        final value = trimmed.substring(prefix.length);
        return value.isEmpty ? null : value;
      }
    }
    return null;
  }

  /// Maps a [BackendError] / any failure into a sanitized JSON response.
  ///
  /// Status code is `BackendError.http ?? 500`. Body carries `code` +
  /// `message` only — never stack traces or nested exception messages.
  Response _errorResponse(Object error) {
    final (status, code, message) = _extractError(error);
    return Response(
      status,
      body: jsonEncode({
        'error': {'code': code, 'message': message},
      }),
      headers: {'content-type': 'application/json'},
    );
  }

  (int, String, String) _extractError(Object error) {
    if (error is BackendError) {
      return (error.http ?? 500, error.code, error.message);
    }
    // Non-BackendError failures: never echo the raw message.
    return (500, 'INTERNAL', 'Internal server error');
  }

  Response _badRequest({required String code, required String message}) {
    return Response(
      400,
      body: jsonEncode({
        'error': {'code': code, 'message': message},
      }),
      headers: {'content-type': 'application/json'},
    );
  }

  Response _unauthorized(String message) {
    return Response(
      401,
      body: jsonEncode({
        'error': {'code': 'UNAUTHORIZED', 'message': message},
      }),
      headers: {'content-type': 'application/json'},
    );
  }
}
