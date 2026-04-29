import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

void main() {
  group('FakeCareBff', () {
    test('implements CareContract', () {
      final CareContract fake = FakeCareBff();
      expect(fake, isA<CareContract>());
    });

    test('registerAppointment: returns Success with StandardIdResponse',
        () async {
      final fake = FakeCareBff();
      const request = RegisterAppointmentRequest(
        professionalId: 'professional-1',
        summary: 'Initial intake appointment',
      );

      final result = await fake.registerAppointment('patient-1', request);

      expect(result, isA<Success<StandardIdResponse>>());
      switch (result) {
        case Success(:final value):
          expect(value.data.id, isNotEmpty);
        case Failure():
          fail('registerAppointment should succeed for a fake');
      }
    });
  });
}
