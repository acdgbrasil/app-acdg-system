import 'package:core_contracts/core_contracts.dart';

/// Intent for `GET /team?role=...&active=...&search=...` — list team
/// professionals with optional filters.
///
/// **First "query-tolerant" intent in the BFF Web canon** (variant of the
/// A14 query-only canon). Where A14's [GetLookupsBatchIntent] requires a
/// `tables` parameter, this intent accepts ALL query parameters as
/// optional. [parseFromQuery] returns:
/// - [Success] when zero filters are present (`GET /team` lists all).
/// - [Success] when filters are present and parseable.
/// - [Failure] only when a present filter is malformed (e.g. `active=abc`
///   instead of `true`/`false`) or a string filter exceeds [maxStringLen].
///
/// Validation rules:
/// - `role`: trimmed; dropped if empty after trim; capped at
///   [maxStringLen].
/// - `active`: must be the literal string `'true'` or `'false'`; any
///   other non-empty value is a [Failure].
/// - `search`: trimmed; dropped if empty after trim; capped at
///   [maxStringLen].
final class ListTeamIntent with Equatable {
  const ListTeamIntent({this.role, this.active, this.search});

  /// Maximum length (in chars) for `role` and `search` filters. Sized for
  /// realistic worker names / emails / CPFs without inviting DoS by
  /// clients sending megabyte query strings.
  static const int maxStringLen = 100;

  final String? role;
  final bool? active;
  final String? search;

  @override
  List<Object?> get props => [role, active, search];

  /// Parses the shelf [Request.url.queryParameters] map into an intent.
  ///
  /// Returns [Success] when every present filter is valid (zero filters
  /// is also valid). Returns [Failure] with a [_ListTeamParseError] when
  /// `active` is not `true`/`false` or when `role`/`search` exceed the
  /// length cap.
  static Result<ListTeamIntent> parseFromQuery(
    Map<String, String> queryParameters,
  ) {
    final role = _readTrimmed(queryParameters['role']);
    final search = _readTrimmed(queryParameters['search']);

    if (role != null && role.length > maxStringLen) {
      return Failure(
        const _ListTeamParseError(
          'Invalid list-team query: [role] exceeds the maximum length',
        ),
      );
    }

    if (search != null && search.length > maxStringLen) {
      return Failure(
        const _ListTeamParseError(
          'Invalid list-team query: [search] exceeds the maximum length',
        ),
      );
    }

    final activeRaw = queryParameters['active'];
    final bool? active;
    if (activeRaw == null || activeRaw.isEmpty) {
      active = null;
    } else if (activeRaw == 'true') {
      active = true;
    } else if (activeRaw == 'false') {
      active = false;
    } else {
      return Failure(
        const _ListTeamParseError(
          'Invalid list-team query: [active] must be "true" or "false"',
        ),
      );
    }

    return Success(ListTeamIntent(role: role, active: active, search: search));
  }

  static String? _readTrimmed(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

/// Internal, PII-safe parse error for [ListTeamIntent.parseFromQuery].
///
/// `const` because every failure message is a fixed literal — the parser
/// never echoes raw query values back to the caller (avoids leaking
/// arbitrary search text via logs / error responses).
final class _ListTeamParseError with Equatable implements Exception {
  const _ListTeamParseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}
