import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../auth/session_store.dart';
import 'session_middleware.dart';

// SEC: canonical 401 body. Identical bytes to bearer_auth_middleware's
// `_genericAuthBody` (constraint #10 — single oracle for every auth
// rejection on the protected pipeline). A pentester cannot distinguish
// "no token" vs "bad token" vs "expired cookie" vs "destroyed session"
// — every path collapses to AUTH-001. Cross-bundle invariant
// "Single-source constants — error codes" (TRACEABILITY.md).
final List<int> _genericAuthBody = utf8.encode(
  jsonEncode(<String, String>{
    'code': 'AUTH-001',
    'message': 'Invalid credentials',
  }),
);

/// Fail-closed gate for the protected pipeline.
///
/// Reads the canonical [sessionContextKey] slot, populated by either
/// [bearerAuthMiddleware] on a valid Bearer JWT, or [sessionMiddleware] on a
/// valid `__session` cookie. On absence — emits the canonical AUTH-001 401
/// body and short-circuits the pipeline; the inner handler is never invoked.
///
/// Pipeline order MUST be:
/// `observability → bearerAuth → sessionMiddleware → authGuard → handler`
/// so both auth paths have a chance to populate the slot before the guard
/// reads it.
///
/// ASVS L2 §4.1.1 deny by default. Closes P0-1 (CVSS 9.8) + pentest B2.
Middleware authGuardMiddleware() {
  return (Handler innerHandler) {
    return (Request request) {
      // SEC: type-safe `is Session` guard. Avoids the `as Session` cast
      // that was the load-bearing bug at handler_utils.getSession (Phase
      // 3 N1). Both null AND a non-Session value (a future bug writing
      // the wrong type) collapse to the same 401 — no TypeError leak.
      final session = request.context[sessionContextKey];
      if (session is! Session) {
        // SEC: short-circuit. Inner handler never runs — closes the
        // anonymous-mutation path on every protected route (registry,
        // family, assessment, care, protection, lookup, team).
        return Response(
          401,
          body: _genericAuthBody,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      }
      return innerHandler(request);
    };
  };
}
