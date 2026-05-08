import 'package:core_contracts/core_contracts.dart';

/// Strict RFC 4122 v4 UUID matcher.
///
/// Requires:
/// - 36 chars total, lowercase hex
/// - 5 hyphen-delimited groups: 8-4-4-4-12
/// - **Version nibble** = `4` (third group, first char)
/// - **Variant nibble** = `8` / `9` / `a` / `b` (fourth group, first char)
///
/// Matches the regex used by `people-context/src/routes/people.ts:10`,
/// further restricted to the v4 version + variant nibbles to reject
/// v1, v3, v5, NIL, and Microsoft Guid braces. Aligned with how
/// social-care Swift normalizes (`PersonId.swift:38`): trim → lowercase
/// → strict UUID parser.
final RegExp _uuidV4Re = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

/// Validates that [raw] is a canonical UUID v4 path parameter.
///
/// Trims surrounding whitespace and lowercases [raw] before validating —
/// matching the social-care backend normalization. The returned
/// [Success] value is the normalized form (lowercase, no surrounding
/// whitespace), suitable for direct propagation upstream.
///
/// On [Failure], the [UuidPathParamError] message echoes ONLY the
/// [fieldName] — never the raw input. Path parameters can carry
/// malformed PII (CPF, email, addresses) when clients misuse the route,
/// so PII discipline is enforced at the boundary.
///
/// This function is the single canonical entry point for UUID path-param
/// validation across the BFF Web canon (A07-A15+). Handlers MUST call
/// this before dispatching to the upstream contract; the contract MUST
/// only ever see a normalized UUID v4.
Result<String> validateUuidPathParam(String raw, {required String fieldName}) {
  final normalized = raw.trim().toLowerCase();
  if (_uuidV4Re.hasMatch(normalized)) return Success(normalized);
  return Failure(UuidPathParamError(fieldName: fieldName));
}

/// PII-safe error for path-parameter UUID validation.
///
/// Carries only the [fieldName] of the rejected parameter — never the
/// raw input value. This keeps the error usable in 400 responses and
/// observability breadcrumbs without leaking what the client sent
/// (which may be malformed PII attempted as a path segment).
final class UuidPathParamError with Equatable implements Exception {
  const UuidPathParamError({required this.fieldName});

  final String fieldName;

  @override
  List<Object?> get props => [fieldName];

  @override
  String toString() => 'Invalid path parameter [$fieldName]: must be a UUID v4';
}
