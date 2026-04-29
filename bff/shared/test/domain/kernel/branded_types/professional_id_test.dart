import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

/// Wave 0 TDD — shape of `ProfessionalId` as an `extension type`.
/// See `patient_id_test.dart` for the full rationale.
void main() {
  group('ProfessionalId (extension type)', () {
    const validUuid = '550e8400-e29b-41d4-a716-446655440000';
    const invalidUuid = 'not-a-uuid';

    test('create(valid) returns Success', () {
      final result = ProfessionalId.create(validUuid);
      expect(result, isA<Success<ProfessionalId>>());
      switch (result) {
        case Success(:final value):
          expect(value.value, equals(validUuid));
        case Failure():
          fail('Expected Success');
      }
    });

    test('create(invalid) returns Failure with AppError code PRI-001', () {
      final result = ProfessionalId.create(invalidUuid);
      expect(result, isA<Failure<ProfessionalId>>());
      switch (result) {
        case Success():
          fail('Expected Failure');
        case Failure(:final error):
          expect(error, isA<AppError>());
          expect((error as AppError).code, equals('PRI-001'));
      }
    });

    test('create(null) returns Failure', () {
      expect(ProfessionalId.create(null), isA<Failure<ProfessionalId>>());
    });

    test('create(empty) returns Failure', () {
      expect(ProfessionalId.create(''), isA<Failure<ProfessionalId>>());
    });

    test('two ProfessionalId from same string are equal (value semantics)', () {
      final a = ProfessionalId.trusted(validUuid);
      final b = ProfessionalId.trusted(validUuid);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString returns the raw value', () {
      final id = ProfessionalId.trusted(validUuid);
      expect(id.toString(), equals(validUuid));
    });
  });
}
