// T03: the thin `PatientService(bff:)` stub was replaced by the Dio-backed
// service. The legacy tests continue to exercise the bridge class
// `LegacyPatientService`, which keeps the old signatures alive for
// non-regression until T19.
//
// ignore_for_file: deprecated_member_use
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:social_care/src/data/services/legacy_patient_service.dart';

void main() {
  late FakeSocialCareBff fakeBff;
  late LegacyPatientService service;

  setUp(() {
    fakeBff = FakeSocialCareBff(delay: Duration.zero);
    service = LegacyPatientService(bff: fakeBff);
  });

  group('PatientService (legacy)', () {
    test('fetchPatient calls bff.fetchPatient correctly', () async {
      // Arrange
      final patientIdRes = PatientId.create(
        '550e8400-e29b-41d4-a716-446655440000',
      );
      final personIdRes = PersonId.create(
        '550e8400-e29b-41d4-a716-446655440001',
      );
      final relIdRes = LookupId.create('550e8400-e29b-41d4-a716-446655440002');

      if (patientIdRes case Success(value: final patientId)) {
        if (personIdRes case Success(value: final personId)) {
          if (relIdRes case Success(value: final prRelationshipId)) {
            final patient = Patient.reconstitute(
              id: patientId,
              version: 1,
              personId: personId,
              prRelationshipId: prRelationshipId,
            );
            await fakeBff.registerPatient(patient);

            // Act
            final result = await service.fetchPatient(patientId);

            // Assert
            if (result case Success(value: final p)) {
              expect(p.patientId, patientId.value);
            } else {
              fail('Should have returned success');
            }
            return;
          }
        }
      }
      fail('Failed to create test IDs');
    });

    test('fetchPatient returns failure when patient not found', () async {
      // Arrange
      final patientIdRes = PatientId.create(
        '550e8400-e29b-41d4-a716-446655440003',
      );

      if (patientIdRes case Success(value: final patientId)) {
        // Act
        final result = await service.fetchPatient(patientId);

        // Assert
        expect(result.isFailure, isTrue);
      } else {
        fail('Failed to create test ID');
      }
    });
  });
}
