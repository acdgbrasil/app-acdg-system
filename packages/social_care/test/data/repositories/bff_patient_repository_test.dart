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

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, patient.id);
    });

    test('should delegate getPatient to BFF contract', () async {
      final patient = PatientFixtures.validPatient;
      // Seed the fake BFF
      await fakeBff.registerPatient(patient);

      final result = await repository.getPatient(patient.id);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.id, patient.id);
    });

    test('should return failure when patient not found', () async {
      final unknownId = PatientId.create(
        '550e8400-e29b-41d4-a716-999999999999',
      ).valueOrNull!;

      final result = await repository.getPatient(unknownId);

      expect(result.isFailure, isTrue);
    });

    test('should delegate getPatientByPersonId to BFF contract', () async {
      final patient = PatientFixtures.validPatient;
      await fakeBff.registerPatient(patient);

      final result = await repository.getPatientByPersonId(patient.personId);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.personId, patient.personId);
    });
  });
}
