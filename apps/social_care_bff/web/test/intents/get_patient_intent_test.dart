import 'package:core_contracts/core_contracts.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/get_patient_intent.dart';
import 'package:social_care_web/src/intents/uuid_validation.dart';

import '../_test_uuids.dart';

void main() {
  group('GetPatientIntent', () {
    test('constructs directly with a pre-validated patientId', () {
      const intent = GetPatientIntent(patientId: kPatientUuid);

      expect(intent.patientId, equals(kPatientUuid));
    });

    test('instances with equal patientId are equal (Equatable)', () {
      const a = GetPatientIntent(patientId: kPatientUuid);
      const b = GetPatientIntent(patientId: kPatientUuid);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different patientId are not equal', () {
      const a = GetPatientIntent(patientId: kPatientUuid);
      const b = GetPatientIntent(patientId: kPatientUuidAlt);

      expect(a, isNot(equals(b)));
    });

    group('parseFromPath', () {
      test('returns Success with normalized id for valid UUID v4', () {
        final result = GetPatientIntent.parseFromPath(kPatientUuid);

        switch (result) {
          case Success(:final value):
            expect(value.patientId, equals(kPatientUuid));
          case Failure():
            fail('Expected Success for canonical UUID v4');
        }
      });

      test('normalizes uppercase input to lowercase', () {
        final result = GetPatientIntent.parseFromPath(
          kPatientUuid.toUpperCase(),
        );

        switch (result) {
          case Success(:final value):
            expect(value.patientId, equals(kPatientUuid));
          case Failure():
            fail('Expected Success — uppercase should be normalized');
        }
      });

      test('returns Failure with UuidPathParamError for non-UUID input', () {
        final result = GetPatientIntent.parseFromPath(kNonUuid);

        switch (result) {
          case Success():
            fail('Expected Failure for non-UUID');
          case Failure(:final error):
            expect(error, isA<UuidPathParamError>());
            expect((error as UuidPathParamError).fieldName, equals('patientId'));
        }
      });

      test('returns Failure for empty string', () {
        final result = GetPatientIntent.parseFromPath('');

        expect(result, isA<Failure<GetPatientIntent>>());
      });

      test('returns Failure for UUID v1 (rejects non-v4 versions)', () {
        final result = GetPatientIntent.parseFromPath(kUuidV1);

        expect(result, isA<Failure<GetPatientIntent>>());
      });
    });
  });
}
