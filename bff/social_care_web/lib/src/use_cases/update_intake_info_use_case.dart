import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/update_intake_info_intent.dart';
import '../observability/observability_context.dart';

/// Updates intake (acolhimento) information by delegating to
/// [CareContract.updateIntakeInfo].
///
/// Emits the canonical triad of breadcrumbs:
/// - `care.intake.update.received` on dispatch (carries `patientId` ONLY)
/// - `care.intake.update.completed` on success
/// - `care.intake.update.failed` on error (carries `errorCode`)
///
/// PII-safety: breadcrumbs NEVER echo `originName`, `originContact` or
/// `serviceReason` — these fields may carry case-history content and MUST
/// stay confined to the upstream call path.
final class UpdateIntakeInfoUseCase {
  const UpdateIntakeInfoUseCase({required CareContract care}) : _care = care;

  final CareContract _care;

  Future<Result<StandardResponse<void>>> execute(
    UpdateIntakeInfoIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'care.intake.update.received',
      data: {'patientId': intent.patientId},
    );

    final result = await _care.updateIntakeInfo(
      intent.patientId,
      intent.request,
    );

    return switch (result) {
      Success() => () {
        obs.breadcrumb('care.intake.update.completed');
        return Success<StandardResponse<void>>(
          StandardResponse<void>(
            data: null,
            meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
          ),
        );
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'care.intake.update.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure<StandardResponse<void>>(error);
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
