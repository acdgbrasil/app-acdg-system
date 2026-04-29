import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/update_socio_economic_situation_intent.dart';
import '../observability/observability_context.dart';

/// Updates the socioeconomic ficha by delegating to
/// [AssessmentContract.updateSocioEconomicSituation].
///
/// Emits the canonical breadcrumb triad under the
/// `assessment.socio_economic.update` namespace.
final class UpdateSocioEconomicSituationUseCase {
  const UpdateSocioEconomicSituationUseCase({
    required AssessmentContract assessment,
  }) : _assessment = assessment;

  final AssessmentContract _assessment;

  Future<Result<StandardResponse<void>>> execute(
    UpdateSocioEconomicSituationIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'assessment.socio_economic.update.received',
      data: {'patientId': intent.patientId},
    );

    final result = await _assessment.updateSocioEconomicSituation(
      intent.patientId,
      intent.request,
    );

    return switch (result) {
      Success() => () {
        obs.breadcrumb('assessment.socio_economic.update.completed');
        return Success<StandardResponse<void>>(
          StandardResponse<void>(
            data: null,
            meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
          ),
        );
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'assessment.socio_economic.update.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure<StandardResponse<void>>(error);
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
