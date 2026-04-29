import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/assign_primary_caregiver_intent.dart';
import '../observability/observability_context.dart';

/// Assigns a primary caregiver by delegating to
/// [RegistryContract.assignPrimaryCaregiver].
///
/// Emits the canonical triad:
/// - `registry.family.assign_caregiver.received` — `patientId`
/// - `registry.family.assign_caregiver.completed` on success
/// - `registry.family.assign_caregiver.failed` with `errorCode` on failure
final class AssignPrimaryCaregiverUseCase {
  const AssignPrimaryCaregiverUseCase({required RegistryContract registry})
    : _registry = registry;

  final RegistryContract _registry;

  Future<Result<StandardResponse<void>>> execute(
    AssignPrimaryCaregiverIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'registry.family.assign_caregiver.received',
      data: {'patientId': intent.patientId},
    );

    final result = await _registry.assignPrimaryCaregiver(
      intent.patientId,
      intent.request,
    );

    return switch (result) {
      Success() => () {
        obs.breadcrumb('registry.family.assign_caregiver.completed');
        return Success<StandardResponse<void>>(
          StandardResponse<void>(
            data: null,
            meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
          ),
        );
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'registry.family.assign_caregiver.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure<StandardResponse<void>>(error);
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
