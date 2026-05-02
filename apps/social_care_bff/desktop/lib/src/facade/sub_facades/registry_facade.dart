import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../../use_cases/registry/add_family_member_use_case.dart';
import '../../use_cases/registry/admit_patient_use_case.dart';
import '../../use_cases/registry/assign_primary_caregiver_use_case.dart';
import '../../use_cases/registry/discharge_patient_use_case.dart';
import '../../use_cases/registry/fetch_patient_by_person_id_use_case.dart';
import '../../use_cases/registry/fetch_patient_use_case.dart';
import '../../use_cases/registry/list_patients_use_case.dart';
import '../../use_cases/registry/readmit_patient_use_case.dart';
import '../../use_cases/registry/register_patient_use_case.dart';
import '../../use_cases/registry/remove_family_member_use_case.dart';
import '../../use_cases/registry/search_patients_use_case.dart';
import '../../use_cases/registry/update_social_identity_use_case.dart';
import '../../use_cases/registry/withdraw_patient_use_case.dart';

/// Registry sub-facade — 13 thin pass-through methods over the Registry
/// use cases (A18b-v2). The constructor is private; instances are built
/// only by `SocialCareDesktop.create()`.
class RegistryFacade {
  RegistryFacade.internal({
    required FetchPatientUseCase fetchPatient,
    required FetchPatientByPersonIdUseCase fetchPatientByPersonId,
    required ListPatientsUseCase listPatients,
    required SearchPatientsUseCase searchPatients,
    required RegisterPatientUseCase registerPatient,
    required AddFamilyMemberUseCase addFamilyMember,
    required RemoveFamilyMemberUseCase removeFamilyMember,
    required AssignPrimaryCaregiverUseCase assignPrimaryCaregiver,
    required UpdateSocialIdentityUseCase updateSocialIdentity,
    required DischargePatientUseCase dischargePatient,
    required ReadmitPatientUseCase readmitPatient,
    required AdmitPatientUseCase admitPatient,
    required WithdrawPatientUseCase withdrawPatient,
  }) : _fetchPatient = fetchPatient,
       _fetchPatientByPersonId = fetchPatientByPersonId,
       _listPatients = listPatients,
       _searchPatients = searchPatients,
       _registerPatient = registerPatient,
       _addFamilyMember = addFamilyMember,
       _removeFamilyMember = removeFamilyMember,
       _assignPrimaryCaregiver = assignPrimaryCaregiver,
       _updateSocialIdentity = updateSocialIdentity,
       _dischargePatient = dischargePatient,
       _readmitPatient = readmitPatient,
       _admitPatient = admitPatient,
       _withdrawPatient = withdrawPatient;

  final FetchPatientUseCase _fetchPatient;
  final FetchPatientByPersonIdUseCase _fetchPatientByPersonId;
  final ListPatientsUseCase _listPatients;
  final SearchPatientsUseCase _searchPatients;
  final RegisterPatientUseCase _registerPatient;
  final AddFamilyMemberUseCase _addFamilyMember;
  final RemoveFamilyMemberUseCase _removeFamilyMember;
  final AssignPrimaryCaregiverUseCase _assignPrimaryCaregiver;
  final UpdateSocialIdentityUseCase _updateSocialIdentity;
  final DischargePatientUseCase _dischargePatient;
  final ReadmitPatientUseCase _readmitPatient;
  final AdmitPatientUseCase _admitPatient;
  final WithdrawPatientUseCase _withdrawPatient;

  // ── Reads ───────────────────────────────────────────────────────────

  Future<Result<PatientResponse>> fetchPatient(String id) => _fetchPatient(id);

  Future<Result<PatientResponse>> fetchPatientByPersonId(String personId) =>
      _fetchPatientByPersonId(personId);

  Future<Result<List<PatientSummaryResponse>>> listPatients({
    String? status,
    String? cursor,
    int? limit,
  }) => _listPatients(status: status, cursor: cursor, limit: limit);

  Future<Result<List<PatientSummaryResponse>>> searchPatients(String term) =>
      _searchPatients(term);

  // ── Writes ──────────────────────────────────────────────────────────

  Future<Result<StandardIdResponse>> registerPatient(
    RegisterPatientRequest req,
  ) => _registerPatient(req);

  Future<Result<void>> addFamilyMember(
    String patientId,
    AddFamilyMemberRequest req,
  ) => _addFamilyMember(patientId, req);

  Future<Result<void>> removeFamilyMember(String patientId, String memberId) =>
      _removeFamilyMember(patientId, memberId);

  Future<Result<void>> assignPrimaryCaregiver(
    String patientId,
    AssignPrimaryCaregiverRequest req,
  ) => _assignPrimaryCaregiver(patientId, req);

  Future<Result<void>> updateSocialIdentity(
    String patientId,
    UpdateSocialIdentityRequest req,
  ) => _updateSocialIdentity(patientId, req);

  Future<Result<void>> dischargePatient(
    String patientId,
    DischargePatientRequest req,
  ) => _dischargePatient(patientId, req);

  Future<Result<void>> readmitPatient(
    String patientId,
    ReadmitPatientRequest req,
  ) => _readmitPatient(patientId, req);

  Future<Result<void>> admitPatient(String patientId) =>
      _admitPatient(patientId);

  Future<Result<void>> withdrawPatient(
    String patientId,
    WithdrawPatientRequest req,
  ) => _withdrawPatient(patientId, req);
}
