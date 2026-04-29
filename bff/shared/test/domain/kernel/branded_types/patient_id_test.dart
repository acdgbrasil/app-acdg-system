import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

/// Wave 0 TDD — shape of `PatientId` as an `extension type` with:
///   - `PatientId.create(String?)` static factory → `Result<PatientId>`
///   - `PatientId.trusted(String)` zero-cost constructor for trusted origins
///   - `toString()` returning the raw value
///   - native value equality (two ids from the same string are `==`)
///
/// Current state (A06c): `PatientId` is a `final class extends BaseUuid`.
/// These tests will partially pass (factory `.create` already exists) but
/// the `.trusted` named constructor does NOT exist yet — compile RED expected.
void main() {
  group('PatientId (extension type)', () {
    const validUuid = '550e8400-e29b-41d4-a716-446655440000';
    const invalidUuid = 'not-a-uuid';

    test('create(valid) returns Success', () {
      final result = PatientId.create(validUuid);
      expect(result, isA<Success<PatientId>>());
      switch (result) {
        case Success(:final value):
          expect(value.value, equals(validUuid));
        case Failure():
          fail('Expected Success');
      }
    });

    test('create(invalid) returns Failure with AppError code PAI-001', () {
      final result = PatientId.create(invalidUuid);
      expect(result, isA<Failure<PatientId>>());
      switch (result) {
        case Success():
          fail('Expected Failure');
        case Failure(:final error):
          expect(error, isA<AppError>());
          expect((error as AppError).code, equals('PAI-001'));
      }
    });

    test('create(null) returns Failure', () {
      expect(PatientId.create(null), isA<Failure<PatientId>>());
    });

    test('create(empty) returns Failure', () {
      expect(PatientId.create(''), isA<Failure<PatientId>>());
    });

    test('two PatientId from same string are equal (value semantics)', () {
      final a = PatientId.trusted(validUuid);
      final b = PatientId.trusted(validUuid);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString returns the raw value', () {
      final id = PatientId.trusted(validUuid);
      expect(id.toString(), equals(validUuid));
    });
  });
}
