import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/update_social_health_summary_intent.dart';
import '../observability/observability_context.dart';

/// Updates the social-health-summary ficha by delegating to
/// [AssessmentContract.updateSocialHealthSummary].
///
/// Emits the canonical breadcrumb triad under the
/// `assessment.social_health_summary.update` namespace.
final class UpdateSocialHealthSummaryUseCase {
  const UpdateSocialHealthSummaryUseCase({
    required AssessmentContract assessment,
  }) : _assessment = assessment;

  final AssessmentContract _assessment;

  Future<Result<StandardResponse<void>>> execute(
    UpdateSocialHealthSummaryIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'assessment.social_health_summary.update.received',
      data: {'patientId': intent.patientId},
    );

    final result = await _assessment.updateSocialHealthSummary(
      intent.patientId,
      intent.request,
    );

    return switch (result) {
      Success() => () {
        obs.breadcrumb('assessment.social_health_summary.update.completed');
        return Success<StandardResponse<void>>(
          StandardResponse<void>(
            data: null,
            meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
          ),
        );
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'assessment.social_health_summary.update.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure<StandardResponse<void>>(error);
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
