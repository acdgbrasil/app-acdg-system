import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/deactivate_worker_intent.dart';
import '../observability/observability_context.dart';

/// Deactivates a team member by delegating to
/// [TeamContract.deactivateWorker].
///
/// Breadcrumb triad: `team.deactivate.{received,completed,failed}`.
/// `memberId` is intentionally NOT included — worker-level audit trails
/// belong to the audit subsystem, not the structured-event log.
final class DeactivateWorkerUseCase {
  const DeactivateWorkerUseCase({required TeamContract team}) : _team = team;

  final TeamContract _team;

  Future<Result<StandardResponse<void>>> execute(
    DeactivateWorkerIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb('team.deactivate.received');

    final result = await _team.deactivateWorker(intent.memberId);

    return switch (result) {
      Success() => () {
        obs.breadcrumb('team.deactivate.completed');
        return result;
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'team.deactivate.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return result;
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
