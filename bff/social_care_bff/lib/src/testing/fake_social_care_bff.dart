import 'package:core/core.dart';

import '../contract/dto/requests/assessment_requests.dart';
import '../contract/dto/requests/care_requests.dart';
import '../contract/dto/requests/protection_requests.dart';
import '../contract/dto/requests/registry_requests.dart';
import '../contract/social_care_contract.dart';
import '../models/audit_event.dart';
import '../models/computed_analytics.dart';
import '../models/lookup_item.dart';
import '../models/patient.dart';

/// In-memory fake implementation of [SocialCareContract] for testing.
///
/// Stores patients and lookup items in memory. All mutations succeed
/// unless [shouldFail] is set to `true`.
class FakeSocialCareBff implements SocialCareContract {
  final Map<String, Patient> patients = {};
  final Map<String, List<LookupItem>> lookupTables = {};
  final List<AuditEvent> auditEvents = [];
  bool shouldFail = false;
  String failMessage = 'Fake error';
  int registerCallCount = 0;

  Result<T> _guard<T>(T value) {
    if (shouldFail) return Failure(failMessage);
    return Success(value);
  }

  @override
  Future<Result<String>> registerPatient({
    required String actorId,
    required RegisterPatientRequest request,
  }) async {
    registerCallCount++;
    const id = 'fake-patient-id';
    patients[id] = Patient(
      patientId: id,
      personId: request.personId,
      version: 1,
      familyMembers: const [],
      diagnoses: const [],
      appointments: const [],
      referrals: const [],
      violationReports: const [],
      computedAnalytics: const ComputedAnalytics(),
    );
    return _guard(id);
  }

  @override
  Future<Result<Patient>> getPatientById(String patientId) async {
    final patient = patients[patientId];
    if (patient == null) return const Failure('Patient not found');
    return _guard(patient);
  }

  @override
  Future<Result<Patient>> getPatientByPersonId(String personId) async {
    final patient = patients.values.where((p) => p.personId == personId);
    if (patient.isEmpty) return const Failure('Patient not found');
    return _guard(patient.first);
  }

  @override
  Future<Result<void>> addFamilyMember({
    required String patientId,
    required String actorId,
    required AddFamilyMemberRequest request,
  }) async => _guard(null);

  @override
  Future<Result<void>> removeFamilyMember({
    required String patientId,
    required String memberId,
    required String actorId,
  }) async => _guard(null);

  @override
  Future<Result<void>> assignPrimaryCaregiver({
    required String patientId,
    required String actorId,
    required AssignPrimaryCaregiverRequest request,
  }) async => _guard(null);

  @override
  Future<Result<void>> updateSocialIdentity({
    required String patientId,
    required String actorId,
    required UpdateSocialIdentityRequest request,
  }) async => _guard(null);

  @override
  Future<Result<List<AuditEvent>>> getAuditTrail(
    String patientId, {
    String? eventType,
  }) async => _guard(auditEvents);

  @override
  Future<Result<void>> updateHousingCondition({
    required String patientId,
    required String actorId,
    required UpdateHousingConditionRequest request,
  }) async => _guard(null);

  @override
  Future<Result<void>> updateSocioEconomicSituation({
    required String patientId,
    required String actorId,
    required UpdateSocioEconomicSituationRequest request,
  }) async => _guard(null);

  @override
  Future<Result<void>> updateWorkAndIncome({
    required String patientId,
    required String actorId,
    required UpdateWorkAndIncomeRequest request,
  }) async => _guard(null);

  @override
  Future<Result<void>> updateEducationalStatus({
    required String patientId,
    required String actorId,
    required UpdateEducationalStatusRequest request,
  }) async => _guard(null);

  @override
  Future<Result<void>> updateHealthStatus({
    required String patientId,
    required String actorId,
    required UpdateHealthStatusRequest request,
  }) async => _guard(null);

  @override
  Future<Result<void>> updateCommunitySupportNetwork({
    required String patientId,
    required String actorId,
    required UpdateCommunitySupportNetworkRequest request,
  }) async => _guard(null);

  @override
  Future<Result<void>> updateSocialHealthSummary({
    required String patientId,
    required String actorId,
    required UpdateSocialHealthSummaryRequest request,
  }) async => _guard(null);

  @override
  Future<Result<String>> registerAppointment({
    required String patientId,
    required String actorId,
    required RegisterAppointmentRequest request,
  }) async => _guard('fake-appointment-id');

  @override
  Future<Result<void>> registerIntakeInfo({
    required String patientId,
    required String actorId,
    required RegisterIntakeInfoRequest request,
  }) async => _guard(null);

  @override
  Future<Result<void>> updatePlacementHistory({
    required String patientId,
    required String actorId,
    required UpdatePlacementHistoryRequest request,
  }) async => _guard(null);

  @override
  Future<Result<String>> reportRightsViolation({
    required String patientId,
    required String actorId,
    required ReportRightsViolationRequest request,
  }) async => _guard('fake-violation-id');

  @override
  Future<Result<String>> createReferral({
    required String patientId,
    required String actorId,
    required CreateReferralRequest request,
  }) async => _guard('fake-referral-id');

  @override
  Future<Result<List<LookupItem>>> listLookupItems(String tableName) async {
    final items = lookupTables[tableName] ?? [];
    return _guard(items);
  }
}
