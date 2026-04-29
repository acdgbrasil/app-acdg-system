import 'package:test/test.dart';

import 'package:social_care_web/src/observability/pii_mask.dart';

/// Canonical PII masking helpers — A08 Wave 0.
///
/// These helpers are shared across every UseCase / handler that emits
/// breadcrumbs involving patient identifiers. They MUST:
///
/// - Never echo the raw value (full CPF, full CNS, full name, RG number).
/// - Preserve just enough shape for operators to correlate breadcrumbs when
///   triaging incidents (first/last digits or initials).
/// - Return `null` verbatim when input is `null` so callers can conditionally
///   include the field via spread: `{ if (cpf != null) 'cpfMask': maskCpf(cpf) }`.
///
/// Shape canon (Wave 1 MUST match exactly — tests pin this down):
///
/// | Field | Raw                         | Masked        |
/// | ----- | --------------------------- | ------------- |
/// | CPF   | `11144477735`               | `111***35`    |
/// | Name  | `João Silva`                | `J***`        |
/// | CNS   | `123456789012345`           | `1234***2345` |
void main() {
  group('maskCpf', () {
    test('masks an 11-digit CPF keeping first 3 and last 2 digits', () {
      expect(maskCpf('11144477735'), equals('111***35'));
    });

    test('returns null when input is null', () {
      expect(maskCpf(null), isNull);
    });

    test('returns *** when input is an empty string', () {
      // Empty input MUST NOT round-trip through as-is; otherwise a bug that
      // silently logs "" would slip by. Masking to '***' is the canonical
      // "present-but-redacted" marker.
      expect(maskCpf(''), equals('***'));
    });

    test('fully masks a short input (< 5 chars)', () {
      expect(maskCpf('123'), equals('***'));
    });

    test('masked value never contains the full raw CPF', () {
      const raw = '52998224725';

      final masked = maskCpf(raw);

      expect(masked, isNotNull);
      expect(masked, isNot(equals(raw)));
      expect(masked, isNot(contains('5299822')));
    });

    test('accepts CPF with punctuation and masks only digits shape', () {
      // Canonical input is digits-only, but defensively we still must not
      // echo the original punctuated form.
      final masked = maskCpf('111.444.777-35');

      expect(masked, isNotNull);
      expect(masked, isNot(contains('111.444.777-35')));
    });
  });

  group('maskName', () {
    test('keeps the first character of a single name', () {
      expect(maskName('João'), equals('J***'));
    });

    test('keeps the first character of a composite name', () {
      expect(maskName('João Silva'), equals('J***'));
    });

    test('returns null when input is null', () {
      expect(maskName(null), isNull);
    });

    test('returns *** when input is empty or whitespace-only', () {
      expect(maskName(''), equals('***'));
      expect(maskName('   '), equals('***'));
    });

    test('masked value never contains the raw full name', () {
      const raw = 'Maria da Silva Santos';

      final masked = maskName(raw);

      expect(masked, isNotNull);
      expect(masked, isNot(contains('Silva')));
      expect(masked, isNot(contains('Santos')));
      expect(masked, isNot(contains('Maria')));
    });
  });

  group('maskCns', () {
    test('masks a 15-digit CNS keeping first 4 and last 4 digits', () {
      expect(maskCns('123456789012345'), equals('1234***2345'));
    });

    test('returns null when input is null', () {
      expect(maskCns(null), isNull);
    });

    test('returns *** when input is an empty string', () {
      expect(maskCns(''), equals('***'));
    });

    test('fully masks a short input (< 8 chars)', () {
      expect(maskCns('123'), equals('***'));
    });

    test('masked value never contains the full raw CNS', () {
      const raw = '898000123456789';

      final masked = maskCns(raw);

      expect(masked, isNotNull);
      expect(masked, isNot(equals(raw)));
      expect(masked, isNot(contains('89800012345')));
    });
  });

  group('PII helpers are total (no throws)', () {
    test('maskCpf never throws on any input', () {
      expect(() => maskCpf('1'), returnsNormally);
      expect(() => maskCpf(''), returnsNormally);
      expect(() => maskCpf(null), returnsNormally);
      expect(() => maskCpf('not-a-number'), returnsNormally);
    });

    test('maskName never throws on any input', () {
      expect(() => maskName('1'), returnsNormally);
      expect(() => maskName(''), returnsNormally);
      expect(() => maskName(null), returnsNormally);
    });

    test('maskCns never throws on any input', () {
      expect(() => maskCns('1'), returnsNormally);
      expect(() => maskCns(''), returnsNormally);
      expect(() => maskCns(null), returnsNormally);
    });
  });
}
