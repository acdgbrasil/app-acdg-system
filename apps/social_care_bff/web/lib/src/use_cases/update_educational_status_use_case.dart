import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/update_educational_status_intent.dart';
import '../observability/observability_context.dart';

/// Updates the educational-status ficha by delegating to
/// [AssessmentContract.updateEducationalStatus].
///
/// Emits the canonical breadcrumb triad under the
/// `assessment.educational_status.update` namespace.
final class UpdateEducationalStatusUseCase {
  const UpdateEducationalStatusUseCase({required AssessmentContract assessment})
    : _assessment = assessment;

  final AssessmentContract _assessment;

  Future<Result<StandardResponse<void>>> execute(
    UpdateEducationalStatusIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'assessment.educational_status.update.received',
      data: {'patientId': intent.patientId},
    );

    final result = await _assessment.updateEducationalStatus(
      intent.patientId,
      intent.request,
    );

    return switch (result) {
      Success() => () {
        obs.breadcrumb('assessment.educational_status.update.completed');
        return Success<StandardResponse<void>>(
          StandardResponse<void>(
            data: null,
            meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
          ),
        );
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'assessment.educational_status.update.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure<StandardResponse<void>>(error);
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
