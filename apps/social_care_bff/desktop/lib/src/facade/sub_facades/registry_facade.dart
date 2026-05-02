import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../composition/builders/registry_use_cases.dart';

/// Registry sub-facade — 13 thin pass-through methods over the Registry
/// use cases (A18b-v2). The constructor is private; instances are built
/// only by `SocialCareDesktop.create()`.
///
/// Backed by [RegistryUseCases] — a data class that groups the 13 use
/// cases (D02). Adding a new use case requires touching the bundle, not
/// the facade signature.
class RegistryFacade {
  RegistryFacade.internal({required RegistryUseCases useCases})
    : _useCases = useCases;

  final RegistryUseCases _useCases;

  // ── Reads ───────────────────────────────────────────────────────────

  Future<Result<PatientResponse>> fetchPatient(String id) =>
      _useCases.fetchPatient(id);

  Future<Result<PatientResponse>> fetchPatientByPersonId(String personId) =>
      _useCases.fetchPatientByPersonId(personId);

  Future<Result<List<PatientSummaryResponse>>> listPatients({
    String? status,
    String? cursor,
    int? limit,
  }) => _useCases.listPatients(status: status, cursor: cursor, limit: limit);

  Future<Result<List<PatientSummaryResponse>>> searchPatients(String term) =>
      _useCases.searchPatients(term);

  // ── Writes ──────────────────────────────────────────────────────────

  Future<Result<StandardIdResponse>> registerPatient(
    RegisterPatientRequest req,
  ) => _useCases.registerPatient(req);

  Future<Result<void>> addFamilyMember(
    String patientId,
    AddFamilyMemberRequest req,
  ) => _useCases.addFamilyMember(patientId, req);

  Future<Result<void>> removeFamilyMember(String patientId, String memberId) =>
      _useCases.removeFamilyMember(patientId, memberId);

  Future<Result<void>> assignPrimaryCaregiver(
    String patientId,
    AssignPrimaryCaregiverRequest req,
  ) => _useCases.assignPrimaryCaregiver(patientId, req);

  Future<Result<void>> updateSocialIdentity(
    String patientId,
    UpdateSocialIdentityRequest req,
  ) => _useCases.updateSocialIdentity(patientId, req);

  Future<Result<void>> dischargePatient(
    String patientId,
    DischargePatientRequest req,
  ) => _useCases.dischargePatient(patientId, req);

  Future<Result<void>> readmitPatient(
    String patientId,
    ReadmitPatientRequest req,
  ) => _useCases.readmitPatient(patientId, req);

  Future<Result<void>> admitPatient(String patientId) =>
      _useCases.admitPatient(patientId);

  Future<Result<void>> withdrawPatient(
    String patientId,
    WithdrawPatientRequest req,
  ) => _useCases.withdrawPatient(patientId, req);
}
