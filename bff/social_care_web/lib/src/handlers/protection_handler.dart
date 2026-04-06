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
      final patientIdResult = PatientId.create(id);
      final historyResult = PatientTranslator.placementHistoryFromJson(body);

      return switch ((patientIdResult, historyResult)) {
        (Success(:final value), Success(value: final history)) =>
          switch (await contract.updatePlacementHistory(value, history)) {
            Success() => jsonNoContent(),
            Failure(:final error) => jsonError(500, error.toString()),
          },
        (Failure(:final error), _) => jsonError(
          400,
          'Invalid patient ID: $error',
        ),
        (_, Failure(:final error)) => jsonError(
          400,
          'Invalid placement history: $error',
        ),
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
      final patientIdResult = PatientId.create(id);
      final reportResult = PatientTranslator.violationReportFromJson(body);

      return switch ((patientIdResult, reportResult)) {
        (Success(:final value), Success(value: final report)) =>
          switch (await contract.reportViolation(value, report)) {
            Success(:final value) => jsonOk({'id': value.value}),
            Failure(:final error) => jsonError(500, error.toString()),
          },
        (Failure(:final error), _) => jsonError(
          400,
          'Invalid patient ID: $error',
        ),
        (_, Failure(:final error)) => jsonError(
          400,
          'Invalid violation report: $error',
        ),
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
      final patientIdResult = PatientId.create(id);
      final referralResult = PatientTranslator.referralFromJson(body);

      return switch ((patientIdResult, referralResult)) {
        (Success(:final value), Success(value: final referral)) =>
          switch (await contract.createReferral(value, referral)) {
            Success(:final value) => jsonOk({'id': value.value}),
            Failure(:final error) => jsonError(500, error.toString()),
          },
        (Failure(:final error), _) => jsonError(
          400,
          'Invalid patient ID: $error',
        ),
        (_, Failure(:final error)) => jsonError(
          400,
          'Invalid referral: $error',
        ),
      };
    } catch (e) {
      return jsonError(400, 'Invalid request body: $e');
    }
  }
}
