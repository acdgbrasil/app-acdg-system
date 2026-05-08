import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/report_rights_violation_intent.dart';

import '../_test_uuids.dart';

/// Wave 0 RED contract for [ReportRightsViolationIntent] — A12.
///
/// Canon (P2 if-case, 3 required — mirrors [UpdateIntakeInfoIntent] from A11):
/// - `victimId`, `violationType`, `descriptionOfFact` are REQUIRED non-empty
///   strings.
/// - `violationTypeId`, `reportDate`, `incidentDate`, `actionsTaken` are
///   optional passthroughs.
/// - Missing/empty required fields produce a [Failure] whose message
///   enumerates the missing names (dynamic string — `_ReportRightsViolationParseError`
///   is NOT const):
///   `"Invalid report-violation body: missing or empty [<names>]"`.
///
/// PII-safety (CRITICAL — narrative against paciente, often a child):
/// - `descriptionOfFact` carries raw description of violation.
/// - `actionsTaken` carries raw intervention notes.
/// - Parse errors MUST NEVER echo either of these fields back — only the
///   structurally-missing field NAMES.

Map<String, dynamic> _validBody() => {
  'victimId': '660e8400-e29b-41d4-a716-446655440001',
  'violationType': 'PHYSICAL',
  'descriptionOfFact': 'Paciente apresentou hematomas no bracos em 14/04/2026',
  'violationTypeId': 'viol-phys',
  'reportDate': '2026-04-17T10:00:00Z',
  'incidentDate': '2026-04-14T00:00:00Z',
  'actionsTaken': 'Acionado Conselho Tutelar 8º distrito',
};

void main() {
  group('ReportRightsViolationIntent', () {
    test(
      'constructs with patientId + ReportRightsViolationRequest payload',
      () {
        const request = ReportRightsViolationRequest(
          victimId: 'vic-1',
          violationType: 'PHYSICAL',
          descriptionOfFact: 'fact',
        );

        const intent = ReportRightsViolationIntent(
          patientId: kPatientUuid,
          request: request,
        );

        expect(intent.patientId, equals(kPatientUuid));
        expect(intent.request, equals(request));
      },
    );

    test('instances with equal payload are equal (Equatable)', () {
      const request = ReportRightsViolationRequest(
        victimId: 'vic-1',
        violationType: 'PHYSICAL',
        descriptionOfFact: 'fact',
      );

      const a = ReportRightsViolationIntent(
        patientId: kPatientUuid,
        request: request,
      );
      const b = ReportRightsViolationIntent(
        patientId: kPatientUuid,
        request: request,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different patientId are not equal', () {
      const request = ReportRightsViolationRequest(
        victimId: 'vic-1',
        violationType: 'PHYSICAL',
        descriptionOfFact: 'fact',
      );

      const a = ReportRightsViolationIntent(
        patientId: kPatientUuid,
        request: request,
      );
      const b = ReportRightsViolationIntent(
        patientId: kPatientUuidAlt,
        request: request,
      );

      expect(a, isNot(equals(b)));
    });

    group('parseFromBody — Result<ReportRightsViolationIntent> (P2 if-case)', () {
      test('returns Success when all required fields are present', () {
        final result = ReportRightsViolationIntent.parseFromBody(
          kPatientUuid,
          _validBody(),
        );

        expect(result, isA<Success<ReportRightsViolationIntent>>());
      });

      test('Success payload preserves patientId + required + optionals', () {
        final result = ReportRightsViolationIntent.parseFromBody(
          kPatientUuid,
          _validBody(),
        );

        switch (result) {
          case Success(:final value):
            expect(value.patientId, equals(kPatientUuid));
            expect(
              value.request.victimId,
              equals('660e8400-e29b-41d4-a716-446655440001'),
            );
            expect(value.request.violationType, equals('PHYSICAL'));
            expect(
              value.request.descriptionOfFact,
              equals('Paciente apresentou hematomas no bracos em 14/04/2026'),
            );
            expect(value.request.violationTypeId, equals('viol-phys'));
            expect(value.request.reportDate, equals('2026-04-17T10:00:00Z'));
            expect(value.request.incidentDate, equals('2026-04-14T00:00:00Z'));
            expect(
              value.request.actionsTaken,
              equals('Acionado Conselho Tutelar 8º distrito'),
            );
          case Failure():
            fail('Expected Success, got Failure');
        }
      });

      test('Success with required only — optionals null', () {
        final result =
            ReportRightsViolationIntent.parseFromBody(kPatientUuid, const {
              'victimId': 'vic-1',
              'violationType': 'PHYSICAL',
              'descriptionOfFact': 'fact',
            });

        switch (result) {
          case Success(:final value):
            expect(value.request.victimId, equals('vic-1'));
            expect(value.request.violationType, equals('PHYSICAL'));
            expect(value.request.descriptionOfFact, equals('fact'));
            expect(value.request.violationTypeId, isNull);
            expect(value.request.reportDate, isNull);
            expect(value.request.incidentDate, isNull);
            expect(value.request.actionsTaken, isNull);
          case Failure():
            fail('Expected Success, got Failure');
        }
      });

      test('returns Failure when victimId is missing', () {
        final body = _validBody()..remove('victimId');

        final result = ReportRightsViolationIntent.parseFromBody(
          kPatientUuid,
          body,
        );

        expect(result, isA<Failure<ReportRightsViolationIntent>>());
      });

      test('returns Failure when violationType is missing', () {
        final body = _validBody()..remove('violationType');

        final result = ReportRightsViolationIntent.parseFromBody(
          kPatientUuid,
          body,
        );

        expect(result, isA<Failure<ReportRightsViolationIntent>>());
      });

      test('returns Failure when descriptionOfFact is missing', () {
        final body = _validBody()..remove('descriptionOfFact');

        final result = ReportRightsViolationIntent.parseFromBody(
          kPatientUuid,
          body,
        );

        expect(result, isA<Failure<ReportRightsViolationIntent>>());
      });

      test('returns Failure when victimId is empty string', () {
        final body = _validBody()..['victimId'] = '';

        final result = ReportRightsViolationIntent.parseFromBody(
          kPatientUuid,
          body,
        );

        expect(result, isA<Failure<ReportRightsViolationIntent>>());
      });

      test('returns Failure when descriptionOfFact is empty string', () {
        final body = _validBody()..['descriptionOfFact'] = '';

        final result = ReportRightsViolationIntent.parseFromBody(
          kPatientUuid,
          body,
        );

        expect(result, isA<Failure<ReportRightsViolationIntent>>());
      });

      test('returns Failure when body is empty', () {
        final result = ReportRightsViolationIntent.parseFromBody(
          kPatientUuid,
          const {},
        );

        expect(result, isA<Failure<ReportRightsViolationIntent>>());
      });

      test(
        'Failure message enumerates ALL missing fields when body is empty',
        () {
          final result = ReportRightsViolationIntent.parseFromBody(
            kPatientUuid,
            const {},
          );

          switch (result) {
            case Success():
              fail('Expected Failure');
            case Failure(:final error):
              final msg = error.toString();
              expect(msg, contains('victimId'));
              expect(msg, contains('violationType'));
              expect(msg, contains('descriptionOfFact'));
              expect(msg, startsWith('Invalid report-violation body:'));
          }
        },
      );

      test('Failure message enumerates only missing (not present) fields', () {
        final result = ReportRightsViolationIntent.parseFromBody(
          kPatientUuid,
          const {'victimId': 'vic-1'},
        );

        switch (result) {
          case Success():
            fail('Expected Failure');
          case Failure(:final error):
            final msg = error.toString();
            expect(msg, isNot(contains('victimId')));
            expect(msg, contains('violationType'));
            expect(msg, contains('descriptionOfFact'));
        }
      });

      test(
        'Failure message NEVER echoes raw descriptionOfFact (PII — violation narrative)',
        () {
          final body = {
            // missing victimId — forces Failure
            'violationType': 'PHYSICAL',
            'descriptionOfFact':
                'Paciente relatou agressao fisica pela mae em 14/04/2026',
          };

          final result = ReportRightsViolationIntent.parseFromBody(
            kPatientUuid,
            body,
          );

          switch (result) {
            case Success():
              fail('Expected Failure');
            case Failure(:final error):
              final dumped = error.toString();
              expect(
                dumped,
                isNot(contains('agressao fisica')),
                reason: 'Parse error must never echo descriptionOfFact',
              );
              expect(dumped, isNot(contains('mae')));
              expect(dumped, isNot(contains('14/04/2026')));
              expect(dumped, isNot(contains('relatou')));
          }
        },
      );

      test(
        'Failure message NEVER echoes raw actionsTaken (PII — intervention)',
        () {
          final body = {
            // missing victimId + descriptionOfFact — forces Failure
            'violationType': 'PHYSICAL',
            'actionsTaken': 'Acionado Conselho Tutelar 8º distrito',
          };

          final result = ReportRightsViolationIntent.parseFromBody(
            kPatientUuid,
            body,
          );

          switch (result) {
            case Success():
              fail('Expected Failure');
            case Failure(:final error):
              final dumped = error.toString();
              expect(
                dumped,
                isNot(contains('Conselho Tutelar')),
                reason: 'Parse error must never echo actionsTaken',
              );
              expect(dumped, isNot(contains('8º distrito')));
          }
        },
      );

      test(
        'Failure message NEVER echoes raw victimId (UUID but still PII-adjacent)',
        () {
          final body = {
            // missing violationType + descriptionOfFact
            'victimId': '11111111-2222-3333-4444-555555555555',
          };

          final result = ReportRightsViolationIntent.parseFromBody(
            kPatientUuid,
            body,
          );

          switch (result) {
            case Success():
              fail('Expected Failure');
            case Failure(:final error):
              final dumped = error.toString();
              expect(dumped, isNot(contains('11111111')));
          }
        },
      );
    });
  });
}
