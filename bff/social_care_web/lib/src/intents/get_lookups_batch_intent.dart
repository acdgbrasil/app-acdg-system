import 'package:core_contracts/core_contracts.dart';

/// Intent for `GET /lookups?tables=a,b,c` — fetch multiple lookup tables in a
/// single round trip. Eliminates the client-side `Future.wait([...])` that
/// the Flutter `PatientRegistrationViewModel` performs today.
///
/// **First "query-only" intent in the BFF Web canon.** Where path-only intents
/// (e.g. [GetLookupTableIntent]) get their data from shelf route params and
/// P2 intents get their data from a JSON body, this intent gets it from the
/// query string. The factory mirrors `parseFromBody` in shape — same
/// `Result<T>` return, same naming, same private `_*ParseError` PII-safe
/// envelope — but consumes a `Map<String, String>` taken from
/// `request.url.queryParameters`.
///
/// Parsing rules (all enforced by [parseFromQuery]):
/// 1. **Tolerant CSV split**: `tables=a,,b,` → `[a, b]`. Whitespace around
///    each token is trimmed and empty tokens are dropped. This matches the
///    project-wide CSV convention (`people-context/src/config/env.ts:31-34`).
/// 2. **Failure on absent / empty / blank input**: missing `tables` param,
///    `tables=`, `tables=   ` and `tables=,,,` all return [Failure].
/// 3. **Hard cap of [maxTables] = 20** distinct entries, sized at ~54%
///    headroom over the 13 entries currently in `AllowedLookupTables.swift`.
///    Anything above the cap is a client bug (and a DoS vector if left
///    uncapped), so the parser fails closed.
final class GetLookupsBatchIntent with Equatable {
  const GetLookupsBatchIntent({required this.tables});

  /// Maximum number of tables a single batch request may name.
  ///
  /// Sized for the realistic universe of `dominio_*` tables (13 today)
  /// with ~54% headroom. Beyond this is treated as a client bug.
  static const int maxTables = 20;

  final List<String> tables;

  @override
  List<Object?> get props => [tables];

  /// Parses the shelf [Request.url.queryParameters] map into an intent.
  ///
  /// Returns [Success] when at least one non-blank table name remains
  /// after trimming and filtering, and the count is `<= ` [maxTables].
  /// Otherwise returns [Failure] with a [_GetLookupsBatchParseError] whose
  /// message is PII-safe (no values from the request are echoed back).
  static Result<GetLookupsBatchIntent> parseFromQuery(
    Map<String, String> queryParameters,
  ) {
    final raw = queryParameters['tables'];
    if (raw == null) {
      return Failure(
        const _GetLookupsBatchParseError(
          'Invalid lookups-batch query: missing required parameter [tables]',
        ),
      );
    }

    final tokens = raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);

    if (tokens.isEmpty) {
      return Failure(
        const _GetLookupsBatchParseError(
          'Invalid lookups-batch query: [tables] must contain at least one '
          'non-blank value',
        ),
      );
    }

    if (tokens.length > maxTables) {
      return Failure(
        const _GetLookupsBatchParseError(
          'Invalid lookups-batch query: [tables] exceeds the maximum of '
          '$maxTables entries',
        ),
      );
    }

    return Success(GetLookupsBatchIntent(tables: tokens));
  }
}

/// Internal, PII-safe parse error for [GetLookupsBatchIntent.parseFromQuery].
///
/// `const` because every failure message is a fixed literal — the parser
/// never echoes raw values from the request back to the caller.
final class _GetLookupsBatchParseError with Equatable implements Exception {
  const _GetLookupsBatchParseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}
