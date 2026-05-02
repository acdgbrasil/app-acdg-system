import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/update_work_and_income_intent.dart';
import '../observability/observability_context.dart';

/// Updates the work-and-income ficha by delegating to
/// [AssessmentContract.updateWorkAndIncome].
///
/// Emits the canonical breadcrumb triad under the
/// `assessment.work_and_income.update` namespace.
final class UpdateWorkAndIncomeUseCase {
  const UpdateWorkAndIncomeUseCase({required AssessmentContract assessment})
    : _assessment = assessment;

  final AssessmentContract _assessment;

  Future<Result<StandardResponse<void>>> execute(
    UpdateWorkAndIncomeIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'assessment.work_and_income.update.received',
      data: {'patientId': intent.patientId},
    );

    final result = await _assessment.updateWorkAndIncome(
      intent.patientId,
      intent.request,
    );

    return switch (result) {
      Success() => () {
        obs.breadcrumb('assessment.work_and_income.update.completed');
        return Success<StandardResponse<void>>(
          StandardResponse<void>(
            data: null,
            meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
          ),
        );
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'assessment.work_and_income.update.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure<StandardResponse<void>>(error);
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
