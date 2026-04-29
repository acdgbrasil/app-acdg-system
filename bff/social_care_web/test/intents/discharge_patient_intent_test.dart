import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/discharge_patient_intent.dart';
import 'package:social_care_web/src/intents/uuid_validation.dart';

import '../_test_uuids.dart';

void main() {
  group('DischargePatientIntent', () {
    test('constructs with required patientId + request', () {
      const request = DischargePatientRequest(reason: 'Treatment completed');

      const intent = DischargePatientIntent(
        patientId: kPatientUuid,
        request: request,
      );

      expect(intent.patientId, equals(kPatientUuid));
      expect(intent.request, equals(request));
    });

    test('instances with equal fields are equal (Equatable)', () {
      const request = DischargePatientRequest(reason: 'Done');

      const a = DischargePatientIntent(
        patientId: kPatientUuid,
        request: request,
      );
      const b = DischargePatientIntent(
        patientId: kPatientUuid,
        request: request,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    group('parseFromBody — Result<DischargePatientIntent> (P2 if-case)', () {
      test('returns Success when reason is present', () {
        final result = DischargePatientIntent.parseFromBody(
          kPatientUuid,
          const {'reason': 'Treatment completed', 'notes': 'Follow-up OK'},
        );

        expect(result, isA<Success<DischargePatientIntent>>());
        switch (result) {
          case Success(:final value):
            expect(value.patientId, equals(kPatientUuid));
            expect(value.request.reason, equals('Treatment completed'));
            expect(value.request.notes, equals('Follow-up OK'));
          case Failure():
            fail('Expected Success');
        }
      });

      test('returns Success when notes is absent', () {
        final result = DischargePatientIntent.parseFromBody(
          kPatientUuid,
          const {'reason': 'Treatment completed'},
        );

        expect(result, isA<Success<DischargePatientIntent>>());
      });

      test('returns Failure when reason is missing', () {
        final result = DischargePatientIntent.parseFromBody(
          kPatientUuid,
          const {},
        );

        expect(result, isA<Failure<DischargePatientIntent>>());
      });

      test('returns Failure when reason is empty', () {
        final result = DischargePatientIntent.parseFromBody(
          kPatientUuid,
          const {'reason': ''},
        );

        expect(result, isA<Failure<DischargePatientIntent>>());
      });

      test(
        'returns Failure with UuidPathParamError when path id is not UUID v4',
        () {
          final result = DischargePatientIntent.parseFromBody(kNonUuid, const {
            'reason': 'Treatment completed',
          });

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
