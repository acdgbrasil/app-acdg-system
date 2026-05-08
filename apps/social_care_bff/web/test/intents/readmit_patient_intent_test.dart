import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/readmit_patient_intent.dart';
import 'package:social_care_web/src/intents/uuid_validation.dart';

import '../_test_uuids.dart';

void main() {
  group('ReadmitPatientIntent', () {
    test('constructs with required patientId + request', () {
      const request = ReadmitPatientRequest(notes: 'Returned for follow-up');

      const intent = ReadmitPatientIntent(
        patientId: kPatientUuid,
        request: request,
      );

      expect(intent.patientId, equals(kPatientUuid));
      expect(intent.request, equals(request));
    });

    test('instances with equal fields are equal (Equatable)', () {
      const request = ReadmitPatientRequest();

      const a = ReadmitPatientIntent(patientId: kPatientUuid, request: request);
      const b = ReadmitPatientIntent(patientId: kPatientUuid, request: request);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    group('parseFromBody — Result<ReadmitPatientIntent> (P2 if-case)', () {
      test('returns Success with empty body (notes is optional)', () {
        final result = ReadmitPatientIntent.parseFromBody(
          kPatientUuid,
          const {},
        );

        expect(result, isA<Success<ReadmitPatientIntent>>());
        switch (result) {
          case Success(:final value):
            expect(value.patientId, equals(kPatientUuid));
            expect(value.request.notes, isNull);
          case Failure():
            fail('Expected Success');
        }
      });

      test('returns Success with notes when provided', () {
        final result = ReadmitPatientIntent.parseFromBody(kPatientUuid, const {
          'notes': 'Returned for follow-up',
        });

        expect(result, isA<Success<ReadmitPatientIntent>>());
        switch (result) {
          case Success(:final value):
            expect(value.request.notes, equals('Returned for follow-up'));
          case Failure():
            fail('Expected Success');
        }
      });

      test(
        'returns Failure when patientId is empty (UUID gate rejects it)',
        () {
          final result = ReadmitPatientIntent.parseFromBody('', const {});

          switch (result) {
            case Success():
              fail('Expected Failure for empty path id');
            case Failure(:final error):
              expect(error, isA<UuidPathParamError>());
          }
        },
      );

      test(
        'returns Failure with UuidPathParamError when path id is not UUID v4',
        () {
          final result = ReadmitPatientIntent.parseFromBody(kNonUuid, const {});

          switch (result) {
            case Success():
              fail('Expected Failure for non-UUID path id');
            case Failure(:final error):
              expect(error, isA<UuidPathParamError>());
              expect(
                (error as UuidPathParamError).fieldName,
                equals('patientId'),
              );
              expect(error.toString(), isNot(contains(kNonUuid)));
          }
        },
      );
    });
  });
}
