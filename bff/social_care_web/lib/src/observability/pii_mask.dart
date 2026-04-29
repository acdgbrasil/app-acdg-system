/// Canonical PII masking helpers for BFF Web breadcrumbs.
///
/// These helpers are shared across every UseCase / handler that emits
/// breadcrumbs involving patient identifiers. They MUST:
///
/// - Never echo the raw value (full CPF, full CNS, full name, RG number).
/// - Preserve just enough shape for operators to correlate breadcrumbs when
///   triaging incidents (first/last digits or initials).
/// - Return `null` verbatim when input is `null` so callers can conditionally
///   include the field via spread:
///   `{ if (cpf != null) 'cpfMask': maskCpf(cpf) }`.
///
/// Shape canon (pinned by [test/observability/pii_mask_test.dart]):
///
/// | Field | Raw                  | Masked        |
/// | ----- | -------------------- | ------------- |
/// | CPF   | `11144477735`        | `111***35`    |
/// | Name  | `João Silva`         | `J***`        |
/// | CNS   | `123456789012345`    | `1234***2345` |
///
/// Rules:
/// - `null` passes through verbatim.
/// - Empty/short/whitespace-only input collapses to `'***'`.
/// - Helpers are TOTAL — they never throw for any input.
library;

/// "Present but redacted" marker used whenever the raw input is empty or too
/// short to carry a useful prefix/suffix without leaking the whole value.
const String _redacted = '***';

/// Masks a CPF-like identifier preserving the first 3 and last 2 digits.
///
/// Input with any format (digits only, with punctuation, alphanumeric) is
/// accepted — only the digit characters are considered for the prefix/suffix
/// so punctuation never surfaces in breadcrumb output.
String? maskCpf(String? raw) {
  if (raw == null) return null;
  final digits = _digitsOnly(raw);
  if (digits.length < 5) return _redacted;
  final prefix = digits.substring(0, 3);
  final suffix = digits.substring(digits.length - 2);
  return '$prefix$_redacted$suffix';
}

/// Masks a CNS-like identifier preserving the first 4 and last 4 digits.
///
/// CNS numbers are 15 digits in production; we keep more context than CPF
/// because operators often need to disambiguate between very similar IDs.
String? maskCns(String? raw) {
  if (raw == null) return null;
  final digits = _digitsOnly(raw);
  if (digits.length < 8) return _redacted;
  final prefix = digits.substring(0, 4);
  final suffix = digits.substring(digits.length - 4);
  return '$prefix$_redacted$suffix';
}

/// Masks a full name preserving only its first character.
///
/// Handles single and composite names equivalently — only the initial of the
/// first word survives; everything else collapses into [_redacted].
String? maskName(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return _redacted;
  final initial = trimmed[0];
  return '$initial$_redacted';
}

/// Extracts only ASCII digits from [input].
String _digitsOnly(String input) {
  final buf = StringBuffer();
  for (final codeUnit in input.codeUnits) {
    if (codeUnit >= 0x30 && codeUnit <= 0x39) {
      buf.writeCharCode(codeUnit);
    }
  }
  return buf.toString();
}
