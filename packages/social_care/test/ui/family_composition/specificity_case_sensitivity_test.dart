import 'package:flutter_test/flutter_test.dart';
import 'package:social_care/social_care.dart';
import 'package:social_care/src/ui/family_composition/view_models/family_composition_view_model.dart';
import 'package:shared/shared.dart';
import 'package:core/core.dart';
import '../../../testing/fakes/in_memory_patient_repository.dart';
import '../../../testing/fakes/in_memory_lookup_repository.dart';

void main() {
  late FamilyCompositionViewModel viewModel;
  late InMemoryPatientRepository fakeRepo;
  late InMemoryLookupRepository fakeLookup;

  const patientIdStr = 'ea781937-9a92-46bd-a968-1127e54ef1e8';
  // ID em MAIÚSCULAS vindo do Mock/API de Lookups
  const specificityIdUpper = '9DF22864-05B2-461E-8F61-DAD23D23EA76';
  // ID em minúsculas vindo do Domínio/Paciente (normalizado pelo PatientId/LookupId)
  const specificityIdLower = '9df22864-05b2-461e-8f61-dad23d23ea76';

  setUp(() async {
    fakeRepo = InMemoryPatientRepository();
    fakeLookup = InMemoryLookupRepository();

    // Simula API de Lookups retornando IDs em MAIÚSCULAS
    fakeLookup.seed('dominio_parentesco', [
      LookupItem(id: '00000000-0000-0000-0000-000000000001', codigo: 'PESSOA_REFERENCIA', descricao: 'Pessoa de Referência'),
    ]);

    fakeLookup.seed('dominio_tipo_identidade', [
      LookupItem(id: specificityIdUpper, codigo: 'ASSENTADO', descricao: 'Assentado(a)'),
    ]);

    final pId = PatientId.create(patientIdStr).valueOrNull!;

    // Simula Paciente vindo do banco com ID normalizado (lowercase pelo BaseUuid)
    await fakeRepo.registerPatient(Patient.reconstitute(
      id: pId,
      personId: PersonId.create('00000000-0000-0000-0000-000000000200').valueOrNull!,
      prRelationshipId: LookupId.create('00000000-0000-0000-0000-000000000001').valueOrNull!,
      version: 1,
      socialIdentity: SocialIdentity.create(
        typeId: LookupId.create(specificityIdLower).valueOrNull!,
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
  });

  group('FamilyCompositionViewModel: Case Sensitivity Regression', () {
    test('BUG: selectedId MUST match a lookup item ID regardless of casing', () async {
      // 1. Carregar lookups e paciente
      // O ViewModel chama _loadLookups no construtor, mas é async. 
      // Precisamos garantir que terminou.
      await Future.delayed(Duration.zero);
      await viewModel.loadPatientCommand.execute();

      final selectedId = viewModel.selectedSpecificityId;
      final lookupItems = viewModel.specificityLookup;

      // Log para debug no console de testes se necessário
      print('Selected ID: $selectedId');
      print('Lookup IDs: ${lookupItems.map((e) => e.id).toList()}');

      // O teste de regressão: Deve existir um item na lista cujo ID seja IGUAL ao selecionado.
      // Se um for lower e outro upper, isso falha, quebrando o "check" na UI.
      final hasMatch = lookupItems.any((item) => item.id == selectedId);

      expect(
        hasMatch, 
        isTrue, 
        reason: 'A UI faz comparação estrita (item.id == selectedId). '
                'Se os IDs não forem normalizados para o mesmo case, o check não aparecerá.'
      );
    });

    test('BUG: canSave MUST remain false after selecting logically identical ID (case-insensitive)', () async {
      await Future.delayed(Duration.zero);
      await viewModel.loadPatientCommand.execute();

      // O ID original é lowercase (vindo do domínio)
      // O usuário clica em um item que veio em UPPERCASE da API de Lookups
      viewModel.updateSpecificity(specificityIdUpper);
      
      expect(viewModel.canSave, isFalse, reason: 'Selecionar o mesmo ID (mesmo que com casing diferente) não deve sujar o estado');
    });
  });
}
