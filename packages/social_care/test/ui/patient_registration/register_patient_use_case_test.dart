import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:social_care/social_care.dart';

import '../../../testing/social_care_testing.dart';

void main() {
  late RegisterPatientUseCase useCase;
  late InMemoryPatientRepository repository;

  setUp(() {
    repository = InMemoryPatientRepository();
    useCase = RegisterPatientUseCase(patientRepository: repository);
  });

  group('RegisterPatientUseCase', () {
    test(
      'should register a valid patient and auto-add them as PR member',
      () async {
        final intent = RegisterPatientIntent(
          firstName: 'Maria',
          lastName: 'Silva',
          motherName: 'Ana Silva',
          nationality: 'Brasileira',
          sex: Sex.feminino,
          birthDate: kBirthDate,
          prRelationshipId: PatientFixtures.prRelationshipId.value,
          cpf: PatientFixtures.validCpf,
          addressState: 'SP',
          city: 'São Paulo',
          residenceLocation: ResidenceLocation.urbano,
          diagnoses: [PatientFixtures.diagnosis],
          familyMembers: [], // Only other members go here
        );

        final result = await useCase.execute(intent);

        expect(result.isSuccess, isTrue);
        final stored = repository.patients.first;
        expect(stored.personalData?.firstName, 'Maria');
        expect(stored.civilDocuments?.cpf?.value, PatientFixtures.validCpf);
        expect(stored.address?.city, 'São Paulo');

        // Verify domain invariant: Patient is the PR member
        expect(stored.familyMembers, hasLength(1));
        expect(
          stored.familyMembers.first.relationshipId.value,
          intent.prRelationshipId,
        );
        expect(stored.familyMembers.first.isPrimaryCaregiver, isTrue);
      },
    );

    test('should fail when diagnoses list is empty', () async {
      final intent = RegisterPatientIntent(
        firstName: 'Maria',
        lastName: 'Silva',
        motherName: 'Ana Silva',
        nationality: 'Brasileira',
        sex: Sex.feminino,
        birthDate: kBirthDate,
        prRelationshipId: PatientFixtures.prRelationshipId.value,
        cpf: PatientFixtures.validCpf,
        residenceLocation: ResidenceLocation.urbano,
        city: 'São Paulo',
        addressState: 'SP',
        diagnoses: const <Diagnosis>[], // Empty — invariant violation
      );

      final result = await useCase.execute(intent);

      expect(result.isFailure, isTrue);
      final error = (result as Failure).error;
      expect(error, isA<InvalidDataError>());
      expect(repository.patients, isEmpty);
    });

    test('should fail when multiple PRs are provided', () async {
      // Manual member with PR relationship ID
      final extraPrMember = FamilyMember.create(
        personId: PatientFixtures.familyMemberPersonId,
        relationshipId: PatientFixtures.prRelationshipId, // Same as patient
        residesWithPatient: true,
        birthDate: TimeStamp.fromIso('1965-08-20T00:00:00.000Z').valueOrNull!,
      ).valueOrNull!;

      final intent = RegisterPatientIntent(
        firstName: 'Maria',
        lastName: 'Silva',
        motherName: 'Ana Silva',
        nationality: 'Brasileira',
        sex: Sex.feminino,
        birthDate: kBirthDate,
        prRelationshipId: PatientFixtures.prRelationshipId.value,
        cpf: PatientFixtures.validCpf,
        city: 'São Paulo',
        addressState: 'SP',
        residenceLocation: ResidenceLocation.urbano,
        diagnoses: [PatientFixtures.diagnosis],
        familyMembers: [
          extraPrMember,
        ], // This will create 2 PRs (Auto + Manual)
      );

      final result = await useCase.execute(intent);

      expect(result.isFailure, isTrue);
      final error = (result as Failure).error;
      // PAT-009: Multiple PRs not allowed
      expect(error, isA<MultiplePrimaryReferencesError>());
    });
  });
}

final kBirthDate = DateTime(1990, 5, 15);
