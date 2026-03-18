import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:social_care/social_care.dart';

import '../../../testing/social_care_testing.dart';

void main() {
  late InMemoryPatientRepository repository;
  late RegisterPatientUseCase useCase;

  setUp(() {
    repository = InMemoryPatientRepository();
    useCase = RegisterPatientUseCase(patientRepository: repository);
  });

  group('RegisterPatientUseCase', () {
    test('should register a valid patient and return PatientId', () async {
      final command = RegisterPatientCommand(
        patientId: PatientFixtures.patientId,
        personId: PatientFixtures.personId,
        prRelationshipId: PatientFixtures.prRelationshipId,
        personalData: PatientFixtures.personalData,
        diagnoses: [PatientFixtures.diagnosis],
        familyMembers: [PatientFixtures.familyMember],
      );

      final result = await useCase.execute(command);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, PatientFixtures.patientId);
      expect(repository.patients, hasLength(1));
      expect(repository.patients.first.id, PatientFixtures.patientId);
    });

    test('should fail when diagnoses list is empty', () async {
      final command = RegisterPatientCommand(
        patientId: PatientFixtures.patientId,
        personId: PatientFixtures.personId,
        prRelationshipId: PatientFixtures.prRelationshipId,
        personalData: PatientFixtures.personalData,
        diagnoses: [], // Empty — invariant violation
        familyMembers: [PatientFixtures.familyMember],
      );

      final result = await useCase.execute(command);

      expect(result.isFailure, isTrue);
      final error = (result as Failure).error as AppError;
      expect(error.code, 'PAT-003');
      expect(repository.patients, isEmpty);
    });

    test('should fail when no Pessoa de Referência (PR) in family', () async {
      // Family member with a DIFFERENT relationship ID (not PR)
      final nonPrRelId = LookupId.create('550e8400-e29b-41d4-a716-999999999999').valueOrNull!;
      final nonPrMember = FamilyMember.create(
        personId: PatientFixtures.familyMemberPersonId,
        relationshipId: nonPrRelId, // Not matching prRelationshipId
        residesWithPatient: true,
        birthDate: TimeStamp.fromIso('1965-08-20T00:00:00.000Z').valueOrNull!,
      ).valueOrNull!;

      final command = RegisterPatientCommand(
        patientId: PatientFixtures.patientId,
        personId: PatientFixtures.personId,
        prRelationshipId: PatientFixtures.prRelationshipId,
        personalData: PatientFixtures.personalData,
        diagnoses: [PatientFixtures.diagnosis],
        familyMembers: [nonPrMember], // No PR match
      );

      final result = await useCase.execute(command);

      expect(result.isFailure, isTrue);
      final error = (result as Failure).error as AppError;
      expect(error.code, 'PAT-008');
      expect(repository.patients, isEmpty);
    });

    test('should pass optional civilDocuments and address', () async {
      final command = RegisterPatientCommand(
        patientId: PatientFixtures.patientId,
        personId: PatientFixtures.personId,
        prRelationshipId: PatientFixtures.prRelationshipId,
        personalData: PatientFixtures.personalData,
        diagnoses: [PatientFixtures.diagnosis],
        familyMembers: [PatientFixtures.familyMember],
      );

      final result = await useCase.execute(command);

      expect(result.isSuccess, isTrue);
      final stored = repository.patients.first;
      expect(stored.personalData, PatientFixtures.personalData);
      expect(stored.civilDocuments, isNull);
      expect(stored.address, isNull);
    });
  });
}
