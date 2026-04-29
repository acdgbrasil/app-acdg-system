import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/get_audit_trail_intent.dart';
import '../observability/observability_context.dart';

/// Fetches the audit trail for a patient via [AuditContract.getAuditTrail].
///
/// Emits the canonical triad:
/// - `registry.audit_trail.get.received` — `patientId` + `hasEventTypeFilter`
///   + `hasPagination` flags (NEVER the raw filter values).
/// - `registry.audit_trail.get.completed` — carries `count` (entries length)
///   on success. NEVER the list itself.
/// - `registry.audit_trail.get.failed` — carries `errorCode` on failure.
final class GetAuditTrailUseCase {
  const GetAuditTrailUseCase({required AuditContract audit}) : _audit = audit;

  final AuditContract _audit;

  Future<Result<StandardResponse<List<AuditTrailEntryResponse>>>> execute(
    GetAuditTrailIntent intent,
    ObservabilityContext obs,
  ) async {
    final hasEventTypeFilter =
        intent.eventType != null && intent.eventType!.isNotEmpty;
    final hasPagination = intent.limit != null || intent.offset != null;

    obs.breadcrumb(
      'registry.audit_trail.get.received',
      data: {
        'patientId': intent.patientId,
        'hasEventTypeFilter': hasEventTypeFilter,
        'hasPagination': hasPagination,
      },
    );

    final result = await _audit.getAuditTrail(
      intent.patientId,
      eventType: intent.eventType,
      limit: intent.limit,
      offset: intent.offset,
    );

    return switch (result) {
      Success(:final value) => () {
        obs.breadcrumb(
          'registry.audit_trail.get.completed',
          data: {'count': value.data.length},
        );
        return Success<StandardResponse<List<AuditTrailEntryResponse>>>(value);
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'registry.audit_trail.get.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure<StandardResponse<List<AuditTrailEntryResponse>>>(error);
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
