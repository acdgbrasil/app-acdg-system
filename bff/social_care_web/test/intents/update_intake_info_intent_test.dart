import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/update_intake_info_intent.dart';

/// Representative happy-path body the APP sends to
/// `PUT /api/patients/<id>/intake`.
///
/// Wave 1 MUST keep [UpdateIntakeInfoIntent.parseFromBody] aligned with this
/// shape. Required: `ingressTypeId`, `serviceReason`. Optionals: `originName`,
/// `originContact`. `linkedSocialPrograms` defaults to empty list.
Map<String, dynamic> _validBody() => {
  'ingressTypeId': 'ing-spontaneous',
  'serviceReason': 'Procura por apoio psicossocial',
  'originName': 'Unidade Basica de Saude Vila Nova',
  'originContact': '(11) 4002-8922',
  'linkedSocialPrograms': <Map<String, dynamic>>[
    {'programId': 'prog-bolsa-familia', 'observation': 'Cadastrada 2025'},
  ],
};

void main() {
  group('UpdateIntakeInfoIntent', () {
    test('constructs with patientId + RegisterIntakeInfoRequest payload', () {
      const request = RegisterIntakeInfoRequest(
        ingressTypeId: 'ing-1',
        serviceReason: 'support',
      );

      const intent = UpdateIntakeInfoIntent(
        patientId: 'pat-1',
        request: request,
      );

      expect(intent.patientId, equals('pat-1'));
      expect(intent.request, equals(request));
    });

    test('instances with equal payload are equal (Equatable)', () {
      const request = RegisterIntakeInfoRequest(
        ingressTypeId: 'ing-1',
        serviceReason: 'support',
      );

      const a = UpdateIntakeInfoIntent(patientId: 'pat-1', request: request);
      const b = UpdateIntakeInfoIntent(patientId: 'pat-1', request: request);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different patientId are not equal', () {
      const request = RegisterIntakeInfoRequest(
        ingressTypeId: 'ing-1',
        serviceReason: 'support',
      );

      const a = UpdateIntakeInfoIntent(patientId: 'pat-1', request: request);
      const b = UpdateIntakeInfoIntent(patientId: 'pat-2', request: request);

      expect(a, isNot(equals(b)));
    });

    group('parseFromBody — Result<UpdateIntakeInfoIntent> (P2 if-case)', () {
      test('returns Success when required fields are present', () {
        final result = UpdateIntakeInfoIntent.parseFromBody(
          'pat-1',
          _validBody(),
        );

        expect(result, isA<Success<UpdateIntakeInfoIntent>>());
      });

      test(
        'Success payload preserves patientId + required + optionals + programs',
        () {
          final result = UpdateIntakeInfoIntent.parseFromBody(
            'pat-1',
            _validBody(),
          );

          switch (result) {
            case Success(:final value):
              expect(value.patientId, equals('pat-1'));
              expect(value.request.ingressTypeId, equals('ing-spontaneous'));
              expect(
                value.request.serviceReason,
                equals('Procura por apoio psicossocial'),
              );
              expect(
                value.request.originName,
                equals('Unidade Basica de Saude Vila Nova'),
              );
              expect(value.request.originContact, equals('(11) 4002-8922'));
              expect(value.request.linkedSocialPrograms, hasLength(1));
              expect(
                value.request.linkedSocialPrograms.first.programId,
                equals('prog-bolsa-familia'),
              );
              expect(
                value.request.linkedSocialPrograms.first.observation,
                equals('Cadastrada 2025'),
              );
            case Failure():
              fail('Expected Success, got Failure');
          }
        },
      );

      test(
        'Success with required only — optionals null + empty programs list',
        () {
          final result = UpdateIntakeInfoIntent.parseFromBody('pat-1', const {
            'ingressTypeId': 'ing-1',
            'serviceReason': 'support',
          });

          switch (result) {
            case Success(:final value):
              expect(value.request.ingressTypeId, equals('ing-1'));
              expect(value.request.serviceReason, equals('support'));
              expect(value.request.originName, isNull);
              expect(value.request.originContact, isNull);
              expect(value.request.linkedSocialPrograms, isEmpty);
            case Failure():
              fail('Expected Success, got Failure');
          }
        },
      );

      test('tolerates malformed linkedSocialPrograms (defaults to empty)', () {
        final body = _validBody()..['linkedSocialPrograms'] = 'not-a-list';

        final result = UpdateIntakeInfoIntent.parseFromBody('pat-1', body);

        switch (result) {
          case Success(:final value):
            expect(value.request.linkedSocialPrograms, isEmpty);
          case Failure():
            fail('Malformed programs must NOT fail the parse — treat as empty');
        }
      });

      test('returns Failure when ingressTypeId is missing', () {
        final body = _validBody()..remove('ingressTypeId');

        final result = UpdateIntakeInfoIntent.parseFromBody('pat-1', body);

        expect(result, isA<Failure<UpdateIntakeInfoIntent>>());
      });

      test('returns Failure when serviceReason is missing', () {
        final body = _validBody()..remove('serviceReason');

        final result = UpdateIntakeInfoIntent.parseFromBody('pat-1', body);

        expect(result, isA<Failure<UpdateIntakeInfoIntent>>());
      });

      test('returns Failure when ingressTypeId is empty string', () {
        final body = _validBody()..['ingressTypeId'] = '';

        final result = UpdateIntakeInfoIntent.parseFromBody('pat-1', body);

        expect(result, isA<Failure<UpdateIntakeInfoIntent>>());
      });

      test('returns Failure when serviceReason is empty string', () {
        final body = _validBody()..['serviceReason'] = '';

        final result = UpdateIntakeInfoIntent.parseFromBody('pat-1', body);

        expect(result, isA<Failure<UpdateIntakeInfoIntent>>());
      });

      test('returns Failure when body is empty', () {
        final result = UpdateIntakeInfoIntent.parseFromBody('pat-1', const {});

        expect(result, isA<Failure<UpdateIntakeInfoIntent>>());
      });

      test(
        'Failure message enumerates missing fields [ingressTypeId, serviceReason]',
        () {
          final result = UpdateIntakeInfoIntent.parseFromBody(
            'pat-1',
            const {},
          );

          switch (result) {
            case Success():
              fail('Expected Failure');
            case Failure(:final error):
              final msg = error.toString();
              expect(msg, contains('ingressTypeId'));
              expect(msg, contains('serviceReason'));
          }
        },
      );

      test(
        'Failure message does NOT echo originName / originContact (PII)',
        () {
          final body = {
            // missing ingressTypeId + serviceReason — forces Failure
            'originName': 'Hospital Regional Santa Casa',
            'originContact': '(11) 98765-4321',
          };

          final result = UpdateIntakeInfoIntent.parseFromBody('pat-1', body);

          switch (result) {
            case Success():
              fail('Expected Failure');
            case Failure(:final error):
              final dumped = error.toString();
              expect(
                dumped,
                isNot(contains('Santa Casa')),
                reason: 'Parse error must never echo raw originName',
              );
              expect(
                dumped,
                isNot(contains('98765-4321')),
                reason: 'Parse error must never echo raw originContact',
              );
          }
        },
      );

      test(
        'Failure message does NOT echo raw serviceReason (PII — case history)',
        () {
          final body = {
            // missing ingressTypeId — forces Failure
            'serviceReason': 'Internacao apos violencia domestica relatada',
          };

          final result = UpdateIntakeInfoIntent.parseFromBody('pat-1', body);

          switch (result) {
            case Success():
              fail('Expected Failure');
            case Failure(:final error):
              final dumped = error.toString();
              expect(
                dumped,
                isNot(contains('violencia domestica')),
                reason: 'Parse error must never echo raw serviceReason',
              );
          }
        },
      );
    });
  });
}
