import 'package:core_contracts/core_contracts.dart';

import '../contract/dto/requests/registry/add_family_member_request.dart';
import '../contract/dto/requests/registry/assign_primary_caregiver_request.dart';
import '../contract/dto/requests/registry/discharge_patient_request.dart';
import '../contract/dto/requests/registry/readmit_patient_request.dart';
import '../contract/dto/requests/registry/register_patient_request.dart';
import '../contract/dto/requests/registry/update_social_identity_request.dart';
import '../contract/dto/requests/registry/withdraw_patient_request.dart';
import '../contract/dto/responses/registry/patient_response.dart';
import '../contract/dto/responses/registry/patient_summary_response.dart';
import '../contract/dto/shared/paginated_list.dart';
import '../contract/dto/shared/pagination_meta.dart';
import '../contract/dto/shared/standard_response.dart';
import '../contract/sub_contracts/registry_contract.dart';
import 'stores/in_memory_patient_store.dart';

/// In-memory fake for [RegistryContract].
///
/// State is held in an [InMemoryPatientStore] — a public collaborator the
/// tests can inspect or pre-seed via `fake.store.patients[...]`.
class FakeRegistryBff implements RegistryContract {
  FakeRegistryBff({InMemoryPatientStore? store})
      : store = store ?? InMemoryPatientStore();

  final InMemoryPatientStore store;

  String _nextId() => DateTime.now().microsecondsSinceEpoch.toString();

  StandardResponse<T> _wrap<T>(T data) => StandardResponse(
    data: data,
    meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
  );

  StandardIdResponse _wrapId(String id) => _wrap(IdData(id: id));

  // ── Patients ────────────────────────────────────────────────────────────

  @override
  Future<Result<PaginatedList<PatientSummaryResponse>>> fetchPatients({
    String? search,
    String? status,
    String? cursor,
    int? limit,
  }) async {
    Iterable<PatientSummaryResponse> list = store.summaries.values;
    if (status != null && status.isNotEmpty) {
      list = list.where((p) => p.status == status);
    }
    if (search != null && search.isNotEmpty) {
      final needle = search.toLowerCase();
      list = list.where(
        (p) => (p.fullName ?? '').toLowerCase().contains(needle),
      );
    }
    final data = list.toList();
    return Success(
      PaginatedList(
        data: data,
        meta: PaginationMeta(
          pageSize: limit ?? data.length,
          totalCount: data.length,
          hasMore: false,
        ),
      ),
    );
  }

  @override
  Future<Result<StandardIdResponse>> registerPatient(
    RegisterPatientRequest request,
  ) async {
    final patientId = _nextId();
    final firstDiagnosis = request.initialDiagnoses.isNotEmpty
        ? request.initialDiagnoses.first.description
        : null;
    store.save(
      PatientResponse(
        patientId: patientId,
        personId: request.personId,
        prRelationshipId: request.prRelationshipId,
      ),
      PatientSummaryResponse(
        patientId: patientId,
        personId: request.personId,
        firstName: request.personalData?.firstName,
        lastName: request.personalData?.lastName,
        fullName: request.personalData == null
            ? null
            : '${request.personalData!.firstName} ${request.personalData!.lastName}'
                .trim(),
        primaryDiagnosis: firstDiagnosis,
        memberCount: 0,
        status: 'admitted',
      ),
    );
    return Success(_wrapId(patientId));
  }

  @override
  Future<Result<StandardResponse<PatientResponse>>> fetchPatient(
    String patientId,
  ) async {
    final patient = store.get(patientId);
    if (patient == null) {
      return Failure('Patient not found: $patientId');
    }
    return Success(_wrap(patient));
  }

  @override
  Future<Result<StandardResponse<PatientResponse>>> fetchPatientByPersonId(
    String personId,
  ) async {
    for (final patient in store.patients.values) {
      if (patient.personId == personId) {
        return Success(_wrap(patient));
      }
    }
    return Failure('Patient not found for person: $personId');
  }

  // ── Family Members ──────────────────────────────────────────────────────

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

  // ── Social Identity ─────────────────────────────────────────────────────

  @override
  Future<Result<void>> updateSocialIdentity(
    String patientId,
    UpdateSocialIdentityRequest request,
  ) async => const Success(null);

  // ── Lifecycle ───────────────────────────────────────────────────────────

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
}
