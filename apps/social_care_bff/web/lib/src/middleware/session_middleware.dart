import 'package:shelf/shelf.dart';

import '../auth/session_store.dart';

/// Key used to store/retrieve the [Session] from shelf request context.
const String sessionContextKey = 'session';

/// Creates a shelf [Middleware] that reads the `__session` cookie,
/// looks up the session in [store], and attaches it to the request context.
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

/// Parses the `__session` value from a Cookie header string.
///
/// Cookie format: `name1=value1; name2=value2`
/// Returns `null` if `__session` is not found.
String? _parseSessionCookie(String cookieHeader) {
  final cookies = cookieHeader.split(';');
  for (final cookie in cookies) {
    final trimmed = cookie.trim();
    if (trimmed.startsWith('__session=')) {
      return trimmed.substring('__session='.length);
    }
  }
  return null;
}
