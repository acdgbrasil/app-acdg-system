import 'dart:convert';

import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../auth/oidc_server_client.dart';
import '../auth/session_store.dart';
import '../config/server_config.dart';
import '../handlers/assessment_handler.dart';
import '../handlers/auth_handler.dart';
import '../handlers/care_handler.dart';
import '../handlers/lookup_handler.dart';
import '../handlers/protection_handler.dart';
import '../handlers/registry_handler.dart';
import '../middleware/auth_guard_middleware.dart';
import '../middleware/session_middleware.dart';

/// Builds the complete router for the BFF Web server.
///
/// Middleware chain:
/// 1. Session middleware applied globally (reads cookie, attaches session)
/// 2. Auth guard applied only to protected routes (rejects if no session)
///
/// Route groups:
/// - `/health/*` — public (no auth, no session needed)
/// - `/auth/*`   — session middleware only (login/callback public, me/logout need session)
/// - `/patients/*` — session + auth guard
/// - `/lookups/*`  — session + auth guard
/// Factory that creates a [SocialCareContract] for a given [Session].
typedef AppContractFactory = SocialCareContract Function(Session session);

class AppRouter {
  AppRouter({
    required ServerConfig config,
    required SessionStore sessionStore,
    required OidcServerClient oidcClient,
    required AppContractFactory contractFactory,
  }) : _sessionStore = sessionStore,
       _oidcClient = oidcClient,
       _contractFactory = contractFactory;

  final SessionStore _sessionStore;
  final OidcServerClient _oidcClient;
  final AppContractFactory _contractFactory;

  /// Returns the fully assembled shelf [Handler].
  ///
  /// Uses [Cascade] to try each handler group in order:
  /// 1. Health (public, no session required)
  /// 2. Auth (session middleware, no auth guard)
  /// 3. Protected routes (session middleware + auth guard)
  ///
  /// The session middleware wraps auth and protected routes so they
  /// can access the session from context. Health routes bypass it entirely.
  Handler get handler {
    // --- Public health routes (no auth, no session) ---
    final healthRouter = Router();
    healthRouter.get('/health/live', _liveHandler);
    healthRouter.get('/health/ready', _readyHandler);

    // --- Auth routes (session middleware, no auth guard) ---
    final authHandler = AuthHandler(
      oidcClient: _oidcClient,
      sessionStore: _sessionStore,
    );

    final authPipeline = const Pipeline()
        .addMiddleware(sessionMiddleware(_sessionStore))
        .addHandler(authHandler.router.call);

    // --- Protected routes (session middleware + auth guard) ---
    final registryHandler = RegistryHandler(contractFactory: _contractFactory);

    final assessmentHandler = AssessmentHandler(
      contractFactory: _contractFactory,
    );

    final careHandler = CareHandler(contractFactory: _contractFactory);

    final protectionHandler = ProtectionHandler(
      contractFactory: _contractFactory,
    );

    final lookupHandler = LookupHandler(contractFactory: _contractFactory);

    final protectedPipeline = const Pipeline()
        .addMiddleware(sessionMiddleware(_sessionStore))
        .addMiddleware(authGuardMiddleware());

    // Use Cascade to try handlers in order.
    // Each Router returns 404 for unmatched routes; Cascade tries the next.
    final cascade = Cascade()
        .add(healthRouter.call)
        .add(authPipeline)
        .add(protectedPipeline.addHandler(registryHandler.router.call))
        .add(protectedPipeline.addHandler(assessmentHandler.router.call))
        .add(protectedPipeline.addHandler(careHandler.router.call))
        .add(protectedPipeline.addHandler(protectionHandler.router.call))
        .add(protectedPipeline.addHandler(lookupHandler.router.call));

    return cascade.handler;
  }

  /// GET /health/live — liveness probe.
  ///
  /// Always returns 200 if the process is running.
  /// No authentication or backend connectivity check needed.
  Future<Response> _liveHandler(Request request) async {
    return Response.ok(
      jsonEncode({'status': 'ok'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// GET /health/ready — readiness probe.
  ///
  /// Returns 200 if the server is ready to accept traffic.
  /// Does not check backend connectivity (that would require auth).
  Future<Response> _readyHandler(Request request) async {
    return Response.ok(
      jsonEncode({'status': 'ready'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
