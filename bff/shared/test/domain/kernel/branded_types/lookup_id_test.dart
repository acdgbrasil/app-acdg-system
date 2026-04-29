import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

/// Wave 0 TDD — shape of `LookupId` as an `extension type`.
/// See `patient_id_test.dart` for the full rationale.
void main() {
  group('LookupId (extension type)', () {
    const validUuid = '550e8400-e29b-41d4-a716-446655440000';
    const invalidUuid = 'not-a-uuid';

    test('create(valid) returns Success', () {
      final result = LookupId.create(validUuid);
      expect(result, isA<Success<LookupId>>());
      switch (result) {
        case Success(:final value):
          expect(value.value, equals(validUuid));
        case Failure():
          fail('Expected Success');
      }
    });

    test('create(invalid) returns Failure with AppError code LID-001', () {
      final result = LookupId.create(invalidUuid);
      expect(result, isA<Failure<LookupId>>());
      switch (result) {
        case Success():
          fail('Expected Failure');
        case Failure(:final error):
          expect(error, isA<AppError>());
          expect((error as AppError).code, equals('LID-001'));
      }
    });

    test('create(null) returns Failure', () {
      expect(LookupId.create(null), isA<Failure<LookupId>>());
    });

    test('create(empty) returns Failure', () {
      expect(LookupId.create(''), isA<Failure<LookupId>>());
    });

    test('two LookupId from same string are equal (value semantics)', () {
      final a = LookupId.trusted(validUuid);
      final b = LookupId.trusted(validUuid);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString returns the raw value', () {
      final id = LookupId.trusted(validUuid);
      expect(id.toString(), equals(validUuid));
    });
  });
}
