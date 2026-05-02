import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

/// Wave 0 TDD — shape of `AppointmentId` as an `extension type`.
/// See `patient_id_test.dart` for the full rationale.
void main() {
  group('AppointmentId (extension type)', () {
    const validUuid = '550e8400-e29b-41d4-a716-446655440000';
    const invalidUuid = 'not-a-uuid';

    test('create(valid) returns Success', () {
      final result = AppointmentId.create(validUuid);
      expect(result, isA<Success<AppointmentId>>());
      switch (result) {
        case Success(:final value):
          expect(value.value, equals(validUuid));
        case Failure():
          fail('Expected Success');
      }
    });

    test('create(invalid) returns Failure with AppError code AI-001', () {
      final result = AppointmentId.create(invalidUuid);
      expect(result, isA<Failure<AppointmentId>>());
      switch (result) {
        case Success():
          fail('Expected Failure');
        case Failure(:final error):
          expect(error, isA<AppError>());
          expect((error as AppError).code, equals('AI-001'));
      }
    });

    test('create(null) returns Failure', () {
      expect(AppointmentId.create(null), isA<Failure<AppointmentId>>());
    });

    test('create(empty) returns Failure', () {
      expect(AppointmentId.create(''), isA<Failure<AppointmentId>>());
    });

    test('two AppointmentId from same string are equal (value semantics)', () {
      final a = AppointmentId.trusted(validUuid);
      final b = AppointmentId.trusted(validUuid);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString returns the raw value', () {
      final id = AppointmentId.trusted(validUuid);
      expect(id.toString(), equals(validUuid));
    });
  });
}
