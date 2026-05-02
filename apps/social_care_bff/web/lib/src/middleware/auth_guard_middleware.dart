import 'dart:convert';

import 'package:shelf/shelf.dart';

import 'session_middleware.dart';

/// Creates a shelf [Middleware] that guards routes requiring authentication.
///
/// Returns 401 if no [Session] is found in the request context
/// (i.e., [sessionMiddleware] didn't find a valid session).
Middleware authGuardMiddleware() {
  return (Handler innerHandler) {
    return (Request request) {
      final session = request.context[sessionContextKey];
      if (session == null) {
        return Response(
          401,
          body: jsonEncode({
            'error': 'Unauthorized',
            'message': 'Valid session required',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }
      return innerHandler(request);
    };
  };
}
