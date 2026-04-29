import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/register_appointment_intent.dart';

/// Representative happy-path body the APP sends to
/// `POST /api/patients/<id>/appointments`.
///
/// Wave 1 MUST keep [RegisterAppointmentIntent.parseFromBody] aligned with
/// this shape. Required: `professionalId`. Optionals: `summary`, `actionPlan`,
/// `date`, `type`.
Map<String, dynamic> _validBody() => {
  'professionalId': 'prof-42',
  'summary': 'Primeira consulta multidisciplinar',
  'actionPlan': 'Encaminhar para neuropediatra',
  'date': '2026-04-17T10:00:00Z',
  'type': 'intake',
};

void main() {
  group('RegisterAppointmentIntent', () {
    test('constructs with patientId + RegisterAppointmentRequest payload', () {
      const request = RegisterAppointmentRequest(professionalId: 'prof-1');

      const intent = RegisterAppointmentIntent(
        patientId: 'pat-1',
        request: request,
      );

      expect(intent.patientId, equals('pat-1'));
      expect(intent.request, equals(request));
    });

    test('instances with equal payload are equal (Equatable)', () {
      const request = RegisterAppointmentRequest(professionalId: 'prof-1');

      const a = RegisterAppointmentIntent(patientId: 'pat-1', request: request);
      const b = RegisterAppointmentIntent(patientId: 'pat-1', request: request);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different patientId are not equal', () {
      const request = RegisterAppointmentRequest(professionalId: 'prof-1');

      const a = RegisterAppointmentIntent(patientId: 'pat-1', request: request);
      const b = RegisterAppointmentIntent(patientId: 'pat-2', request: request);

      expect(a, isNot(equals(b)));
    });

    test('instances with different request payload are not equal', () {
      const a = RegisterAppointmentIntent(
        patientId: 'pat-1',
        request: RegisterAppointmentRequest(professionalId: 'prof-1'),
      );
      const b = RegisterAppointmentIntent(
        patientId: 'pat-1',
        request: RegisterAppointmentRequest(professionalId: 'prof-2'),
      );

      expect(a, isNot(equals(b)));
    });

    group('parseFromBody — Result<RegisterAppointmentIntent> (P2 if-case)', () {
      test('returns Success when professionalId is present', () {
        final result = RegisterAppointmentIntent.parseFromBody(
          'pat-1',
          _validBody(),
        );

        expect(result, isA<Success<RegisterAppointmentIntent>>());
      });

      test(
        'Success payload preserves patientId + professionalId + optionals',
        () {
          final result = RegisterAppointmentIntent.parseFromBody(
            'pat-1',
            _validBody(),
          );

          switch (result) {
            case Success(:final value):
              expect(value.patientId, equals('pat-1'));
              expect(value.request.professionalId, equals('prof-42'));
              expect(
                value.request.summary,
                equals('Primeira consulta multidisciplinar'),
              );
              expect(
                value.request.actionPlan,
                equals('Encaminhar para neuropediatra'),
              );
              expect(value.request.date, equals('2026-04-17T10:00:00Z'));
              expect(value.request.type, equals('intake'));
            case Failure():
              fail('Expected Success, got Failure');
          }
        },
      );

      test('returns Success with null optionals when omitted', () {
        final result = RegisterAppointmentIntent.parseFromBody('pat-1', const {
          'professionalId': 'prof-42',
        });

        switch (result) {
          case Success(:final value):
            expect(value.request.professionalId, equals('prof-42'));
            expect(value.request.summary, isNull);
            expect(value.request.actionPlan, isNull);
            expect(value.request.date, isNull);
            expect(value.request.type, isNull);
          case Failure():
            fail('Expected Success, got Failure');
        }
      });

      test('returns Failure when professionalId is missing', () {
        final body = _validBody()..remove('professionalId');

        final result = RegisterAppointmentIntent.parseFromBody('pat-1', body);

        expect(result, isA<Failure<RegisterAppointmentIntent>>());
      });

      test('returns Failure when professionalId is empty string', () {
        final body = _validBody()..['professionalId'] = '';

        final result = RegisterAppointmentIntent.parseFromBody('pat-1', body);

        expect(result, isA<Failure<RegisterAppointmentIntent>>());
      });

      test('returns Failure when body is empty', () {
        final result = RegisterAppointmentIntent.parseFromBody(
          'pat-1',
          const {},
        );

        expect(result, isA<Failure<RegisterAppointmentIntent>>());
      });

      test('Failure message enumerates missing field [professionalId]', () {
        final result = RegisterAppointmentIntent.parseFromBody(
          'pat-1',
          const {},
        );

        switch (result) {
          case Success():
            fail('Expected Failure');
          case Failure(:final error):
            final msg = error.toString();
            expect(msg, contains('professionalId'));
        }
      });

      test(
        'Failure message does NOT echo raw summary content (PII — patient history)',
        () {
          final body = {
            // missing professionalId — forces Failure
            'summary': 'Paciente relata abuso familiar recorrente',
            'actionPlan': 'Acionar conselho tutelar',
          };

          final result = RegisterAppointmentIntent.parseFromBody('pat-1', body);

          switch (result) {
            case Success():
              fail('Expected Failure');
            case Failure(:final error):
              final dumped = error.toString();
              expect(
                dumped,
                isNot(contains('abuso familiar recorrente')),
                reason: 'Parse error must never echo raw summary content',
              );
              expect(
                dumped,
                isNot(contains('conselho tutelar')),
                reason: 'Parse error must never echo raw actionPlan content',
              );
          }
        },
      );
    });
  });
}
