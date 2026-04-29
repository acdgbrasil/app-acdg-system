import 'package:core_contracts/core_contracts.dart';

/// Intent envelope for `GET /api/patients/{id}/audit-trail`.
///
/// All filters are optional. Invalid integers (non-numeric `limit` / `offset`)
/// silently collapse to `null` — same total-function canon as
/// [ListPatientsIntent.parseFromQuery].
///
/// The intent still constructs when [patientId] is empty; the handler is
/// expected to reject that upstream with a 400. Wave 1 UseCase emits
/// breadcrumb FLAGS (`hasEventTypeFilter`, `hasPagination`) rather than
/// raw values, to keep audit observability PII-safe.
final class GetAuditTrailIntent with Equatable {
  const GetAuditTrailIntent({
    required this.patientId,
    this.eventType,
    this.limit,
    this.offset,
  });

  final String patientId;
  final String? eventType;
  final int? limit;
  final int? offset;

  @override
  List<Object?> get props => [patientId, eventType, limit, offset];

  /// Total-function factory mirroring [ListPatientsIntent.parseFromQuery] —
  /// always returns an intent; invalid values are coerced to `null`.
  factory GetAuditTrailIntent.parseFromQuery(
    String patientId,
    Map<String, String> query,
  ) {
    return GetAuditTrailIntent(
      patientId: patientId,
      eventType: _coerce(query['eventType']),
      limit: _parseInt(query['limit']),
      offset: _parseInt(query['offset']),
    );
  }

  static String? _coerce(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int? _parseInt(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return int.tryParse(raw.trim());
  }
}
