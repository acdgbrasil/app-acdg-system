import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

void main() {
  group('FakeAuditBff', () {
    test('implements AuditContract', () {
      final AuditContract fake = FakeAuditBff();
      expect(fake, isA<AuditContract>());
    });

    test('getAuditTrail: returns Success with a list (empty by default)',
        () async {
      final fake = FakeAuditBff();

      final result = await fake.getAuditTrail('patient-1');

      expect(result,
          isA<Success<StandardResponse<List<AuditTrailEntryResponse>>>>());
      switch (result) {
        case Success(:final value):
          expect(value.data, isA<List<AuditTrailEntryResponse>>());
        case Failure():
          fail('getAuditTrail should succeed for a fake');
      }
    });
  });
}
