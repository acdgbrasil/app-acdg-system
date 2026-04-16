import 'package:core_contracts/core_contracts.dart';

import '../contract/social_care_contract.dart';
import '../contract/dto/requests/assessment/update_community_support_network_request.dart';
import '../contract/dto/requests/assessment/update_educational_status_request.dart';
import '../contract/dto/requests/assessment/update_health_status_request.dart';
import '../contract/dto/requests/assessment/update_housing_condition_request.dart';
import '../contract/dto/requests/assessment/update_social_health_summary_request.dart';
import '../contract/dto/requests/assessment/update_socio_economic_situation_request.dart';
import '../contract/dto/requests/assessment/update_work_and_income_request.dart';
import '../contract/dto/requests/care/register_appointment_request.dart';
import '../contract/dto/requests/care/register_intake_info_request.dart';
import '../contract/dto/requests/people/assign_role_request.dart';
import '../contract/dto/requests/people/register_person_request.dart';
import '../contract/dto/requests/people/register_person_with_login_request.dart';
import '../contract/dto/requests/protection/create_referral_request.dart';
import '../contract/dto/requests/protection/report_rights_violation_request.dart';
import '../contract/dto/requests/protection/update_placement_history_request.dart';
import '../contract/dto/requests/registry/add_family_member_request.dart';
import '../contract/dto/requests/registry/assign_primary_caregiver_request.dart';
import '../contract/dto/requests/registry/discharge_patient_request.dart';
import '../contract/dto/requests/registry/readmit_patient_request.dart';
import '../contract/dto/requests/registry/register_patient_request.dart';
import '../contract/dto/requests/registry/update_social_identity_request.dart';
import '../contract/dto/requests/registry/withdraw_patient_request.dart';
import '../contract/dto/responses/analytics/axis_metadata_response.dart';
import '../contract/dto/responses/analytics/indicator_response.dart';
import '../contract/dto/responses/audit/audit_trail_entry_response.dart';
import '../contract/dto/responses/people/person_response.dart';
import '../contract/dto/responses/people/person_role_response.dart';
import '../contract/dto/responses/registry/patient_response.dart';
import '../contract/dto/responses/registry/patient_summary_response.dart';
import '../contract/dto/shared/paginated_list.dart';
import '../contract/dto/shared/pagination_meta.dart';
import '../contract/dto/shared/standard_response.dart';

/// Implementation of [SocialCareContract] for testing and local simulation.
class FakeSocialCareBff implements SocialCareContract {
  FakeSocialCareBff({this.delay = const Duration(milliseconds: 200)});

  final Duration delay;

  StandardResponse<T> _wrap<T>(T data) => StandardResponse(
    data: data,
    meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
  );

  StandardIdResponse _wrapId(String id) => _wrap(IdData(id: id));

  // ── Health ──────────────────────────────────────────────────────────────

  @override
  Future<Result<void>> checkHealth() async => const Success(null);

  @override
  Future<Result<void>> checkReady() async => const Success(null);

  // ── Registry ────────────────────────────────────────────────────────────

  @override
  Future<Result<PaginatedList<PatientSummaryResponse>>> fetchPatients({
    String? search,
    String? status,
    String? cursor,
    int? limit,
  }) async {
    await Future.delayed(delay);
    return Success(
      PaginatedList(
        data: const [],
        meta: PaginationMeta(
          pageSize: limit ?? 20,
          totalCount: 0,
          hasMore: false,
        ),
      ),
    );
  }

  @override
  Future<Result<StandardIdResponse>> registerPatient(
    RegisterPatientRequest request,
  ) async {
    await Future.delayed(delay);
    return Success(_wrapId('fake-patient-id'));
  }

  @override
  Future<Result<StandardResponse<PatientResponse>>> fetchPatient(
    String patientId,
  ) async {
    await Future.delayed(delay);
    return Failure('Patient not found: $patientId');
  }

  @override
  Future<Result<StandardResponse<PatientResponse>>> fetchPatientByPersonId(
    String personId,
  ) async {
    await Future.delayed(delay);
    return Failure('Patient not found for person: $personId');
  }

  @override
  Future<Result<StandardResponse<PatientResponse>>> fetchPatientEnriched(
    String patientId,
  ) async => fetchPatient(patientId);

  @override
  Future<Result<void>> addFamilyMember(
    String patientId,
    AddFamilyMemberRequest request, {
    String? cpf,
  }) async => const Success(null);

  @override
  Future<Result<void>> removeFamilyMember(
    String patientId,
    String memberId,
  ) async => const Success(null);

  @override
  Future<Result<void>> assignPrimaryCaregiver(
    String patientId,
    AssignPrimaryCaregiverRequest request,
  ) async => const Success(null);

  @override
  Future<Result<void>> updateSocialIdentity(
    String patientId,
    UpdateSocialIdentityRequest request,
  ) async => const Success(null);

  @override
  Future<Result<void>> dischargePatient(
    String patientId,
    DischargePatientRequest request,
  ) async => const Success(null);

  @override
  Future<Result<void>> readmitPatient(
    String patientId,
    ReadmitPatientRequest request,
  ) async => const Success(null);

  @override
  Future<Result<void>> admitPatient(String patientId) async =>
      const Success(null);

  @override
  Future<Result<void>> withdrawPatient(
    String patientId,
    WithdrawPatientRequest request,
  ) async => const Success(null);

  // ── Assessment ──────────────────────────────────────────────────────────

  @override
  Future<Result<void>> updateHousingCondition(
    String patientId,
    UpdateHousingConditionRequest request,
  ) async => const Success(null);

  @override
  Future<Result<void>> updateSocioEconomicSituation(
    String patientId,
    UpdateSocioEconomicSituationRequest request,
  ) async => const Success(null);

  @override
  Future<Result<void>> updateWorkAndIncome(
    String patientId,
    UpdateWorkAndIncomeRequest request,
  ) async => const Success(null);

  @override
  Future<Result<void>> updateEducationalStatus(
    String patientId,
    UpdateEducationalStatusRequest request,
  ) async => const Success(null);

  @override
  Future<Result<void>> updateHealthStatus(
    String patientId,
    UpdateHealthStatusRequest request,
  ) async => const Success(null);

  @override
  Future<Result<void>> updateCommunitySupportNetwork(
    String patientId,
    UpdateCommunitySupportNetworkRequest request,
  ) async => const Success(null);

  @override
  Future<Result<void>> updateSocialHealthSummary(
    String patientId,
    UpdateSocialHealthSummaryRequest request,
  ) async => const Success(null);

  // ── Care ────────────────────────────────────────────────────────────────

  @override
  Future<Result<StandardIdResponse>> registerAppointment(
    String patientId,
    RegisterAppointmentRequest request,
  ) async => Success(_wrapId('fake-appointment-id'));

  @override
  Future<Result<void>> updateIntakeInfo(
    String patientId,
    RegisterIntakeInfoRequest request,
  ) async => const Success(null);

  // ── Protection ──────────────────────────────────────────────────────────

  @override
  Future<Result<void>> updatePlacementHistory(
    String patientId,
    UpdatePlacementHistoryRequest request,
  ) async => const Success(null);

  @override
  Future<Result<StandardIdResponse>> reportViolation(
    String patientId,
    ReportRightsViolationRequest request,
  ) async => Success(_wrapId('fake-violation-id'));

  @override
  Future<Result<StandardIdResponse>> createReferral(
    String patientId,
    CreateReferralRequest request,
  ) async => Success(_wrapId('fake-referral-id'));

  // ── Audit ───────────────────────────────────────────────────────────────

  @override
  Future<Result<StandardResponse<List<AuditTrailEntryResponse>>>> getAuditTrail(
    String patientId, {
    String? eventType,
    int? limit,
    int? offset,
  }) async => Success(_wrap(const <AuditTrailEntryResponse>[]));

  // ── Lookup ──────────────────────────────────────────────────────────────

  @override
  Future<Result<StandardResponse<List<Map<String, dynamic>>>>> getLookupTable(
    String tableName,
  ) async => Success(_wrap(const <Map<String, dynamic>>[]));

  // ── People ──────────────────────────────────────────────────────────────

  @override
  Future<Result<StandardIdResponse>> registerPerson(
    RegisterPersonRequest request,
  ) async => Success(_wrapId('fake-person-id'));

  @override
  Future<Result<StandardIdResponse>> registerPersonWithLogin(
    RegisterPersonWithLoginRequest request,
  ) async => Success(_wrapId('fake-person-id'));

  @override
  Future<Result<PersonResponse>> getPerson(String personId) async =>
      Success(PersonResponse(id: personId, fullName: 'Fake Person'));

  @override
  Future<Result<PersonResponse>> findPersonByCpf(String cpf) async =>
      const Failure('Person not found');

  @override
  Future<Result<StandardResponse<List<PersonResponse>>>> fetchPeople({
    int? limit,
    String? name,
    String? cpf,
    String? cursor,
  }) async => Success(_wrap(const <PersonResponse>[]));

  @override
  Future<Result<void>> deactivatePerson(String personId) async =>
      const Success(null);

  @override
  Future<Result<void>> reactivatePerson(String personId) async =>
      const Success(null);

  @override
  Future<Result<void>> requestPasswordReset(String personId) async =>
      const Success(null);

  @override
  Future<Result<void>> assignRole(
    String personId,
    AssignRoleRequest request,
  ) async => const Success(null);

  @override
  Future<Result<List<PersonRoleResponse>>> listPersonRoles(
    String personId, {
    bool? active,
  }) async => const Success([]);

  @override
  Future<Result<List<PersonRoleResponse>>> queryRoles({
    required String system,
    String? role,
    bool active = true,
  }) async => const Success([]);

  @override
  Future<Result<void>> deactivateRole({
    required String personId,
    required String roleId,
  }) async => const Success(null);

  @override
  Future<Result<void>> reactivateRole({
    required String personId,
    required String roleId,
  }) async => const Success(null);

  // ── Analytics ───────────────────────────────────────────────────────────

  @override
  Future<Result<StandardResponse<IndicatorResponse>>> getIndicators(
    String axis, {
    String? period,
  }) async => Success(_wrap(IndicatorResponse(axis: axis, rows: const [])));

  @override
  Future<Result<StandardResponse<List<AxisMetadataResponse>>>>
  getAxesMetadata() async => Success(_wrap(const <AxisMetadataResponse>[]));
}
