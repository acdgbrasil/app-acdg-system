import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:social_care/social_care.dart';

import '../../../testing/social_care_testing.dart';

void main() {
  late InMemoryPatientRepository repository;
  late GetPatientUseCase useCase;

  setUp(() {
    repository = InMemoryPatientRepository();
    useCase = GetPatientUseCase(patientRepository: repository);
  });

  group('GetPatientUseCase', () {
    test('should return patient when found', () async {
      // Arrange — seed repository with a patient
      await repository.registerPatient(PatientFixtures.validPatient);

      // Act
      final result = await useCase.execute(PatientFixtures.patientId);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.id, PatientFixtures.patientId);
      expect(result.valueOrNull?.personalData?.firstName, 'Maria');
    });

    test('should fail when patient not found', () async {
      final unknownId = PatientId.create('550e8400-e29b-41d4-a716-999999999999').valueOrNull!;

      final result = await useCase.execute(unknownId);

      expect(result.isFailure, isTrue);
      final error = (result as Failure).error as AppError;
      expect(error.code, 'PAT-404');
    });
  });
}
