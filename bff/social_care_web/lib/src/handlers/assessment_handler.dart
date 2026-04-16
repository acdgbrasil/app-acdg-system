import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../auth/session_store.dart';
import 'handler_utils.dart';

/// Factory that creates a [SocialCareContract] for a given [Session].
typedef AssessmentContractFactory =
    SocialCareContract Function(Session session);

/// Handles patient assessment endpoints.
///
/// Routes:
/// - `PUT /patients/<id>/assessment/housing`
/// - `PUT /patients/<id>/assessment/socioeconomic`
/// - `PUT /patients/<id>/assessment/work-income`
/// - `PUT /patients/<id>/assessment/education`
/// - `PUT /patients/<id>/assessment/health`
/// - `PUT /patients/<id>/assessment/community-support`
/// - `PUT /patients/<id>/assessment/social-health-summary`
class AssessmentHandler {
  AssessmentHandler({required AssessmentContractFactory contractFactory})
    : _contractFactory = contractFactory;

  final AssessmentContractFactory _contractFactory;

  Router get router {
    final r = Router();
    r.put('/patients/<id>/assessment/housing', _updateHousing);
    r.put('/patients/<id>/assessment/socioeconomic', _updateSocioeconomic);
    r.put('/patients/<id>/assessment/work-income', _updateWorkIncome);
    r.put('/patients/<id>/assessment/education', _updateEducation);
    r.put('/patients/<id>/assessment/health', _updateHealth);
    r.put('/patients/<id>/assessment/community-support', _updateCommunity);
    r.put(
      '/patients/<id>/assessment/social-health-summary',
      _updateSocialHealth,
    );
    return r;
  }

  Future<Response> _updateHousing(Request request, String id) async {
    final session = getSession(request);
    final contract = _contractFactory(session);

    try {
      final body = await readJsonBody(request);
      final dto = UpdateHousingConditionRequest.fromJson(body);

      return switch (await contract.updateHousingCondition(id, dto)) {
        Success() => jsonNoContent(),
        Failure(:final error) => backendError(error),
      };
    } catch (e) {
      return jsonError(400, 'Invalid request body: $e');
    }
  }

  Future<Response> _updateSocioeconomic(Request request, String id) async {
    final session = getSession(request);
    final contract = _contractFactory(session);

    try {
      final body = await readJsonBody(request);
      final dto = UpdateSocioEconomicSituationRequest.fromJson(body);

      return switch (await contract.updateSocioEconomicSituation(id, dto)) {
        Success() => jsonNoContent(),
        Failure(:final error) => backendError(error),
      };
    } catch (e) {
      return jsonError(400, 'Invalid request body: $e');
    }
  }

  Future<Response> _updateWorkIncome(Request request, String id) async {
    final session = getSession(request);
    final contract = _contractFactory(session);

    try {
      final body = await readJsonBody(request);
      final dto = UpdateWorkAndIncomeRequest.fromJson(body);

      return switch (await contract.updateWorkAndIncome(id, dto)) {
        Success() => jsonNoContent(),
        Failure(:final error) => backendError(error),
      };
    } catch (e) {
      return jsonError(400, 'Invalid request body: $e');
    }
  }

  Future<Response> _updateEducation(Request request, String id) async {
    final session = getSession(request);
    final contract = _contractFactory(session);

    try {
      final body = await readJsonBody(request);
      final dto = UpdateEducationalStatusRequest.fromJson(body);

      return switch (await contract.updateEducationalStatus(id, dto)) {
        Success() => jsonNoContent(),
        Failure(:final error) => backendError(error),
      };
    } catch (e) {
      return jsonError(400, 'Invalid request body: $e');
    }
  }

  Future<Response> _updateHealth(Request request, String id) async {
    final session = getSession(request);
    final contract = _contractFactory(session);

    try {
      final body = await readJsonBody(request);
      final dto = UpdateHealthStatusRequest.fromJson(body);

      return switch (await contract.updateHealthStatus(id, dto)) {
        Success() => jsonNoContent(),
        Failure(:final error) => backendError(error),
      };
    } catch (e) {
      return jsonError(400, 'Invalid request body: $e');
    }
  }

  Future<Response> _updateCommunity(Request request, String id) async {
    final session = getSession(request);
    final contract = _contractFactory(session);

    try {
      final body = await readJsonBody(request);
      final dto = UpdateCommunitySupportNetworkRequest.fromJson(body);

      return switch (await contract.updateCommunitySupportNetwork(id, dto)) {
        Success() => jsonNoContent(),
        Failure(:final error) => backendError(error),
      };
    } catch (e) {
      return jsonError(400, 'Invalid request body: $e');
    }
  }

  Future<Response> _updateSocialHealth(Request request, String id) async {
    final session = getSession(request);
    final contract = _contractFactory(session);

    try {
      final body = await readJsonBody(request);
      final dto = UpdateSocialHealthSummaryRequest.fromJson(body);

      return switch (await contract.updateSocialHealthSummary(id, dto)) {
        Success() => jsonNoContent(),
        Failure(:final error) => backendError(error),
      };
    } catch (e) {
      return jsonError(400, 'Invalid request body: $e');
    }
  }
}
