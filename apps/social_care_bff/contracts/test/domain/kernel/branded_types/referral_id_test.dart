import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

/// Wave 0 TDD — shape of `ReferralId` as an `extension type`.
/// See `patient_id_test.dart` for the full rationale.
void main() {
  group('ReferralId (extension type)', () {
    const validUuid = '550e8400-e29b-41d4-a716-446655440000';
    const invalidUuid = 'not-a-uuid';

    test('create(valid) returns Success', () {
      final result = ReferralId.create(validUuid);
      expect(result, isA<Success<ReferralId>>());
      switch (result) {
        case Success(:final value):
          expect(value.value, equals(validUuid));
        case Failure():
          fail('Expected Success');
      }
    });

    test('create(invalid) returns Failure with AppError code RI-001', () {
      final result = ReferralId.create(invalidUuid);
      expect(result, isA<Failure<ReferralId>>());
      switch (result) {
        case Success():
          fail('Expected Failure');
        case Failure(:final error):
          expect(error, isA<AppError>());
          expect((error as AppError).code, equals('RI-001'));
      }
    });

    test('create(null) returns Failure', () {
      expect(ReferralId.create(null), isA<Failure<ReferralId>>());
    });

    test('create(empty) returns Failure', () {
      expect(ReferralId.create(''), isA<Failure<ReferralId>>());
    });

    test('two ReferralId from same string are equal (value semantics)', () {
      final a = ReferralId.trusted(validUuid);
      final b = ReferralId.trusted(validUuid);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString returns the raw value', () {
      final id = ReferralId.trusted(validUuid);
      expect(id.toString(), equals(validUuid));
    });
  });
}
