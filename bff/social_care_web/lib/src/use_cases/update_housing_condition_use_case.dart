import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/update_housing_condition_intent.dart';
import '../observability/observability_context.dart';

/// Updates the housing condition ficha by delegating to
/// [AssessmentContract.updateHousingCondition].
///
/// Emits the canonical breadcrumb triad:
/// - `assessment.housing.update.received` on dispatch (carries `patientId`)
/// - `assessment.housing.update.completed` on success
/// - `assessment.housing.update.failed` on error (carries `errorCode`)
final class UpdateHousingConditionUseCase {
  const UpdateHousingConditionUseCase({required AssessmentContract assessment})
    : _assessment = assessment;

  final AssessmentContract _assessment;

  Future<Result<StandardResponse<void>>> execute(
    UpdateHousingConditionIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'assessment.housing.update.received',
      data: {'patientId': intent.patientId},
    );

    final result = await _assessment.updateHousingCondition(
      intent.patientId,
      intent.request,
    );

    return switch (result) {
      Success() => () {
        obs.breadcrumb('assessment.housing.update.completed');
        return Success<StandardResponse<void>>(
          StandardResponse<void>(
            data: null,
            meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
          ),
        );
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'assessment.housing.update.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure<StandardResponse<void>>(error);
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
