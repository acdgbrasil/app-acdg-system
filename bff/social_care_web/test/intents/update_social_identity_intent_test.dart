import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/update_social_identity_intent.dart';

/// Wave 0 RED contract for the new [UpdateSocialIdentityIntent].
///
/// Body must carry a non-empty `typeId`. `description` is optional —
/// when absent or empty it collapses to `null` on the intent's request
/// payload (same rule the other A07 intents follow for optional fields).
Map<String, dynamic> _validBody() => {
  'typeId': 'social-id-type-lgbtqia',
  'description': 'Self-identifies as non-binary',
};

void main() {
  group('UpdateSocialIdentityIntent', () {
    test('constructs with patientId + request', () {
      const request = UpdateSocialIdentityRequest(
        typeId: 'type-1',
        description: 'Free-form',
      );

      const intent = UpdateSocialIdentityIntent(
        patientId: 'pat-1',
        request: request,
      );

      expect(intent.patientId, equals('pat-1'));
      expect(intent.request, equals(request));
    });

    test('instances with equal payload are equal (Equatable)', () {
      const request = UpdateSocialIdentityRequest(typeId: 'type-1');

      const a = UpdateSocialIdentityIntent(
        patientId: 'pat-1',
        request: request,
      );
      const b = UpdateSocialIdentityIntent(
        patientId: 'pat-1',
        request: request,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different payloads are not equal', () {
      const a = UpdateSocialIdentityIntent(
        patientId: 'pat-1',
        request: UpdateSocialIdentityRequest(typeId: 'type-1'),
      );
      const b = UpdateSocialIdentityIntent(
        patientId: 'pat-1',
        request: UpdateSocialIdentityRequest(typeId: 'type-2'),
      );

      expect(a, isNot(equals(b)));
    });

    group(
      'parseFromBody — Result<UpdateSocialIdentityIntent> (P2 if-case)',
      () {
        test('returns Success when typeId is present', () {
          final result = UpdateSocialIdentityIntent.parseFromBody(
            'pat-1',
            _validBody(),
          );

          expect(result, isA<Success<UpdateSocialIdentityIntent>>());
        });

        test('Success payload preserves typeId and description', () {
          final result = UpdateSocialIdentityIntent.parseFromBody(
            'pat-1',
            _validBody(),
          );

          switch (result) {
            case Success(:final value):
              expect(value.patientId, equals('pat-1'));
              expect(value.request.typeId, equals('social-id-type-lgbtqia'));
              expect(
                value.request.description,
                equals('Self-identifies as non-binary'),
              );
            case Failure():
              fail('Expected Success');
          }
        });

        test('Success preserves typeId when description is absent', () {
          final result = UpdateSocialIdentityIntent.parseFromBody(
            'pat-1',
            const {'typeId': 'type-only'},
          );

          switch (result) {
            case Success(:final value):
              expect(value.request.typeId, equals('type-only'));
              expect(value.request.description, isNull);
            case Failure():
              fail('Expected Success');
          }
        });

        test('returns Failure when typeId is missing', () {
          final result = UpdateSocialIdentityIntent.parseFromBody(
            'pat-1',
            const {},
          );

          expect(result, isA<Failure<UpdateSocialIdentityIntent>>());
        });

        test('returns Failure when typeId is empty', () {
          final result = UpdateSocialIdentityIntent.parseFromBody(
            'pat-1',
            const {'typeId': ''},
          );

          expect(result, isA<Failure<UpdateSocialIdentityIntent>>());
        });

        test('returns Failure when patientId is empty', () {
          final result = UpdateSocialIdentityIntent.parseFromBody(
            '',
            _validBody(),
          );

          expect(result, isA<Failure<UpdateSocialIdentityIntent>>());
        });

        test('Failure message references structural field name', () {
          final result = UpdateSocialIdentityIntent.parseFromBody(
            'pat-1',
            const {},
          );

          switch (result) {
            case Success():
              fail('Expected Failure');
            case Failure(:final error):
              expect(error.toString(), contains('typeId'));
          }
        });
      },
    );
  });
}
