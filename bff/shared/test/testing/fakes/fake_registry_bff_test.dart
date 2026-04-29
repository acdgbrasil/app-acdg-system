import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

void main() {
  group('FakeRegistryBff', () {
    test('implements RegistryContract', () {
      final RegistryContract fake = FakeRegistryBff();
      expect(fake, isA<RegistryContract>());
    });

    test('registerPatient + fetchPatients: state preserved', () async {
      final fake = FakeRegistryBff();
      const request = RegisterPatientRequest(
        personId: 'person-1',
        initialDiagnoses: [
          DiagnosisDraftDto(
            icdCode: 'G71.0',
            date: '2024-01-01',
            description: 'Muscular dystrophy',
          ),
        ],
        prRelationshipId: 'relationship-1',
      );

      final registerResult = await fake.registerPatient(request);
      expect(registerResult, isA<Success<StandardIdResponse>>());

      final fetchResult = await fake.fetchPatients();
      expect(
        fetchResult,
        isA<Success<PaginatedList<PatientSummaryResponse>>>(),
      );
      switch (fetchResult) {
        case Success(:final value):
          expect(value.data, hasLength(1));
          expect(value.data.first.personId, equals('person-1'));
        case Failure():
          fail('fetchPatients should succeed after registerPatient');
      }
    });
  });
}
