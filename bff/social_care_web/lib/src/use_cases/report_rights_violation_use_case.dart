import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/report_rights_violation_intent.dart';
import '../observability/observability_context.dart';

/// Reports a rights violation by delegating to
/// [ProtectionContract.reportViolation].
///
/// Emits the canonical triad of breadcrumbs:
/// - `protection.violation.report.received` on dispatch (carries
///   `patientId` ONLY — never victimId / violationType / descriptionOfFact)
/// - `protection.violation.report.completed` on success (carries
///   `violationId` — a non-PII UUID)
/// - `protection.violation.report.failed` on error (carries `errorCode`)
///
/// PII-safety (CRITICAL): breadcrumbs NEVER echo `descriptionOfFact`
/// (violation narrative), `actionsTaken` (intervention notes), `victimId`
/// (UUID but PII-adjacent) or `violationType` label. These fields may
/// carry extremely sensitive content (often involving minors) and MUST
/// stay confined to the upstream call path.
final class ReportRightsViolationUseCase {
  const ReportRightsViolationUseCase({required ProtectionContract protection})
    : _protection = protection;

  final ProtectionContract _protection;

  Future<Result<StandardIdResponse>> execute(
    ReportRightsViolationIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'protection.violation.report.received',
      data: {'patientId': intent.patientId},
    );

    final result = await _protection.reportViolation(
      intent.patientId,
      intent.request,
    );

    return switch (result) {
      Success(:final value) => () {
        obs.breadcrumb(
          'protection.violation.report.completed',
          data: {'violationId': value.data.id},
        );
        return Success<StandardIdResponse>(value);
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'protection.violation.report.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure<StandardIdResponse>(error);
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
