import 'package:core_contracts/core_contracts.dart';

import 'uuid_validation.dart';

/// Intent envelope for `GET /api/patients/{id}/audit-trail`.
///
/// All filters are optional. Invalid integers (non-numeric `limit` / `offset`)
/// silently collapse to `null` — same total-function canon as
/// [ListPatientsIntent.parseFromQuery].
///
/// The query factory [parseFromQuery] is total — it always returns an
/// intent, even when [patientId] is empty (the handler used to reject
/// that case). After A23 the handler validates the path UUID separately
/// via [parseFromPath] BEFORE calling [parseFromQuery], so [parseFromQuery]
/// is never invoked with an invalid id. Wave 1 UseCase emits breadcrumb
/// FLAGS (`hasEventTypeFilter`, `hasPagination`) rather than raw values,
/// to keep audit observability PII-safe.
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

  /// Validates the route-level patient id as a UUID v4.
  ///
  /// Returns the normalized id on [Success], or a [UuidPathParamError]
  /// on [Failure] (PII-safe — never echoes the raw input). The handler
  /// MUST call this before [parseFromQuery] so that the audit query is
  /// never dispatched against an invalid id.
  static Result<String> parseFromPath(String rawPatientId) {
    return validateUuidPathParam(rawPatientId, fieldName: 'patientId');
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
