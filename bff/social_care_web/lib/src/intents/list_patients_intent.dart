import 'package:core_contracts/core_contracts.dart';

/// Intent for `GET /api/patients` — optional filters and cursor pagination.
///
/// All fields are optional and collapse to `null` when absent or empty. The
/// handler forwards them verbatim to [RegistryContract.fetchPatients]; the
/// UseCase is not responsible for input coercion beyond what
/// [parseFromQuery] already does.
final class ListPatientsIntent with Equatable {
  const ListPatientsIntent({this.search, this.status, this.cursor, this.limit});

  /// Substring match against patient full name (case-insensitive upstream).
  final String? search;

  /// Lifecycle status filter (e.g. `admitted`, `discharged`, `withdrawn`).
  final String? status;

  /// Opaque pagination cursor returned by the previous page.
  final String? cursor;

  /// Page size hint; invalid (non-numeric) values collapse to `null`.
  final int? limit;

  @override
  List<Object?> get props => [search, status, cursor, limit];

  /// Builds a [ListPatientsIntent] from a shelf query map.
  ///
  /// Normalisation rules:
  /// - whitespace-only or empty strings collapse to `null` so we don't
  ///   forward empty filters downstream;
  /// - `limit` goes through [int.tryParse]; non-numeric values become `null`.
  ///
  /// Total function — never throws, never returns a [Failure]. Invalid input
  /// is silently coerced away.
  factory ListPatientsIntent.parseFromQuery(Map<String, String> query) {
    return ListPatientsIntent(
      search: _coerce(query['search']),
      status: _coerce(query['status']),
      cursor: _coerce(query['cursor']),
      limit: _parseLimit(query['limit']),
    );
  }

  static String? _coerce(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int? _parseLimit(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return int.tryParse(raw.trim());
  }
}
