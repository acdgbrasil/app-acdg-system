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
    test('should return Patient when given a valid UUID string', () async {
      // Arrange
      final patient = PatientFixtures.validPatient;
      await repository.registerPatient(patient);

      // Act
      final result = await useCase.execute(patient.id.value);

      // Assert
      if (result case Success(value: final value)) {
        expect(value, isA<Patient>());
        expect(value.id.value, patient.id.value);
      } else {
        fail('Should have returned success');
      }
    });

    test('should return failure when given an invalid UUID string', () async {
      // Act
      final result = await useCase.execute('invalid-uuid');

      // Assert
      expect(result.isFailure, isTrue);
    });
  });
}
