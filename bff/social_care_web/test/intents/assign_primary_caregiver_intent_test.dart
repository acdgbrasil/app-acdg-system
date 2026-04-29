import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/assign_primary_caregiver_intent.dart';

/// Wave 0 RED contract for the new [AssignPrimaryCaregiverIntent].
///
/// Body must carry a non-empty `memberPersonId`. Any other payload is
/// rejected with a [_AssignPrimaryCaregiverParseError] whose message is
/// purely structural (no value echo — even though `memberPersonId` is an
/// opaque UUID today, we still avoid echoing it to keep the error shape
/// uniform with the CPF-bearing intents).
Map<String, dynamic> _validBody() => {'memberPersonId': 'per-42'};

void main() {
  group('AssignPrimaryCaregiverIntent', () {
    test('constructs with patientId + request', () {
      const request = AssignPrimaryCaregiverRequest(memberPersonId: 'per-42');

      const intent = AssignPrimaryCaregiverIntent(
        patientId: 'pat-1',
        request: request,
      );

      expect(intent.patientId, equals('pat-1'));
      expect(intent.request, equals(request));
    });

    test('instances with equal payload are equal (Equatable)', () {
      const request = AssignPrimaryCaregiverRequest(memberPersonId: 'per-42');

      const a = AssignPrimaryCaregiverIntent(
        patientId: 'pat-1',
        request: request,
      );
      const b = AssignPrimaryCaregiverIntent(
        patientId: 'pat-1',
        request: request,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different payloads are not equal', () {
      const a = AssignPrimaryCaregiverIntent(
        patientId: 'pat-1',
        request: AssignPrimaryCaregiverRequest(memberPersonId: 'per-42'),
      );
      const b = AssignPrimaryCaregiverIntent(
        patientId: 'pat-1',
        request: AssignPrimaryCaregiverRequest(memberPersonId: 'per-99'),
      );

      expect(a, isNot(equals(b)));
    });

    group(
      'parseFromBody — Result<AssignPrimaryCaregiverIntent> (P2 if-case)',
      () {
        test('returns Success when memberPersonId is present', () {
          final result = AssignPrimaryCaregiverIntent.parseFromBody(
            'pat-1',
            _validBody(),
          );

          expect(result, isA<Success<AssignPrimaryCaregiverIntent>>());
        });

        test('Success payload preserves memberPersonId', () {
          final result = AssignPrimaryCaregiverIntent.parseFromBody(
            'pat-1',
            _validBody(),
          );

          switch (result) {
            case Success(:final value):
              expect(value.patientId, equals('pat-1'));
              expect(value.request.memberPersonId, equals('per-42'));
            case Failure():
              fail('Expected Success');
          }
        });

        test('returns Failure when memberPersonId is missing', () {
          final result = AssignPrimaryCaregiverIntent.parseFromBody(
            'pat-1',
            const {},
          );

          expect(result, isA<Failure<AssignPrimaryCaregiverIntent>>());
        });

        test('returns Failure when memberPersonId is empty', () {
          final result = AssignPrimaryCaregiverIntent.parseFromBody(
            'pat-1',
            const {'memberPersonId': ''},
          );

          expect(result, isA<Failure<AssignPrimaryCaregiverIntent>>());
        });

        test('returns Failure when patientId is empty', () {
          final result = AssignPrimaryCaregiverIntent.parseFromBody(
            '',
            _validBody(),
          );

          expect(result, isA<Failure<AssignPrimaryCaregiverIntent>>());
        });

        test('Failure message references structural field name', () {
          final result = AssignPrimaryCaregiverIntent.parseFromBody(
            'pat-1',
            const {},
          );

          switch (result) {
            case Success():
              fail('Expected Failure');
            case Failure(:final error):
              expect(error.toString(), contains('memberPersonId'));
          }
        });
      },
    );
  });
}
