import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../auth/session_store.dart';
import 'handler_utils.dart';

/// Factory that creates a [SocialCareContract] for a given [Session].
typedef ProtectionContractFactory =
    SocialCareContract Function(Session session);

/// Handles protection-related endpoints (placement, violations, referrals).
///
/// Routes:
/// - `PUT  /patients/<id>/placement-history` — update placement history
/// - `POST /patients/<id>/violations`        — report violation
/// - `POST /patients/<id>/referrals`         — create referral
class ProtectionHandler {
  ProtectionHandler({required ProtectionContractFactory contractFactory})
    : _contractFactory = contractFactory;

  final ProtectionContractFactory _contractFactory;

  Router get router {
    final r = Router();
    r.put('/patients/<id>/placement-history', _updatePlacementHistory);
    r.post('/patients/<id>/violations', _reportViolation);
    r.post('/patients/<id>/referrals', _createReferral);
    return r;
  }

  Future<Response> _updatePlacementHistory(Request request, String id) async {
    final session = getSession(request);
    final contract = _contractFactory(session);

    try {
      final body = await readJsonBody(request);
      final dto = UpdatePlacementHistoryRequest.fromJson(body);

      return switch (await contract.updatePlacementHistory(id, dto)) {
        Success() => jsonNoContent(),
        Failure(:final error) => backendError(error),
      };
    } catch (e) {
      return jsonError(400, 'Invalid request body: $e');
    }
  }

  Future<Response> _reportViolation(Request request, String id) async {
    final session = getSession(request);
    final contract = _contractFactory(session);

    try {
      final body = await readJsonBody(request);
      final dto = ReportRightsViolationRequest.fromJson(body);

      return switch (await contract.reportViolation(id, dto)) {
        Success(:final value) => jsonOk({
          'data': {'id': value.data.id},
          'meta': {'timestamp': value.meta.timestamp},
        }),
        Failure(:final error) => backendError(error),
      };
    } catch (e) {
      return jsonError(400, 'Invalid request body: $e');
    }
  }

  Future<Response> _createReferral(Request request, String id) async {
    final session = getSession(request);
    final contract = _contractFactory(session);

    try {
      final body = await readJsonBody(request);
      final dto = CreateReferralRequest.fromJson(body);

      return switch (await contract.createReferral(id, dto)) {
        Success(:final value) => jsonOk({
          'data': {'id': value.data.id},
          'meta': {'timestamp': value.meta.timestamp},
        }),
        Failure(:final error) => backendError(error),
      };
    } catch (e) {
      return jsonError(400, 'Invalid request body: $e');
    }
  }
}
