import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/withdraw_patient_intent.dart';
import 'package:social_care_web/src/intents/uuid_validation.dart';

import '../_test_uuids.dart';

void main() {
  group('WithdrawPatientIntent', () {
    test('constructs with required patientId + request', () {
      const request = WithdrawPatientRequest(reason: 'Family relocated');

      const intent = WithdrawPatientIntent(
        patientId: kPatientUuid,
        request: request,
      );

      expect(intent.patientId, equals(kPatientUuid));
      expect(intent.request, equals(request));
    });

    test('instances with equal fields are equal (Equatable)', () {
      const request = WithdrawPatientRequest(reason: 'R');

      const a = WithdrawPatientIntent(
        patientId: kPatientUuid,
        request: request,
      );
      const b = WithdrawPatientIntent(
        patientId: kPatientUuid,
        request: request,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    group('parseFromBody — Result<WithdrawPatientIntent> (P2 if-case)', () {
      test('returns Success when reason is present', () {
        final result = WithdrawPatientIntent.parseFromBody(
          kPatientUuid,
          const {'reason': 'Family relocated', 'notes': 'Moved to RJ'},
        );

        expect(result, isA<Success<WithdrawPatientIntent>>());
        switch (result) {
          case Success(:final value):
            expect(value.patientId, equals(kPatientUuid));
            expect(value.request.reason, equals('Family relocated'));
            expect(value.request.notes, equals('Moved to RJ'));
          case Failure():
            fail('Expected Success');
        }
      });

      test('returns Failure when reason is missing', () {
        final result = WithdrawPatientIntent.parseFromBody(
          kPatientUuid,
          const {},
        );

        expect(result, isA<Failure<WithdrawPatientIntent>>());
      });

      test('returns Failure when reason is empty', () {
        final result = WithdrawPatientIntent.parseFromBody(
          kPatientUuid,
          const {'reason': ''},
        );

        expect(result, isA<Failure<WithdrawPatientIntent>>());
      });

      test(
        'returns Failure with UuidPathParamError when path id is not UUID v4',
        () {
          final result = WithdrawPatientIntent.parseFromBody(kNonUuid, const {
            'reason': 'Family relocated',
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
