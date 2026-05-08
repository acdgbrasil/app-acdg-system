import 'package:shelf/shelf.dart';

import '../auth/session_store.dart';
import 'cookie_constants.dart';

/// Key used to store/retrieve the [Session] from shelf request context.
///
/// SEC: this is the SINGLE canonical slot for an authenticated [Session] in
/// the request context. Both [bearerAuthMiddleware] and [sessionMiddleware]
/// write here. `getSession()` and `authGuardMiddleware()` read here. Any
/// drift to a second slot would re-introduce P0-1 (CVSS 9.8 — pentest §B2).
const String sessionContextKey = 'session';

/// Creates a shelf [Middleware] that reads the [sessionCookieName] cookie,
/// looks up the session in [store], and attaches it to [sessionContextKey]
/// in the request context.
///
/// Pipeline ordering (load-bearing — see `app_router.dart`):
///
///   observability → bearerAuthMiddleware → sessionMiddleware → authGuard
///
/// SEC: `sessionMiddleware` runs AFTER `bearerAuthMiddleware`. shelf's
/// `request.change(context: ...)` is last-writer-wins on the same key, so if
/// both bearer and cookie auth produce a [Session] for the same request,
/// the cookie session wins. The W0.5 S1 isolation invariant (bearer roles
/// must NEVER be observed under a cookie context, and vice versa) is
/// preserved by `bearerAuthMiddleware` STRIPPING the `Cookie` header on its
/// success path (see `bearer_auth_middleware.dart:173-178`) — so this
/// middleware can never resolve a cookie when bearer auth has already won.
///
/// If no cookie is found or the session is expired/invalid, the request
/// continues without a session in the context (no rejection — that's
/// [authGuardMiddleware]'s job).
Middleware sessionMiddleware(SessionStore store) {
  return (Handler innerHandler) {
    return (Request request) {
      final cookieHeader = request.headers['cookie'];
      if (cookieHeader == null) {
        return innerHandler(request);
      }

      final sessionId = _parseSessionCookie(cookieHeader);
      if (sessionId == null) {
        return innerHandler(request);
      }

      final session = store.get(sessionId);
      if (session == null) {
        return innerHandler(request);
      }

      final updatedRequest = request.change(
        context: {sessionContextKey: session},
      );
      return innerHandler(updatedRequest);
    };
  };
}

/// Parses the [sessionCookieName] value from a Cookie header string.
///
/// Cookie format: `name1=value1; name2=value2`
/// Returns `null` if [sessionCookieName] is not found.
String? _parseSessionCookie(String cookieHeader) {
  // SEC: name comes from cookie_constants.dart — the writer (AuthHandler)
  // and this reader MUST agree. Any drift between writer/reader is a
  // compile-time error now (named import).
  final prefix = '$sessionCookieName=';
  final cookies = cookieHeader.split(';');
  for (final cookie in cookies) {
    final trimmed = cookie.trim();
    if (trimmed.startsWith(prefix)) {
      return trimmed.substring(prefix.length);
    }
  }
  return null;
}
