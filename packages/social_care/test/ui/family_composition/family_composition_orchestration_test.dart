import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:social_care/src/logic/use_case/family/add_family_member_use_case.dart';
import 'package:social_care/src/logic/use_case/family/remove_family_member_use_case.dart';
import 'package:social_care/src/logic/use_case/family/update_primary_caregiver_use_case.dart';
import 'package:social_care/src/logic/use_case/registry/get_patient_use_case.dart';
import 'package:social_care/src/logic/use_case/registry/update_social_identity_use_case.dart';
import 'package:social_care/src/ui/family_composition/models/add_member_result.dart';
import 'package:social_care/src/ui/family_composition/models/family_member_model.dart';
import 'package:social_care/src/ui/family_composition/view_models/family_composition_view_model.dart';

import '../../../testing/social_care_testing.dart';

void main() {
  group('FamilyCompositionViewModel Orchestration (Mission 008.1)', () {
    late FamilyCompositionViewModel viewModel;
    late InMemoryPatientRepository fakeRepo;
    late InMemoryLookupRepository fakeLookup;
    const patientIdStr = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    const personIdStr = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
    const lookupIdStr = 'cccccccc-cccc-cccc-cccc-cccccccccccc';

    setUp(() async {
      fakeRepo = InMemoryPatientRepository();
      fakeLookup = InMemoryLookupRepository();

      // Seed lookups FIRST
      fakeLookup.seed('dominio_parentesco', [
        const LookupItem(id: lookupIdStr, codigo: 'FILHO', descricao: 'Filho'),
        const LookupItem(
          id: 'dddddddd-dddd-dddd-dddd-dddddddddddd',
          codigo: 'PESSOA_REFERENCIA',
          descricao: 'Pessoa de Referência',
        ),
      ]);

      final pId = switch (PatientId.create(patientIdStr)) {
        Success(:final value) => value,
        Failure(:final error) => throw StateError(
          'PatientId Setup failed: $error',
        ),
      };

      final personId = switch (PersonId.create(personIdStr)) {
        Success(:final value) => value,
        Failure(:final error) => throw StateError(
          'PersonId Setup failed: $error',
        ),
      };

      final prRelId = switch (LookupId.create(
        'dddddddd-dddd-dddd-dddd-dddddddddddd',
      )) {
        Success(:final value) => value,
        Failure(:final error) => throw StateError(
          'LookupId Setup failed: $error',
        ),
      };

      await fakeRepo.registerPatient(
        Patient.reconstitute(
          id: pId,
          personId: personId,
          prRelationshipId: prRelId,
          version: 1,
          familyMembers: [],
          diagnoses: [],
          appointments: [],
          referrals: [],
          violationReports: [],
        ),
      );

      viewModel = FamilyCompositionViewModel(
        patientId: patientIdStr,
        getPatientUseCase: GetPatientUseCase(patientRepository: fakeRepo),
        addFamilyMemberUseCase: AddFamilyMemberUseCase(
          patientRepository: fakeRepo,
        ),
        removeFamilyMemberUseCase: RemoveFamilyMemberUseCase(
          patientRepository: fakeRepo,
        ),
        updatePrimaryCaregiverUseCase: UpdatePrimaryCaregiverUseCase(
          patientRepository: fakeRepo,
        ),
        updateSocialIdentityUseCase: UpdateSocialIdentityUseCase(
          patientRepository: fakeRepo,
        ),
        lookupRepository: fakeLookup,
      );

      // Wait a bit for lookups to load (constructor call)
      await Future<void>.delayed(Duration.zero);
    });

    test(
      'handleModalSave (New Member): should execute add command and reload',
      () async {
        final result = _createMockResult(isPrimaryCaregiver: false);

        await viewModel.handleModalSave(result);

        expect(
          viewModel.addMemberCommand.completed,
          isTrue,
          reason:
              'Add command failed. Result: ${viewModel.addMemberCommand.result}',
        );
        expect(
          viewModel.loadPatientCommand.completed,
          isTrue,
          reason: 'Reload failed after add',
        );
      },
    );

    test(
      'handleModalSave (Edit Member): should remove old and add new',
      () async {
        const existingIdStr = '11111111-1111-1111-1111-111111111111';
        final existing = _createMockMember(id: existingIdStr);

        final result = _createMockResult(isPrimaryCaregiver: false);

        await viewModel.handleModalSave(result, existing: existing);

        expect(
          viewModel.removeMemberCommand.completed,
          isTrue,
          reason: 'Remove old member failed',
        );
        expect(
          viewModel.addMemberCommand.completed,
          isTrue,
          reason: 'Add replacement failed',
        );
      },
    );

    test(
      'handleRemove: should guard reference person and not execute command',
      () async {
        final pr = _createMockMember(
          id: '22222222-2222-2222-2222-222222222222',
          isPr: true,
        );

        final removed = await viewModel.handleRemove(pr);

        expect(
          removed,
          isFalse,
          reason: 'Should not allow removing reference person',
        );
        expect(
          viewModel.removeMemberCommand.result,
          isNull,
          reason: 'Command should not have run',
        );
      },
    );
  });
}

AddMemberResult _createMockResult({required bool isPrimaryCaregiver}) {
  return AddMemberResult(
    name: 'John Doe',
    birthDate: DateTime(1990, 1, 1),
    sex: 'Masculino',
    relationshipCode: 'FILHO',
    residesWithPatient: true,
    hasDisability: false,
    isPrimaryCaregiver: isPrimaryCaregiver,
    requiredDocuments: {'RG'},
  );
}

FamilyMemberModel _createMockMember({required String id, bool isPr = false}) {
  return FamilyMemberModel(
    personId: id,
    relationshipLabel: isPr ? 'Pessoa de Referência' : 'Filho',
    relationshipCode: isPr ? 'PESSOA_REFERENCIA' : 'FILHO',
    birthDate: DateTime(1990, 1, 1),
    sex: 'Masculino',
    isReferencePerson: isPr,
    isPrimaryCaregiver: false,
    residesWithPatient: true,
    hasDisability: false,
    requiredDocuments: {},
  );
}
