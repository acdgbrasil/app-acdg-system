import 'package:core/core.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../auth/session_store.dart';
import 'handler_utils.dart';

/// Factory that creates a [SocialCareContract] for a given [Session].
typedef HealthContractFactory = SocialCareContract Function(Session session);

/// Handles health check endpoints.
///
/// Routes:
/// - `GET /health/live`  — liveness probe
/// - `GET /health/ready` — readiness probe
class HealthHandler {
  HealthHandler({required HealthContractFactory contractFactory})
    : _contractFactory = contractFactory;

  final HealthContractFactory _contractFactory;

  Router get router {
    final r = Router();
    r.get('/health/live', _live);
    r.get('/health/ready', _ready);
    return r;
  }

  Future<Response> _live(Request request) async {
    final session = getSession(request);
    final contract = _contractFactory(session);
    final result = await contract.checkHealth();

    return switch (result) {
      Success() => jsonOk({'status': 'ok'}),
      Failure(:final error) => jsonError(503, error.toString()),
    };
  }

  Future<Response> _ready(Request request) async {
    final session = getSession(request);
    final contract = _contractFactory(session);
    final result = await contract.checkReady();

    return switch (result) {
      Success() => jsonOk({'status': 'ready'}),
      Failure(:final error) => jsonError(503, error.toString()),
    };
  }
}
