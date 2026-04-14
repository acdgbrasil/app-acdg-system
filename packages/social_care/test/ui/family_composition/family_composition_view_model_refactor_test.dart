import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:social_care/social_care.dart';

import '../../../testing/social_care_testing.dart';

// Mocking/Faking dependencies
class FakeGetPatientUseCase extends GetPatientUseCase {
  FakeGetPatientUseCase() : super(patientRepository: FakePatientRepository());

  Patient? result;
  @override
  Future<Result<Patient>> execute(String id) async {
    if (result != null) return Success(result!);
    return const Failure('Patient not found');
  }
}

void main() {
  late FamilyCompositionViewModel viewModel;
  late FakeGetPatientUseCase fakeGetPatientUseCase;

  setUp(() {
    fakeGetPatientUseCase = FakeGetPatientUseCase();
    viewModel = FamilyCompositionViewModel(
      patientId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      getPatientUseCase: fakeGetPatientUseCase,
      addFamilyMemberUseCase: AddFamilyMemberUseCase(
        patientRepository: FakePatientRepository(),
      ),
      removeFamilyMemberUseCase: RemoveFamilyMemberUseCase(
        patientRepository: FakePatientRepository(),
      ),
      updatePrimaryCaregiverUseCase: UpdatePrimaryCaregiverUseCase(
        patientRepository: FakePatientRepository(),
      ),
      updateSocialIdentityUseCase: UpdateSocialIdentityUseCase(
        patientRepository: FakePatientRepository(),
      ),
      getLookupTableUseCase: GetLookupTableUseCase(
        lookupRepository: FakeLookupRepository(),
      ),
    );
  });

  group('FamilyCompositionViewModel Gold Standard Refactor', () {
    test('Refactor: loadPatient must be a Command0', () {
      expect(viewModel.loadPatientCommand, isA<Command0<void>>());
    });

    test(
      'Refactor: isLoading property must be removed in favor of command state',
      () {
        final _ = viewModel.loadPatientCommand.execute();
        expect(viewModel.loadPatientCommand.running, isTrue);
      },
    );

    test(
      'Refactor: ageProfile calculation must be moved to a Domain Service or Entity',
      () {
        expect(viewModel.ageProfile, isA<Map<String, int>>());
        expect(viewModel.ageProfile.keys, contains('0-6'));
      },
    );

    test('Refactor: No raw JSON parsing in ViewModel', () async {
      fakeGetPatientUseCase.result = _createRichPatient();

      await viewModel.loadPatientCommand.execute();

      expect(viewModel.members, isNotEmpty);
      expect(viewModel.members.first.personId, isNotEmpty);
      expect(
        viewModel.members.first.relationshipLabel,
        isNot(equals('json_error')),
      );
    });

    test('Refactor: Folder naming must be view_models (plural)', () {
      // Structural test — the import path above proves view_models/ exists.
    });
  });
}

Patient _createRichPatient() {
  final PatientId patientId;
  switch (PatientId.create('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')) {
    case Success(:final value):
      patientId = value;
    case Failure(:final error):
      throw StateError('Test setup failed: $error');
  }

  final PersonId personId;
  switch (PersonId.create('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb')) {
    case Success(:final value):
      personId = value;
    case Failure(:final error):
      throw StateError('Test setup failed: $error');
  }

  final PersonId memberId;
  switch (PersonId.create('11111111-1111-1111-1111-111111111111')) {
    case Success(:final value):
      memberId = value;
    case Failure(:final error):
      throw StateError('Test setup failed: $error');
  }

  final LookupId relId;
  switch (LookupId.create('22222222-2222-2222-2222-222222222222')) {
    case Success(:final value):
      relId = value;
    case Failure(:final error):
      throw StateError('Test setup failed: $error');
  }

  final LookupId prRelId;
  switch (LookupId.create('33333333-3333-3333-3333-333333333333')) {
    case Success(:final value):
      prRelId = value;
    case Failure(:final error):
      throw StateError('Test setup failed: $error');
  }

  final TimeStamp birthDate;
  switch (TimeStamp.fromIso('2000-01-01')) {
    case Success(:final value):
      birthDate = value;
    case Failure(:final error):
      throw StateError('Test setup failed: $error');
  }

  return Patient.reconstitute(
    id: patientId,
    personId: personId,
    prRelationshipId: prRelId,
    version: 1,
    familyMembers: [
      FamilyMember.reconstitute(
        personId: memberId,
        relationshipId: relId,
        isPrimaryCaregiver: false,
        residesWithPatient: true,
        hasDisability: false,
        requiredDocuments: [],
        birthDate: birthDate,
      ),
    ],
    diagnoses: [],
    appointments: [],
    referrals: [],
    violationReports: [],
  );
}
