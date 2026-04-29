import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/create_referral_intent.dart';
import 'package:social_care_web/src/intents/uuid_validation.dart';

import '../_test_uuids.dart';

/// Wave 0 RED contract for [CreateReferralIntent] — A12.
///
/// Canon (P2 if-case, 3 required — mirrors [UpdateIntakeInfoIntent] from A11):
/// - `referredPersonId`, `destinationService`, `reason` are REQUIRED
///   non-empty strings.
/// - `professionalId`, `date` are optional passthroughs.
/// - Missing/empty required fields produce a [Failure] whose message
///   enumerates the missing names (dynamic string — `_CreateReferralParseError`
///   is NOT const):
///   `"Invalid create-referral body: missing or empty [<names>]"`.
///
/// PII-safety:
/// - `reason` can carry sensitive narrative (case history). Parse errors
///   MUST NEVER echo the raw `reason` value back — only the field names
///   that are structurally missing.

Map<String, dynamic> _validBody() => {
  'referredPersonId': '660e8400-e29b-41d4-a716-446655440001',
  'destinationService': 'CRAS Vila Nova',
  'reason': 'Encaminhamento para acompanhamento psicossocial',
  'professionalId': 'prof-42',
  'date': '2026-04-17T10:00:00Z',
};

void main() {
  group('CreateReferralIntent', () {
    test('constructs with patientId + CreateReferralRequest payload', () {
      const request = CreateReferralRequest(
        referredPersonId: 'pers-1',
        destinationService: 'CRAS',
        reason: 'support',
      );

      const intent = CreateReferralIntent(patientId: kPatientUuid, request: request);

      expect(intent.patientId, equals(kPatientUuid));
      expect(intent.request, equals(request));
    });

    test('instances with equal payload are equal (Equatable)', () {
      const request = CreateReferralRequest(
        referredPersonId: 'pers-1',
        destinationService: 'CRAS',
        reason: 'support',
      );

      const a = CreateReferralIntent(patientId: kPatientUuid, request: request);
      const b = CreateReferralIntent(patientId: kPatientUuid, request: request);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different patientId are not equal', () {
      const request = CreateReferralRequest(
        referredPersonId: 'pers-1',
        destinationService: 'CRAS',
        reason: 'support',
      );

      const a = CreateReferralIntent(patientId: kPatientUuid, request: request);
      const b = CreateReferralIntent(patientId: kPatientUuidAlt, request: request);

      expect(a, isNot(equals(b)));
    });

    group('parseFromBody — Result<CreateReferralIntent> (P2 if-case)', () {
      test('returns Success when all required fields are present', () {
        final result = CreateReferralIntent.parseFromBody(
          kPatientUuid,
          _validBody(),
        );

        expect(result, isA<Success<CreateReferralIntent>>());
      });

      test('Success payload preserves patientId + required + optionals', () {
        final result = CreateReferralIntent.parseFromBody(
          kPatientUuid,
          _validBody(),
        );

        switch (result) {
          case Success(:final value):
            expect(value.patientId, equals(kPatientUuid));
            expect(
              value.request.referredPersonId,
              equals('660e8400-e29b-41d4-a716-446655440001'),
            );
            expect(value.request.destinationService, equals('CRAS Vila Nova'));
            expect(
              value.request.reason,
              equals('Encaminhamento para acompanhamento psicossocial'),
            );
            expect(value.request.professionalId, equals('prof-42'));
            expect(value.request.date, equals('2026-04-17T10:00:00Z'));
          case Failure():
            fail('Expected Success, got Failure');
        }
      });

      test('Success with required only — optionals null', () {
        final result = CreateReferralIntent.parseFromBody(kPatientUuid, const {
          'referredPersonId': 'pers-1',
          'destinationService': 'CRAS',
          'reason': 'support',
        });

        switch (result) {
          case Success(:final value):
            expect(value.request.referredPersonId, equals('pers-1'));
            expect(value.request.destinationService, equals('CRAS'));
            expect(value.request.reason, equals('support'));
            expect(value.request.professionalId, isNull);
            expect(value.request.date, isNull);
          case Failure():
            fail('Expected Success, got Failure');
        }
      });

      test('returns Failure when referredPersonId is missing', () {
        final body = _validBody()..remove('referredPersonId');

        final result = CreateReferralIntent.parseFromBody(kPatientUuid, body);

        expect(result, isA<Failure<CreateReferralIntent>>());
      });

      test('returns Failure when destinationService is missing', () {
        final body = _validBody()..remove('destinationService');

        final result = CreateReferralIntent.parseFromBody(kPatientUuid, body);

        expect(result, isA<Failure<CreateReferralIntent>>());
      });

      test('returns Failure when reason is missing', () {
        final body = _validBody()..remove('reason');

        final result = CreateReferralIntent.parseFromBody(kPatientUuid, body);

        expect(result, isA<Failure<CreateReferralIntent>>());
      });

      test('returns Failure when referredPersonId is empty string', () {
        final body = _validBody()..['referredPersonId'] = '';

        final result = CreateReferralIntent.parseFromBody(kPatientUuid, body);

        expect(result, isA<Failure<CreateReferralIntent>>());
      });

      test('returns Failure when destinationService is empty string', () {
        final body = _validBody()..['destinationService'] = '';

        final result = CreateReferralIntent.parseFromBody(kPatientUuid, body);

        expect(result, isA<Failure<CreateReferralIntent>>());
      });

      test('returns Failure when reason is empty string', () {
        final body = _validBody()..['reason'] = '';

        final result = CreateReferralIntent.parseFromBody(kPatientUuid, body);

        expect(result, isA<Failure<CreateReferralIntent>>());
      });

      test('returns Failure when body is empty', () {
        final result = CreateReferralIntent.parseFromBody(kPatientUuid, const {});

        expect(result, isA<Failure<CreateReferralIntent>>());
      });

      test(
        'Failure message enumerates ALL missing fields when body is empty',
        () {
          final result = CreateReferralIntent.parseFromBody(kPatientUuid, const {});

          switch (result) {
            case Success():
              fail('Expected Failure');
            case Failure(:final error):
              final msg = error.toString();
              expect(msg, contains('referredPersonId'));
              expect(msg, contains('destinationService'));
              expect(msg, contains('reason'));
              expect(msg, startsWith('Invalid create-referral body:'));
          }
        },
      );

      test('Failure message enumerates only missing (not present) fields', () {
        final result = CreateReferralIntent.parseFromBody(kPatientUuid, const {
          'referredPersonId': 'pers-1',
        });

        switch (result) {
          case Success():
            fail('Expected Failure');
          case Failure(:final error):
            final msg = error.toString();
            expect(msg, isNot(contains('referredPersonId')));
            expect(msg, contains('destinationService'));
            expect(msg, contains('reason'));
        }
      });

      test(
        'Failure message NEVER echoes raw reason content (PII — case history)',
        () {
          final body = {
            // missing destinationService — forces Failure
            'referredPersonId': 'pers-1',
            'reason': 'Mae relatou violencia fisica contra o filho de 8 anos',
          };

          final result = CreateReferralIntent.parseFromBody(kPatientUuid, body);

          switch (result) {
            case Success():
              fail('Expected Failure');
            case Failure(:final error):
              final dumped = error.toString();
              expect(
                dumped,
                isNot(contains('violencia fisica')),
                reason: 'Parse error must never echo raw reason',
              );
              expect(
                dumped,
                isNot(contains('8 anos')),
                reason: 'Parse error must never echo raw reason',
              );
              expect(
                dumped,
                isNot(contains('Mae')),
                reason: 'Parse error must never echo raw reason',
              );
          }
        },
      );

      test('Failure message NEVER echoes raw destinationService', () {
        final body = {
          // missing referredPersonId + reason — forces Failure
          'destinationService': 'UPA Jardim Catarina 24h',
        };

        final result = CreateReferralIntent.parseFromBody(kPatientUuid, body);

        switch (result) {
          case Success():
            fail('Expected Failure');
          case Failure(:final error):
            final dumped = error.toString();
            expect(dumped, isNot(contains('Jardim Catarina')));
            expect(dumped, isNot(contains('UPA')));
        }
      });
    });
  });
}
