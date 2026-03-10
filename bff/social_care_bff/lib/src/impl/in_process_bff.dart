import 'package:core/core.dart';
import 'package:dio/dio.dart';

import '../api_client/social_care_api_client.dart';
import '../contract/dto/requests/assessment_requests.dart';
import '../contract/dto/requests/care_requests.dart';
import '../contract/dto/requests/protection_requests.dart';
import '../contract/dto/requests/registry_requests.dart';
import '../contract/social_care_contract.dart';
import '../models/audit_event.dart';
import '../models/lookup_item.dart';
import '../models/patient.dart';

/// In-process BFF implementation for desktop.
///
/// Delegates all operations to [SocialCareApiClient] (Dio HTTP).
/// Used when the Flutter app runs on desktop — no intermediate HTTP server.
class InProcessBff implements SocialCareContract {
  InProcessBff({required SocialCareApiClient apiClient}) : _api = apiClient;

  final SocialCareApiClient _api;

  // ──────────────────────────── Registry ────────────────────────────

  @override
  Future<Result<String>> registerPatient({
    required String actorId,
    required RegisterPatientRequest request,
  }) => _run(
    () => _api.registerPatient(actorId: actorId, body: request.toJson()),
  );

  @override
  Future<Result<Patient>> getPatientById(String patientId) =>
      _run(() => _api.getPatientById(patientId));

  @override
  Future<Result<Patient>> getPatientByPersonId(String personId) =>
      _run(() => _api.getPatientByPersonId(personId));

  @override
  Future<Result<void>> addFamilyMember({
    required String patientId,
    required String actorId,
    required AddFamilyMemberRequest request,
  }) => _run(
    () => _api.addFamilyMember(
      patientId: patientId,
      actorId: actorId,
      body: request.toJson(),
    ),
  );

  @override
  Future<Result<void>> removeFamilyMember({
    required String patientId,
    required String memberId,
    required String actorId,
  }) => _run(
    () => _api.removeFamilyMember(
      patientId: patientId,
      memberId: memberId,
      actorId: actorId,
    ),
  );

  @override
  Future<Result<void>> assignPrimaryCaregiver({
    required String patientId,
    required String actorId,
    required AssignPrimaryCaregiverRequest request,
  }) => _run(
    () => _api.assignPrimaryCaregiver(
      patientId: patientId,
      actorId: actorId,
      body: request.toJson(),
    ),
  );

  @override
  Future<Result<void>> updateSocialIdentity({
    required String patientId,
    required String actorId,
    required UpdateSocialIdentityRequest request,
  }) => _run(
    () => _api.updateSocialIdentity(
      patientId: patientId,
      actorId: actorId,
      body: request.toJson(),
    ),
  );

  // ──────────────────────────── Audit ────────────────────────────

  @override
  Future<Result<List<AuditEvent>>> getAuditTrail(
    String patientId, {
    String? eventType,
  }) => _run(() => _api.getAuditTrail(patientId, eventType: eventType));

  // ──────────────────────────── Assessment ────────────────────────────

  @override
  Future<Result<void>> updateHousingCondition({
    required String patientId,
    required String actorId,
    required UpdateHousingConditionRequest request,
  }) => _run(
    () => _api.updateHousingCondition(
      patientId: patientId,
      actorId: actorId,
      body: request.toJson(),
    ),
  );

  @override
  Future<Result<void>> updateSocioEconomicSituation({
    required String patientId,
    required String actorId,
    required UpdateSocioEconomicSituationRequest request,
  }) => _run(
    () => _api.updateSocioEconomicSituation(
      patientId: patientId,
      actorId: actorId,
      body: request.toJson(),
    ),
  );

  @override
  Future<Result<void>> updateWorkAndIncome({
    required String patientId,
    required String actorId,
    required UpdateWorkAndIncomeRequest request,
  }) => _run(
    () => _api.updateWorkAndIncome(
      patientId: patientId,
      actorId: actorId,
      body: request.toJson(),
    ),
  );

  @override
  Future<Result<void>> updateEducationalStatus({
    required String patientId,
    required String actorId,
    required UpdateEducationalStatusRequest request,
  }) => _run(
    () => _api.updateEducationalStatus(
      patientId: patientId,
      actorId: actorId,
      body: request.toJson(),
    ),
  );

  @override
  Future<Result<void>> updateHealthStatus({
    required String patientId,
    required String actorId,
    required UpdateHealthStatusRequest request,
  }) => _run(
    () => _api.updateHealthStatus(
      patientId: patientId,
      actorId: actorId,
      body: request.toJson(),
    ),
  );

  @override
  Future<Result<void>> updateCommunitySupportNetwork({
    required String patientId,
    required String actorId,
    required UpdateCommunitySupportNetworkRequest request,
  }) => _run(
    () => _api.updateCommunitySupportNetwork(
      patientId: patientId,
      actorId: actorId,
      body: request.toJson(),
    ),
  );

  @override
  Future<Result<void>> updateSocialHealthSummary({
    required String patientId,
    required String actorId,
    required UpdateSocialHealthSummaryRequest request,
  }) => _run(
    () => _api.updateSocialHealthSummary(
      patientId: patientId,
      actorId: actorId,
      body: request.toJson(),
    ),
  );

  // ──────────────────────────── Care ────────────────────────────

  @override
  Future<Result<String>> registerAppointment({
    required String patientId,
    required String actorId,
    required RegisterAppointmentRequest request,
  }) => _run(
    () => _api.registerAppointment(
      patientId: patientId,
      actorId: actorId,
      body: request.toJson(),
    ),
  );

  @override
  Future<Result<void>> registerIntakeInfo({
    required String patientId,
    required String actorId,
    required RegisterIntakeInfoRequest request,
  }) => _run(
    () => _api.registerIntakeInfo(
      patientId: patientId,
      actorId: actorId,
      body: request.toJson(),
    ),
  );

  // ──────────────────────────── Protection ────────────────────────────

  @override
  Future<Result<void>> updatePlacementHistory({
    required String patientId,
    required String actorId,
    required UpdatePlacementHistoryRequest request,
  }) => _run(
    () => _api.updatePlacementHistory(
      patientId: patientId,
      actorId: actorId,
      body: request.toJson(),
    ),
  );

  @override
  Future<Result<String>> reportRightsViolation({
    required String patientId,
    required String actorId,
    required ReportRightsViolationRequest request,
  }) => _run(
    () => _api.reportRightsViolation(
      patientId: patientId,
      actorId: actorId,
      body: request.toJson(),
    ),
  );

  @override
  Future<Result<String>> createReferral({
    required String patientId,
    required String actorId,
    required CreateReferralRequest request,
  }) => _run(
    () => _api.createReferral(
      patientId: patientId,
      actorId: actorId,
      body: request.toJson(),
    ),
  );

  // ──────────────────────────── Lookup ────────────────────────────

  @override
  Future<Result<List<LookupItem>>> listLookupItems(String tableName) =>
      _run(() => _api.listLookupItems(tableName));

  // ──────────────────────────── Helpers ────────────────────────────

  Future<Result<T>> _run<T>(Future<T> Function() action) async {
    try {
      final value = await action();
      return Success(value);
    } on DioException catch (e, st) {
      final message = _extractErrorMessage(e);
      return Failure(message, stackTrace: st);
    } on Exception catch (e, st) {
      return Failure(e, stackTrace: st);
    }
  }

  String _extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        return error['message'] as String? ?? e.message ?? 'Unknown error';
      }
      if (error is String) return error;
    }
    return e.message ?? 'Network error';
  }
}
