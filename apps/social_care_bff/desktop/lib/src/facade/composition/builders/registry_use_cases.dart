/// Bundles the 13 Registry use cases (A18b-v2) — the largest of the 7
/// per-bounded-context builders extracted in D02.
///
/// 4 reads (Pattern 1: cache + remote + clock + staleAfter) and 9 writes
/// (Pattern 2: patient-aggregate writes — cache + outbox + engine + clock).
/// Constructed by [RegistryUseCases.build] from shared dependencies and
/// consumed by `RegistryFacade.internal()`.
library;

import 'package:shared/shared.dart';

import '../../../cache/contracts/patients_cache.dart';
import '../../../sync/engine/sync_engine.dart';
import '../../../sync/outbox/outbox_repository.dart';
import '../../../use_cases/_shared/clock.dart';
import '../../../use_cases/registry/add_family_member_use_case.dart';
import '../../../use_cases/registry/admit_patient_use_case.dart';
import '../../../use_cases/registry/assign_primary_caregiver_use_case.dart';
import '../../../use_cases/registry/discharge_patient_use_case.dart';
import '../../../use_cases/registry/fetch_patient_by_person_id_use_case.dart';
import '../../../use_cases/registry/fetch_patient_use_case.dart';
import '../../../use_cases/registry/list_patients_use_case.dart';
import '../../../use_cases/registry/readmit_patient_use_case.dart';
import '../../../use_cases/registry/register_patient_use_case.dart';
import '../../../use_cases/registry/remove_family_member_use_case.dart';
import '../../../use_cases/registry/search_patients_use_case.dart';
import '../../../use_cases/registry/update_social_identity_use_case.dart';
import '../../../use_cases/registry/withdraw_patient_use_case.dart';

/// Data class grouping the 13 Registry use cases. Each field is a freshly
/// constructed use case instance (true factory — no caching, no singleton).
class RegistryUseCases {
  RegistryUseCases({
    required this.fetchPatient,
    required this.fetchPatientByPersonId,
    required this.listPatients,
    required this.searchPatients,
    required this.registerPatient,
    required this.addFamilyMember,
    required this.removeFamilyMember,
    required this.assignPrimaryCaregiver,
    required this.updateSocialIdentity,
    required this.dischargePatient,
    required this.readmitPatient,
    required this.admitPatient,
    required this.withdrawPatient,
  });

  // ── Reads (4) ───────────────────────────────────────────────────────
  final FetchPatientUseCase fetchPatient;
  final FetchPatientByPersonIdUseCase fetchPatientByPersonId;
  final ListPatientsUseCase listPatients;
  final SearchPatientsUseCase searchPatients;

  // ── Writes (9) ──────────────────────────────────────────────────────
  final RegisterPatientUseCase registerPatient;
  final AddFamilyMemberUseCase addFamilyMember;
  final RemoveFamilyMemberUseCase removeFamilyMember;
  final AssignPrimaryCaregiverUseCase assignPrimaryCaregiver;
  final UpdateSocialIdentityUseCase updateSocialIdentity;
  final DischargePatientUseCase dischargePatient;
  final ReadmitPatientUseCase readmitPatient;
  final AdmitPatientUseCase admitPatient;
  final WithdrawPatientUseCase withdrawPatient;

  /// Constructs all 13 Registry use cases from shared dependencies.
  ///
  /// Reads consume [registry] + [clock] + [staleAfter]; writes consume
  /// [outbox] + [engine] + [clock]. All 13 share the [patientsCache]
  /// (Patient is the aggregate root for the bounded context).
  static RegistryUseCases build({
    required PatientsCache patientsCache,
    required RegistryContract remote,
    required OutboxRepository outbox,
    required SyncEngine engine,
    required Clock clock,
    required Duration staleAfter,
  }) {
    return RegistryUseCases(
      // Reads
      fetchPatient: FetchPatientUseCase(
        cache: patientsCache,
        remote: remote,
        clock: clock,
        staleAfter: staleAfter,
      ),
      fetchPatientByPersonId: FetchPatientByPersonIdUseCase(
        cache: patientsCache,
        remote: remote,
        clock: clock,
        staleAfter: staleAfter,
      ),
      listPatients: ListPatientsUseCase(
        cache: patientsCache,
        remote: remote,
        clock: clock,
        staleAfter: staleAfter,
      ),
      searchPatients: SearchPatientsUseCase(
        cache: patientsCache,
        remote: remote,
        clock: clock,
        staleAfter: staleAfter,
      ),
      // Writes
      registerPatient: RegisterPatientUseCase(
        cache: patientsCache,
        outbox: outbox,
        engine: engine,
        clock: clock,
      ),
      addFamilyMember: AddFamilyMemberUseCase(
        cache: patientsCache,
        outbox: outbox,
        engine: engine,
        clock: clock,
      ),
      removeFamilyMember: RemoveFamilyMemberUseCase(
        cache: patientsCache,
        outbox: outbox,
        engine: engine,
        clock: clock,
      ),
      assignPrimaryCaregiver: AssignPrimaryCaregiverUseCase(
        cache: patientsCache,
        outbox: outbox,
        engine: engine,
        clock: clock,
      ),
      updateSocialIdentity: UpdateSocialIdentityUseCase(
        cache: patientsCache,
        outbox: outbox,
        engine: engine,
        clock: clock,
      ),
      dischargePatient: DischargePatientUseCase(
        cache: patientsCache,
        outbox: outbox,
        engine: engine,
        clock: clock,
      ),
      readmitPatient: ReadmitPatientUseCase(
        cache: patientsCache,
        outbox: outbox,
        engine: engine,
        clock: clock,
      ),
      admitPatient: AdmitPatientUseCase(
        cache: patientsCache,
        outbox: outbox,
        engine: engine,
        clock: clock,
      ),
      withdrawPatient: WithdrawPatientUseCase(
        cache: patientsCache,
        outbox: outbox,
        engine: engine,
        clock: clock,
      ),
    );
  }
}
