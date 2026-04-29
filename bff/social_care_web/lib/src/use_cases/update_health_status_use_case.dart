import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/update_health_status_intent.dart';
import '../observability/observability_context.dart';

/// Updates the health-status ficha by delegating to
/// [AssessmentContract.updateHealthStatus].
///
/// Emits the canonical breadcrumb triad under the
/// `assessment.health_status.update` namespace.
///
/// PII invariant: breadcrumbs MUST NOT include deficiency data — in
/// particular [DeficiencyDraftDto.responsibleCaregiverName] (free-text
/// caregiver name) or any other member-scoped field. The `.received` data
/// payload is intentionally limited to `{patientId}`; `.completed` carries
/// no data; `.failed` carries only the upstream `errorCode`.
final class UpdateHealthStatusUseCase {
  const UpdateHealthStatusUseCase({required AssessmentContract assessment})
    : _assessment = assessment;

  final AssessmentContract _assessment;

  Future<Result<StandardResponse<void>>> execute(
    UpdateHealthStatusIntent intent,
    ObservabilityContext obs,
  ) async {
    // PII note: do NOT enrich with deficiency counts or member ids here —
    // the Wave 0 breadcrumb invariant only allows patientId.
    obs.breadcrumb(
      'assessment.health_status.update.received',
      data: {'patientId': intent.patientId},
    );

    final result = await _assessment.updateHealthStatus(
      intent.patientId,
      intent.request,
    );

    return switch (result) {
      Success() => () {
        obs.breadcrumb('assessment.health_status.update.completed');
        return Success<StandardResponse<void>>(
          StandardResponse<void>(
            data: null,
            meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
          ),
        );
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'assessment.health_status.update.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure<StandardResponse<void>>(error);
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
