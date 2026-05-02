import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

/// Wave 0 TDD — shape of `PersonId` as an `extension type`.
/// See `patient_id_test.dart` for the full rationale.
void main() {
  group('PersonId (extension type)', () {
    const validUuid = '550e8400-e29b-41d4-a716-446655440000';
    const invalidUuid = 'not-a-uuid';

    test('create(valid) returns Success', () {
      final result = PersonId.create(validUuid);
      expect(result, isA<Success<PersonId>>());
      switch (result) {
        case Success(:final value):
          expect(value.value, equals(validUuid));
        case Failure():
          fail('Expected Success');
      }
    });

    test('create(invalid) returns Failure with AppError code PID-001', () {
      final result = PersonId.create(invalidUuid);
      expect(result, isA<Failure<PersonId>>());
      switch (result) {
        case Success():
          fail('Expected Failure');
        case Failure(:final error):
          expect(error, isA<AppError>());
          expect((error as AppError).code, equals('PID-001'));
      }
    });

    test('create(null) returns Failure', () {
      expect(PersonId.create(null), isA<Failure<PersonId>>());
    });

    test('create(empty) returns Failure', () {
      expect(PersonId.create(''), isA<Failure<PersonId>>());
    });

    test('two PersonId from same string are equal (value semantics)', () {
      final a = PersonId.trusted(validUuid);
      final b = PersonId.trusted(validUuid);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString returns the raw value', () {
      final id = PersonId.trusted(validUuid);
      expect(id.toString(), equals(validUuid));
    });
  });
}
