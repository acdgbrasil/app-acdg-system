/// RED-phase tests for `RegistryUseCases` builder (D02 W0.5).
///
/// `RegistryUseCases` is one of 7 data classes that group the 42 use
/// cases per bounded context. Today the 13 Registry use cases are listed
/// inline in `social_care_desktop.dart` (lines 292-369, ~80L). D02
/// extracts that list into a single `build()` factory in
/// `lib/src/facade/composition/builders/registry_use_cases.dart`.
///
/// ── Surface under test (per ticket D02 000-request.md) ───────────────
///   * `class RegistryUseCases`
///       - 13 final fields (named `fetchPatient`, `fetchPatientByPersonId`,
///         `listPatients`, `searchPatients`, `registerPatient`,
///         `addFamilyMember`, `removeFamilyMember`,
///         `assignPrimaryCaregiver`, `updateSocialIdentity`,
///         `dischargePatient`, `readmitPatient`, `admitPatient`,
///         `withdrawPatient`)
///       - `static RegistryUseCases build({...})` factory
///
/// ── Test contract ────────────────────────────────────────────────────
///   1. `build()` populates all 13 fields with non-null instances.
///   2. Each field has the expected concrete `*UseCase` type.
///   3. `build()` is a true factory — two calls produce independent
///      instances of identical type.
///
/// IMPORTANT (RED phase): the import below resolves to a file W1 has
/// not created yet. Until then this test file fails to analyze. That is
/// the intended RED signal.
library;

// ignore_for_file: unnecessary_type_check

import 'package:test/test.dart';

import 'package:social_care_desktop/src/use_cases/registry/add_family_member_use_case.dart';
import 'package:social_care_desktop/src/use_cases/registry/admit_patient_use_case.dart';
import 'package:social_care_desktop/src/use_cases/registry/assign_primary_caregiver_use_case.dart';
import 'package:social_care_desktop/src/use_cases/registry/discharge_patient_use_case.dart';
import 'package:social_care_desktop/src/use_cases/registry/fetch_patient_by_person_id_use_case.dart';
import 'package:social_care_desktop/src/use_cases/registry/fetch_patient_use_case.dart';
import 'package:social_care_desktop/src/use_cases/registry/list_patients_use_case.dart';
import 'package:social_care_desktop/src/use_cases/registry/readmit_patient_use_case.dart';
import 'package:social_care_desktop/src/use_cases/registry/register_patient_use_case.dart';
import 'package:social_care_desktop/src/use_cases/registry/remove_family_member_use_case.dart';
import 'package:social_care_desktop/src/use_cases/registry/search_patients_use_case.dart';
import 'package:social_care_desktop/src/use_cases/registry/update_social_identity_use_case.dart';
import 'package:social_care_desktop/src/use_cases/registry/withdraw_patient_use_case.dart';

// ── Builder under test (RED — file does not exist yet) ───────────────
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/facade/composition/builders/registry_use_cases.dart';

import '_builders_test_helpers.dart';

void main() {
  group('RegistryUseCases', () {
    late BuilderDeps deps;

    setUp(() {
      deps = BuilderDeps.fresh();
      addTearDown(deps.close);
    });

    test(
      'build() returns instance with all 13 fields populated and non-null',
      () {
        final useCases = RegistryUseCases.build(
          patientsCache: deps.patientsCache,
          remote: deps.registryRemote,
          outbox: deps.outbox,
          engine: deps.engine,
          clock: deps.clock,
          staleAfter: deps.staleAfter,
        );

        expect(useCases, isNotNull);
        // Reads (4)
        expect(useCases.fetchPatient, isNotNull);
        expect(useCases.fetchPatientByPersonId, isNotNull);
        expect(useCases.listPatients, isNotNull);
        expect(useCases.searchPatients, isNotNull);
        // Writes (9)
        expect(useCases.registerPatient, isNotNull);
        expect(useCases.addFamilyMember, isNotNull);
        expect(useCases.removeFamilyMember, isNotNull);
        expect(useCases.assignPrimaryCaregiver, isNotNull);
        expect(useCases.updateSocialIdentity, isNotNull);
        expect(useCases.dischargePatient, isNotNull);
        expect(useCases.readmitPatient, isNotNull);
        expect(useCases.admitPatient, isNotNull);
        expect(useCases.withdrawPatient, isNotNull);
      },
    );

    test('each field is the expected concrete UseCase type', () {
      final useCases = RegistryUseCases.build(
        patientsCache: deps.patientsCache,
        remote: deps.registryRemote,
        outbox: deps.outbox,
        engine: deps.engine,
        clock: deps.clock,
        staleAfter: deps.staleAfter,
      );

      // Reads
      expect(useCases.fetchPatient, isA<FetchPatientUseCase>());
      expect(
        useCases.fetchPatientByPersonId,
        isA<FetchPatientByPersonIdUseCase>(),
      );
      expect(useCases.listPatients, isA<ListPatientsUseCase>());
      expect(useCases.searchPatients, isA<SearchPatientsUseCase>());
      // Writes
      expect(useCases.registerPatient, isA<RegisterPatientUseCase>());
      expect(useCases.addFamilyMember, isA<AddFamilyMemberUseCase>());
      expect(useCases.removeFamilyMember, isA<RemoveFamilyMemberUseCase>());
      expect(
        useCases.assignPrimaryCaregiver,
        isA<AssignPrimaryCaregiverUseCase>(),
      );
      expect(useCases.updateSocialIdentity, isA<UpdateSocialIdentityUseCase>());
      expect(useCases.dischargePatient, isA<DischargePatientUseCase>());
      expect(useCases.readmitPatient, isA<ReadmitPatientUseCase>());
      expect(useCases.admitPatient, isA<AdmitPatientUseCase>());
      expect(useCases.withdrawPatient, isA<WithdrawPatientUseCase>());
    });

    test(
      'build() called twice with same deps produces independent instances of correct type',
      () {
        final a = RegistryUseCases.build(
          patientsCache: deps.patientsCache,
          remote: deps.registryRemote,
          outbox: deps.outbox,
          engine: deps.engine,
          clock: deps.clock,
          staleAfter: deps.staleAfter,
        );
        final b = RegistryUseCases.build(
          patientsCache: deps.patientsCache,
          remote: deps.registryRemote,
          outbox: deps.outbox,
          engine: deps.engine,
          clock: deps.clock,
          staleAfter: deps.staleAfter,
        );

        // The two builder invocations return distinct data-class instances.
        expect(identical(a, b), isFalse);

        // Each field is a freshly-constructed use case (not cached, not
        // a singleton) — confirmed by identity probes on a representative
        // read and a representative write.
        expect(identical(a.fetchPatient, b.fetchPatient), isFalse);
        expect(identical(a.registerPatient, b.registerPatient), isFalse);
        expect(identical(a.withdrawPatient, b.withdrawPatient), isFalse);

        // ...but the runtime types match (no swap, no decorator wrapping).
        expect(a.fetchPatient.runtimeType, equals(b.fetchPatient.runtimeType));
        expect(
          a.registerPatient.runtimeType,
          equals(b.registerPatient.runtimeType),
        );
        expect(
          a.withdrawPatient.runtimeType,
          equals(b.withdrawPatient.runtimeType),
        );
      },
    );
  });
}
