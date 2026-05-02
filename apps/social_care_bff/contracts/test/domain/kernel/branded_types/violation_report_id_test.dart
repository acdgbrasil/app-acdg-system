import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

/// Wave 0 TDD — shape of `ViolationReportId` as an `extension type`.
/// See `patient_id_test.dart` for the full rationale.
void main() {
  group('ViolationReportId (extension type)', () {
    const validUuid = '550e8400-e29b-41d4-a716-446655440000';
    const invalidUuid = 'not-a-uuid';

    test('create(valid) returns Success', () {
      final result = ViolationReportId.create(validUuid);
      expect(result, isA<Success<ViolationReportId>>());
      switch (result) {
        case Success(:final value):
          expect(value.value, equals(validUuid));
        case Failure():
          fail('Expected Success');
      }
    });

    test('create(invalid) returns Failure with AppError code VRI-001', () {
      final result = ViolationReportId.create(invalidUuid);
      expect(result, isA<Failure<ViolationReportId>>());
      switch (result) {
        case Success():
          fail('Expected Failure');
        case Failure(:final error):
          expect(error, isA<AppError>());
          expect((error as AppError).code, equals('VRI-001'));
      }
    });

    test('create(null) returns Failure', () {
      expect(ViolationReportId.create(null), isA<Failure<ViolationReportId>>());
    });

    test('create(empty) returns Failure', () {
      expect(ViolationReportId.create(''), isA<Failure<ViolationReportId>>());
    });

    test(
      'two ViolationReportId from same string are equal (value semantics)',
      () {
        final a = ViolationReportId.trusted(validUuid);
        final b = ViolationReportId.trusted(validUuid);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      },
    );

    test('toString returns the raw value', () {
      final id = ViolationReportId.trusted(validUuid);
      expect(id.toString(), equals(validUuid));
    });
  });
}
