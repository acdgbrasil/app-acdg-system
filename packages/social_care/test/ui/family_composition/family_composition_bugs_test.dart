import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:shared/src/infrastructure/mappers/registry_mapper.dart';
import 'package:social_care/social_care.dart';
import 'package:social_care/src/ui/family_composition/view_models/family_composition_view_model.dart';

import '../../../testing/fakes/in_memory_lookup_repository.dart';
import '../../../testing/fakes/in_memory_patient_repository.dart';

void main() {
  late FamilyCompositionViewModel viewModel;
  late InMemoryPatientRepository fakeRepo;
  late InMemoryLookupRepository fakeLookup;

  const patientIdStr = '00000000-0000-0000-0000-000000000100';
  const specificityId = '00000000-0000-0000-0000-000000000010';

  setUp(() async {
    fakeRepo = InMemoryPatientRepository();
    fakeLookup = InMemoryLookupRepository();
    
    fakeLookup.seed('dominio_parentesco', [
      const LookupItem(id: '00000000-0000-0000-0000-000000000001', codigo: 'FILHO', descricao: 'Filho'),
    ]);

    fakeLookup.seed('dominio_tipo_identidade', [
      const LookupItem(id: specificityId, codigo: 'QUILOMBOLA', descricao: 'Quilombola'),
    ]);

    final pId = switch (PatientId.create(patientIdStr)) {
      Success(:final value) => value,
      Failure(:final error) => throw StateError('Setup failed: $error'),
    };

    // Paciente inicial já com uma especificidade vinda do banco
    await fakeRepo.registerPatient(Patient.reconstitute(
      id: pId,
      personId: PersonId.create('00000000-0000-0000-0000-000000000200').valueOrNull!,
      prRelationshipId: LookupId.create('00000000-0000-0000-0000-000000000001').valueOrNull!,
      version: 1,
      socialIdentity: SocialIdentity.create(
        typeId: LookupId.create(specificityId).valueOrNull!,
      ).valueOrNull!,
    ));

    viewModel = FamilyCompositionViewModel(
      patientId: patientIdStr,
      getPatientUseCase: GetPatientUseCase(patientRepository: fakeRepo),
      addFamilyMemberUseCase: AddFamilyMemberUseCase(patientRepository: fakeRepo),
      removeFamilyMemberUseCase: RemoveFamilyMemberUseCase(patientRepository: fakeRepo),
      updatePrimaryCaregiverUseCase: UpdatePrimaryCaregiverUseCase(patientRepository: fakeRepo),
      updateSocialIdentityUseCase: UpdateSocialIdentityUseCase(patientRepository: fakeRepo),
      lookupRepository: fakeLookup,
      );

      await Future<void>.delayed(Duration.zero);
      });
  group('ACDG Gold Standard: Contract & Performance Regression', () {
    
    test('BUG 1 & 9: canSave MUST be false after load and true only after change', () async {
      await viewModel.loadPatientCommand.execute();
      
      // Deve reconhecer a especificidade vinda do banco e dar canSave false
      expect(viewModel.selectedSpecificityId, equals(specificityId));
      expect(viewModel.canSave, isFalse, reason: 'canSave deve ser false se o estado for igual ao do banco');

      viewModel.updateSpecificity('outra_spec');
      expect(viewModel.canSave, isTrue);
    });

    test('BUG 4 & 7: familyMemberToJson MUST strictly use key "relationship" (Contract Alignment)', () {
      final memberId = switch (PersonId.create('00000000-0000-0000-0000-000000000999')) {
        Success(:final value) => value,
        Failure(:final error) => throw StateError('Setup failed: $error'),
      };
      
      final member = FamilyMember.reconstitute(
        personId: memberId,
        relationshipId: LookupId.create('00000000-0000-0000-0000-000000000001').valueOrNull!,
        isPrimaryCaregiver: false,
        residesWithPatient: true,
        hasDisability: false,
        requiredDocuments: [],
        birthDate: TimeStamp.now,
      );

      final json = PatientTranslator.familyMemberToJson(member);

      expect(json.containsKey('relationship'), isTrue, reason: 'O servidor exige "relationship" no JSON');
      expect(json.containsKey('relationshipId'), isFalse, reason: 'Não envie "relationshipId", evite poluição de contrato');
    });

    test('PERFORMANCE: ageProfile MUST be memoized (computed only on data change)', () async {
      await viewModel.loadPatientCommand.execute();

      final profile1 = viewModel.ageProfile;
      final profile2 = viewModel.ageProfile;

      // Verifica se o objeto retornado é o mesmo (memoização via cache)
      expect(identical(profile1, profile2), isTrue, reason: 'ageProfile deve ser cacheado para evitar loops excessivos no build');
    });

    test('BUG 17: familyMemberFromJson MUST support both "relationship" and "relationshipId"', () {
      final jsonWithNewKey = {
        'personId': '00000000-0000-0000-0000-000000000999',
        'relationship': '00000000-0000-0000-0000-000000000001',
        'birthDate': '1990-01-01T00:00:00.000Z',
        'isResiding': true,
        'isCaregiver': false,
      };

      final result = RegistryMapper.familyMemberFromJson(jsonWithNewKey);

      expect(result.isSuccess, isTrue, reason: 'Deve suportar a nova chave "relationship" vinda do Sync Queue');
      final member = (result as Success<FamilyMember>).value;
      expect(member.relationshipId.value, equals('00000000-0000-0000-0000-000000000001'));
    });
  });
}
