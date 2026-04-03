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
      final patient = PatientFixtures.validPatient;
      await repository.registerPatient(patient);

      // Act
      final result = await useCase.execute(patient.id.value);

      // Assert
      if (result case Success(value: final value)) {
        expect(value, isA<Patient>());
        expect(value.id.value, patient.id.value);
        expect(value.personalData?.firstName, 'Maria');
      } else {
        fail('Should have returned success');
      }
    });

    test('should fail when patient not found', () async {
      // Act
      final result = await useCase.execute('550e8400-e29b-41d4-a716-999999999999');

      // Assert
      expect(result.isFailure, isTrue);
      if (result case Failure(error: final AppError error)) {
        expect(error.code, 'PAT-404');
      }
    });
  });
}
