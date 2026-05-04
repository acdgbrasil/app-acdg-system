/// Shared helpers for every `acdg ...` subcommand that hits the BFF.
///
/// Originally `_patient_helpers.dart` (C03); renamed to `_command_helpers.dart`
/// in C04 because the same three helpers serve the family verbs verbatim and
/// will keep growing across `assessment`, `care`, `protection`, `team`, etc.
///
/// Two responsibilities:
///   1. Map error → exit code + stderr message in one place so every verb
///      agrees on the contract (`AuthRequiredError` ≠ `NetworkError` ≠
///      `ServerError`). [Result.error] is statically typed as `Object`, so
///      these helpers accept `Object` and narrow internally.
///   2. Drop `null` keys from a request body so optional fields are NOT
///      serialized when absent (DTO conventions: `{notes?}` means "omit the
///      key", not "send `notes: null`").
library;

import '../errors/cli_error.dart';

/// Exit-code matrix per W0 REPORT §2.4.
///
/// | Bucket                            | Code |
/// |-----------------------------------|-----:|
/// | AuthRequiredError                 | 2    |
/// | NetworkError                      | 3    |
/// | ServerError / generic 5xx + 4xx   | 1    |
/// | InvalidArgError (caller)          | 64   |
/// | Anything else (unexpected)        | 1    |
int exitCodeFor(Object error) {
  if (error is AuthRequiredError) return 2;
  if (error is RefreshTokenInvalidError) return 2;
  if (error is NetworkError) return 3;
  if (error is ServerError) return 1;
  if (error is InvalidArgError) return 64;
  return 1;
}

/// Renders a stderr-friendly message for [error]. Surfaces the HTTP status
/// for [ServerError] so the caller sees `409`, `422`, `500`, etc.
String stderrMessageFor(Object error) {
  if (error is AuthRequiredError) {
    return 'Authentication required. Run: acdg auth login';
  }
  if (error is RefreshTokenInvalidError) {
    return 'Authentication required (refresh token rotated). '
        'Run: acdg auth login';
  }
  if (error is NetworkError) {
    return 'Network error: ${error.message}';
  }
  if (error is ServerError) {
    return 'Server error (${error.statusCode}): ${error.message}';
  }
  if (error is InvalidArgError) {
    return 'Invalid argument: ${error.message}';
  }
  return 'Unexpected error: $error';
}

/// Returns a copy of [body] with all entries whose value is `null` dropped.
///
/// Used when assembling a POST body from CLI flags — optional flags surface
/// as `null` if the user did not pass them; we want them OMITTED from JSON
/// (matching the Dart `?` field convention used by every BFF request DTO).
Map<String, Object?> dropNulls(Map<String, Object?> body) => {
  for (final entry in body.entries)
    if (entry.value != null) entry.key: entry.value,
};
