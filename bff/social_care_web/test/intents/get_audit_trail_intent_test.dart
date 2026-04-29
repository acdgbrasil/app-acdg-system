import 'package:test/test.dart';

import 'package:social_care_web/src/intents/get_audit_trail_intent.dart';

/// Wave 0 RED contract for the new [GetAuditTrailIntent].
///
/// Query parameters are best-effort:
/// - `eventType` optional;
/// - `limit` and `offset` optional ints — non-numeric values silently
///   collapse to `null` (per A07 `ListPatientsIntent.parseFromQuery`
///   total-function canon).
/// Because everything is optional, the factory is a total function — it
/// returns the intent directly, never a `Result`. The only failure mode
/// is an empty `patientId` — pinned by the `_blankPatientIdCollapses` test
/// below: the intent still constructs (Wave 1 handler filters out the
/// empty-id request via a 400 upstream, not via a Failure here).
void main() {
  group('GetAuditTrailIntent', () {
    test('constructs with required patientId only', () {
      const intent = GetAuditTrailIntent(patientId: 'pat-1');

      expect(intent.patientId, equals('pat-1'));
      expect(intent.eventType, isNull);
      expect(intent.limit, isNull);
      expect(intent.offset, isNull);
    });

    test('constructs with all optional filters', () {
      const intent = GetAuditTrailIntent(
        patientId: 'pat-1',
        eventType: 'PATIENT_REGISTERED',
        limit: 50,
        offset: 10,
      );

      expect(intent.eventType, equals('PATIENT_REGISTERED'));
      expect(intent.limit, equals(50));
      expect(intent.offset, equals(10));
    });

    test('instances with equal fields are equal (Equatable)', () {
      const a = GetAuditTrailIntent(
        patientId: 'pat-1',
        eventType: 'E',
        limit: 10,
        offset: 0,
      );
      const b = GetAuditTrailIntent(
        patientId: 'pat-1',
        eventType: 'E',
        limit: 10,
        offset: 0,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances differ when any field differs', () {
      const a = GetAuditTrailIntent(patientId: 'pat-1', limit: 10);
      const b = GetAuditTrailIntent(patientId: 'pat-1', limit: 20);

      expect(a, isNot(equals(b)));
    });

    group('parseFromQuery — total factory', () {
      test('returns intent with all-null filters for empty query', () {
        final intent = GetAuditTrailIntent.parseFromQuery('pat-1', const {});

        expect(intent.patientId, equals('pat-1'));
        expect(intent.eventType, isNull);
        expect(intent.limit, isNull);
        expect(intent.offset, isNull);
      });

      test('forwards eventType when provided', () {
        final intent = GetAuditTrailIntent.parseFromQuery('pat-1', const {
          'eventType': 'PATIENT_REGISTERED',
        });

        expect(intent.eventType, equals('PATIENT_REGISTERED'));
      });

      test('parses limit + offset as ints when valid', () {
        final intent = GetAuditTrailIntent.parseFromQuery('pat-1', const {
          'limit': '25',
          'offset': '50',
        });

        expect(intent.limit, equals(25));
        expect(intent.offset, equals(50));
      });

      test('coerces empty/whitespace eventType to null', () {
        final intent = GetAuditTrailIntent.parseFromQuery('pat-1', const {
          'eventType': '  ',
        });

        expect(intent.eventType, isNull);
      });

      test('invalid limit (non-numeric) is coerced to null', () {
        final intent = GetAuditTrailIntent.parseFromQuery('pat-1', const {
          'limit': 'not-a-number',
        });

        expect(intent.limit, isNull);
      });

      test('invalid offset (non-numeric) is coerced to null', () {
        final intent = GetAuditTrailIntent.parseFromQuery('pat-1', const {
          'offset': 'abc',
        });

        expect(intent.offset, isNull);
      });

      test(
        'blank patientId collapses to empty string (handler decides 400)',
        () {
          final intent = GetAuditTrailIntent.parseFromQuery('', const {});

          expect(intent.patientId, equals(''));
        },
      );
    });
  });
}
