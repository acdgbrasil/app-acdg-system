import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:social_care/social_care.dart';

import '../../../testing/social_care_testing.dart';

void main() {
  late FakeSocialCareBff fakeBff;
  late BffPatientRepository repository;

  setUp(() {
    fakeBff = FakeSocialCareBff(delay: Duration.zero);
    repository = BffPatientRepository(
      bff: fakeBff,
      patientService: PatientService(bff: fakeBff),
    );
  });

  group('BffPatientRepository', () {
    test('should delegate registerPatient to BFF contract', () async {
      final patient = PatientFixtures.validPatient;

      final result = await repository.registerPatient(patient);

      if (result case Success(value: final id)) {
        expect(id, patient.id);
      } else {
        fail('Should have returned success');
      }
    });

    test('should map getPatient to Patient domain entity', () async {
      // Arrange
      final patient = PatientFixtures.validPatient;
      await fakeBff.registerPatient(patient);

      // Act
      final result = await repository.getPatient(patient.id);

      // Assert
      if (result case Success(value: final value)) {
        expect(value, isA<Patient>());
        expect(value.id.value, patient.id.value);
      } else {
        fail('Should have returned success');
      }
    });

    test('should return failure when patient not found', () async {
      // Arrange
      final unknownIdRes = PatientId.create('550e8400-e29b-41d4-a716-999999999999');

      if (unknownIdRes case Success(value: final unknownId)) {
        // Act
        final result = await repository.getPatient(unknownId);

        // Assert
        expect(result.isFailure, isTrue);
      } else {
        fail('Failed to create test ID');
      }
    });

    test('should delegate getPatientByPersonId to BFF contract', () async {
      final patient = PatientFixtures.validPatient;
      await fakeBff.registerPatient(patient);

      final result = await repository.getPatientByPersonId(patient.personId);

      if (result case Success(value: final p)) {
        expect(p.personId, patient.personId);
      } else {
        fail('Should have returned success');
      }
    });
  });
}
