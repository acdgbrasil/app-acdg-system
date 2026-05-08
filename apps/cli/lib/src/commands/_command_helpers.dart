/// Shared helpers for every `acdg ...` subcommand that hits the BFF.
///
/// Two responsibilities:
///   1. Drop `null` keys from a request body so optional fields are NOT
///      serialized when absent (DTO conventions: `{notes?}` means "omit the
///      key", not "send `notes: null`").
///   2. Decode the canonical `StandardResponse<IdData>` envelope.
library;

/// Returns a copy of [body] with all entries whose value is `null` dropped.
///
/// Used when assembling a POST body from CLI flags — optional flags surface
/// as `null` if the user did not pass them; we want them OMITTED from JSON
/// (matching the Dart `?` field convention used by every BFF request DTO).
Map<String, Object?> dropNulls(Map<String, Object?> body) => {
  for (final entry in body.entries)
    if (entry.value != null) entry.key: entry.value,
};

/// Reads `data.id` from the canonical `StandardResponse<IdData>` envelope:
/// `{"data": {"id": "<uuid>"}, "meta": {...}}`.
///
/// Returns `null` (defensively, NOT a throw) when the envelope shape is
/// unexpected — the caller's success path is then expected to degrade to
/// a generic `<resource> created` line so non-empty stdout is still
/// produced.
String? decodeStandardIdResponse(Object? data) {
  if (data is! Map<String, Object?>) return null;
  final inner = data['data'];
  if (inner is! Map<String, Object?>) return null;
  final id = inner['id'];
  return id is String ? id : null;
}
