import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/update_placement_history_intent.dart';
import '../observability/observability_context.dart';

/// Updates the institutional placement history by delegating to
/// [ProtectionContract.updatePlacementHistory].
///
/// Emits the canonical breadcrumb triad:
/// - `protection.placement_history.update.received` on dispatch (carries
///   `patientId` ONLY — never registries / collectiveSituations /
///   separationChecklist content)
/// - `protection.placement_history.update.completed` on success
/// - `protection.placement_history.update.failed` on error (carries
///   `errorCode`)
///
/// The upstream [ProtectionContract.updatePlacementHistory] returns
/// `Future<Result<void>>`. This UseCase rewraps the success into the
/// canonical [StandardResponse<void>] envelope so the handler layer stays
/// uniform with the rest of the BFF (A08/A10 canon).
///
/// PII-safety (CRITICAL): breadcrumbs NEVER echo `homeLossReport` /
/// `thirdPartyGuardReport` (family-history narrative), `registries[].reason`
/// (placement reasoning — violence, abandonment, etc.), `memberId` UUIDs,
/// or `separationChecklist` boolean flags. These fields may carry highly
/// sensitive content and MUST stay confined to the upstream call path.
final class UpdatePlacementHistoryUseCase {
  const UpdatePlacementHistoryUseCase({required ProtectionContract protection})
    : _protection = protection;

  final ProtectionContract _protection;

  Future<Result<StandardResponse<void>>> execute(
    UpdatePlacementHistoryIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'protection.placement_history.update.received',
      data: {'patientId': intent.patientId},
    );

    final result = await _protection.updatePlacementHistory(
      intent.patientId,
      intent.request,
    );

    return switch (result) {
      Success() => () {
        obs.breadcrumb('protection.placement_history.update.completed');
        return Success<StandardResponse<void>>(
          StandardResponse<void>(
            data: null,
            meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
          ),
        );
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'protection.placement_history.update.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure<StandardResponse<void>>(error);
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
