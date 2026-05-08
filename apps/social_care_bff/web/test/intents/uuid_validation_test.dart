import 'package:core_contracts/core_contracts.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/uuid_validation.dart';

/// Wave 0 RED contract for [validateUuidPathParam] — A23.
///
/// Pinned invariants:
/// - Accepts canonical RFC 4122 v4 UUIDs only (36 chars, hyphenated,
///   version nibble = `4`, variant nibble = `[89ab]`).
/// - Rejects v1, v3, v5, NIL UUID, Microsoft Guid braces, URN form.
/// - Normalizes input via trim → lowercase before validating, matching
///   social-care Swift backend (`PersonId.swift:38`).
/// - On [Failure], the [UuidPathParamError] message MUST NOT echo the
///   raw input value — only the [fieldName]. Path params can carry
///   malformed PII (CPF, email) from clients misusing the route.
///
/// Cross-checked against:
/// - `social-care/Sources/.../Domain/Kernel/PersonId.swift:38`
/// - `people-context/src/routes/people.ts:10`
void main() {
  group('validateUuidPathParam', () {
    // Canonical UUID v4 fixtures (lowercase, RFC 4122-compliant)
    const validV4 = 'a1b2c3d4-e5f6-4789-a012-3456789abcde';

    group('Success — accepts canonical UUID v4', () {
      test('returns Success(value) when input is a valid lowercase v4', () {
        final result = validateUuidPathParam(validV4, fieldName: 'patientId');

        switch (result) {
          case Success(:final value):
            expect(value, equals(validV4));
          case Failure():
            fail('Expected Success for canonical UUID v4');
        }
      });

      test('normalizes uppercase input to lowercase', () {
        final result = validateUuidPathParam(
          validV4.toUpperCase(),
          fieldName: 'patientId',
        );

        switch (result) {
          case Success(:final value):
            expect(value, equals(validV4));
          case Failure():
            fail('Expected Success — uppercase should be normalized');
        }
      });

      test('normalizes mixed-case input to lowercase', () {
        final result = validateUuidPathParam(
          'A1B2C3D4-e5f6-4789-A012-3456789ABCDE',
          fieldName: 'patientId',
        );

        switch (result) {
          case Success(:final value):
            expect(value, equals(validV4));
          case Failure():
            fail('Expected Success — mixed case should be normalized');
        }
      });

      test('trims surrounding whitespace before validating', () {
        final result = validateUuidPathParam(
          '  $validV4  ',
          fieldName: 'patientId',
        );

        switch (result) {
          case Success(:final value):
            expect(value, equals(validV4));
          case Failure():
            fail('Expected Success — whitespace should be trimmed');
        }
      });

      test('accepts variant nibble values 8, 9, a, b', () {
        for (final variant in ['8', '9', 'a', 'b']) {
          final candidate = 'a1b2c3d4-e5f6-4789-${variant}012-3456789abcde';
          final result = validateUuidPathParam(
            candidate,
            fieldName: 'patientId',
          );
          expect(
            result,
            isA<Success<String>>(),
            reason: 'variant nibble "$variant" must be accepted',
          );
        }
      });
    });

    group('Failure — rejects non-canonical input', () {
      test('rejects empty string', () {
        final result = validateUuidPathParam('', fieldName: 'patientId');

        expect(result, isA<Failure<String>>());
      });

      test('rejects whitespace-only string', () {
        final result = validateUuidPathParam('   ', fieldName: 'patientId');

        expect(result, isA<Failure<String>>());
      });

      test('rejects non-UUID literal like "people" (the bleed case)', () {
        // This is the literal scenario that triggered A23 — a legacy
        // URL `/team/people` was being routed to GetTeamMember(id='people').
        final result = validateUuidPathParam('people', fieldName: 'memberId');

        expect(result, isA<Failure<String>>());
      });

      test('rejects UUID v1 (timestamp-based)', () {
        // version nibble = 1
        const v1 = 'a1b2c3d4-e5f6-1789-a012-3456789abcde';
        final result = validateUuidPathParam(v1, fieldName: 'patientId');

        expect(result, isA<Failure<String>>());
      });

      test('rejects UUID v3 (md5)', () {
        const v3 = 'a1b2c3d4-e5f6-3789-a012-3456789abcde';
        final result = validateUuidPathParam(v3, fieldName: 'patientId');

        expect(result, isA<Failure<String>>());
      });

      test('rejects UUID v5 (sha1)', () {
        const v5 = 'a1b2c3d4-e5f6-5789-a012-3456789abcde';
        final result = validateUuidPathParam(v5, fieldName: 'patientId');

        expect(result, isA<Failure<String>>());
      });

      test('rejects NIL UUID (all zeros)', () {
        const nil = '00000000-0000-0000-0000-000000000000';
        final result = validateUuidPathParam(nil, fieldName: 'patientId');

        expect(result, isA<Failure<String>>());
      });

      test('rejects invalid variant nibble (c, d, e, f)', () {
        for (final invalid in ['c', 'd', 'e', 'f']) {
          final candidate = 'a1b2c3d4-e5f6-4789-${invalid}012-3456789abcde';
          final result = validateUuidPathParam(
            candidate,
            fieldName: 'patientId',
          );
          expect(
            result,
            isA<Failure<String>>(),
            reason: 'variant nibble "$invalid" must be rejected',
          );
        }
      });

      test('rejects Microsoft Guid braces format', () {
        const guid = '{a1b2c3d4-e5f6-4789-a012-3456789abcde}';
        final result = validateUuidPathParam(guid, fieldName: 'patientId');

        expect(result, isA<Failure<String>>());
      });

      test('rejects URN form (urn:uuid:...)', () {
        const urn = 'urn:uuid:a1b2c3d4-e5f6-4789-a012-3456789abcde';
        final result = validateUuidPathParam(urn, fieldName: 'patientId');

        expect(result, isA<Failure<String>>());
      });

      test('rejects UUID without hyphens (32-char raw)', () {
        const raw = 'a1b2c3d4e5f64789a0123456789abcde';
        final result = validateUuidPathParam(raw, fieldName: 'patientId');

        expect(result, isA<Failure<String>>());
      });

      test('rejects UUID with too few characters', () {
        const short = 'a1b2c3d4-e5f6-4789-a012-3456789abc';
        final result = validateUuidPathParam(short, fieldName: 'patientId');

        expect(result, isA<Failure<String>>());
      });

      test('rejects UUID with too many characters', () {
        const long = 'a1b2c3d4-e5f6-4789-a012-3456789abcdef';
        final result = validateUuidPathParam(long, fieldName: 'patientId');

        expect(result, isA<Failure<String>>());
      });

      test('rejects non-hex characters (g-z)', () {
        const bad = 'g1b2c3d4-e5f6-4789-a012-3456789abcde';
        final result = validateUuidPathParam(bad, fieldName: 'patientId');

        expect(result, isA<Failure<String>>());
      });

      test('rejects path traversal attempts', () {
        for (final attack in ['../patient', '/etc/passwd', '..\\..\\']) {
          final result = validateUuidPathParam(attack, fieldName: 'patientId');
          expect(
            result,
            isA<Failure<String>>(),
            reason: 'path traversal "$attack" must be rejected',
          );
        }
      });
    });

    group('PII safety — Failure NEVER echoes raw value', () {
      test('error message mentions fieldName but not raw value', () {
        final result = validateUuidPathParam(
          'sensitive-cpf-12345678901',
          fieldName: 'patientId',
        );

        switch (result) {
          case Success():
            fail('Expected Failure');
          case Failure(:final error):
            final msg = error.toString();
            expect(msg, contains('patientId'));
            expect(msg, isNot(contains('sensitive-cpf-12345678901')));
            expect(msg, isNot(contains('12345678901')));
        }
      });

      test(
        'error message NEVER echoes a malformed email passed as path param',
        () {
          final result = validateUuidPathParam(
            'attacker@evil.com',
            fieldName: 'memberId',
          );

          switch (result) {
            case Success():
              fail('Expected Failure');
            case Failure(:final error):
              final msg = error.toString();
              expect(msg, isNot(contains('attacker')));
              expect(msg, isNot(contains('evil.com')));
              expect(msg, isNot(contains('@')));
          }
        },
      );

      test('error message uses different fieldName per call', () {
        final r1 = validateUuidPathParam('bad', fieldName: 'patientId');
        final r2 = validateUuidPathParam('bad', fieldName: 'roleId');

        final m1 = (r1 as Failure<String>).error.toString();
        final m2 = (r2 as Failure<String>).error.toString();

        expect(m1, contains('patientId'));
        expect(m2, contains('roleId'));
        expect(m1, isNot(contains('roleId')));
        expect(m2, isNot(contains('patientId')));
      });
    });
  });

  group('UuidPathParamError', () {
    test('exposes fieldName as a public field', () {
      const error = UuidPathParamError(fieldName: 'patientId');

      expect(error.fieldName, equals('patientId'));
    });

    test('two errors with the same fieldName are equal (Equatable)', () {
      const a = UuidPathParamError(fieldName: 'patientId');
      const b = UuidPathParamError(fieldName: 'patientId');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('two errors with different fieldName are NOT equal', () {
      const a = UuidPathParamError(fieldName: 'patientId');
      const b = UuidPathParamError(fieldName: 'memberId');

      expect(a, isNot(equals(b)));
    });

    test('implements Exception (interop with BackendError handlers)', () {
      const error = UuidPathParamError(fieldName: 'patientId');

      expect(error, isA<Exception>());
    });

    test('toString includes the fieldName', () {
      const error = UuidPathParamError(fieldName: 'patientId');

      expect(error.toString(), contains('patientId'));
    });
  });
}
