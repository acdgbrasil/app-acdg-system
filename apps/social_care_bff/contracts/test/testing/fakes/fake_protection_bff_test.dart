import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

void main() {
  group('FakeProtectionBff', () {
    test('implements ProtectionContract', () {
      final ProtectionContract fake = FakeProtectionBff();
      expect(fake, isA<ProtectionContract>());
    });

    test('reportViolation: returns Success with StandardIdResponse', () async {
      final fake = FakeProtectionBff();
      const request = ReportRightsViolationRequest(
        victimId: 'patient-1',
        violationType: 'physical',
        descriptionOfFact: 'Incident description for tests.',
      );

      final result = await fake.reportViolation('patient-1', request);

      expect(result, isA<Success<StandardIdResponse>>());
      switch (result) {
        case Success(:final value):
          expect(value.data.id, isNotEmpty);
        case Failure():
          fail('reportViolation should succeed for a fake');
      }
    });
  });
}
