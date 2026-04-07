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
      final patientIdResult = PatientId.create(id);
      final dataResult = PatientTranslator.housingConditionFromJson(body);

      return switch ((patientIdResult, dataResult)) {
        (Success(:final value), Success(value: final data)) =>
          switch (await contract.updateHousingCondition(value, data)) {
            Success() => jsonNoContent(),
            Failure(:final error) => backendError(error),
          },
        (Failure(:final error), _) => jsonError(
          400,
          'Invalid patient ID: $error',
        ),
        (_, Failure(:final error)) => jsonError(
          400,
          'Invalid housing condition: $error',
        ),
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
      final patientIdResult = PatientId.create(id);
      final dataResult = PatientTranslator.socioEconomicFromJson(body);

      return switch ((patientIdResult, dataResult)) {
        (Success(:final value), Success(value: final data)) =>
          switch (await contract.updateSocioEconomicSituation(value, data)) {
            Success() => jsonNoContent(),
            Failure(:final error) => backendError(error),
          },
        (Failure(:final error), _) => jsonError(
          400,
          'Invalid patient ID: $error',
        ),
        (_, Failure(:final error)) => jsonError(
          400,
          'Invalid socioeconomic situation: $error',
        ),
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
      final patientIdResult = PatientId.create(id);
      final dataResult = PatientTranslator.workAndIncomeFromJson(body);

      return switch ((patientIdResult, dataResult)) {
        (Success(:final value), Success(value: final data)) =>
          switch (await contract.updateWorkAndIncome(value, data)) {
            Success() => jsonNoContent(),
            Failure(:final error) => backendError(error),
          },
        (Failure(:final error), _) => jsonError(
          400,
          'Invalid patient ID: $error',
        ),
        (_, Failure(:final error)) => jsonError(
          400,
          'Invalid work and income: $error',
        ),
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
      final patientIdResult = PatientId.create(id);
      final dataResult = PatientTranslator.educationalStatusFromJson(body);

      return switch ((patientIdResult, dataResult)) {
        (Success(:final value), Success(value: final data)) =>
          switch (await contract.updateEducationalStatus(value, data)) {
            Success() => jsonNoContent(),
            Failure(:final error) => backendError(error),
          },
        (Failure(:final error), _) => jsonError(
          400,
          'Invalid patient ID: $error',
        ),
        (_, Failure(:final error)) => jsonError(
          400,
          'Invalid educational status: $error',
        ),
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
      final patientIdResult = PatientId.create(id);
      final dataResult = PatientTranslator.healthStatusFromJson(body);

      return switch ((patientIdResult, dataResult)) {
        (Success(:final value), Success(value: final data)) =>
          switch (await contract.updateHealthStatus(value, data)) {
            Success() => jsonNoContent(),
            Failure(:final error) => backendError(error),
          },
        (Failure(:final error), _) => jsonError(
          400,
          'Invalid patient ID: $error',
        ),
        (_, Failure(:final error)) => jsonError(
          400,
          'Invalid health status: $error',
        ),
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
      final patientIdResult = PatientId.create(id);
      final dataResult = PatientTranslator.communitySupportFromJson(body);

      return switch ((patientIdResult, dataResult)) {
        (Success(:final value), Success(value: final data)) =>
          switch (await contract.updateCommunitySupportNetwork(value, data)) {
            Success() => jsonNoContent(),
            Failure(:final error) => backendError(error),
          },
        (Failure(:final error), _) => jsonError(
          400,
          'Invalid patient ID: $error',
        ),
        (_, Failure(:final error)) => jsonError(
          400,
          'Invalid community support network: $error',
        ),
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
      final patientIdResult = PatientId.create(id);
      final dataResult = PatientTranslator.socialHealthSummaryFromJson(body);

      return switch ((patientIdResult, dataResult)) {
        (Success(:final value), Success(value: final data)) =>
          switch (await contract.updateSocialHealthSummary(value, data)) {
            Success() => jsonNoContent(),
            Failure(:final error) => backendError(error),
          },
        (Failure(:final error), _) => jsonError(
          400,
          'Invalid patient ID: $error',
        ),
        (_, Failure(:final error)) => jsonError(
          400,
          'Invalid social health summary: $error',
        ),
      };
    } catch (e) {
      return jsonError(400, 'Invalid request body: $e');
    }
  }
}
