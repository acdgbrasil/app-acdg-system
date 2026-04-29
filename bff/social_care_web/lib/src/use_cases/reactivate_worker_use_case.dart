import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/reactivate_worker_intent.dart';
import '../observability/observability_context.dart';

/// Reactivates a previously deactivated team member by delegating to
/// [TeamContract.reactivateWorker].
///
/// Breadcrumb triad: `team.reactivate.{received,completed,failed}`.
final class ReactivateWorkerUseCase {
  const ReactivateWorkerUseCase({required TeamContract team}) : _team = team;

  final TeamContract _team;

  Future<Result<StandardResponse<void>>> execute(
    ReactivateWorkerIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb('team.reactivate.received');

    final result = await _team.reactivateWorker(intent.memberId);

    return switch (result) {
      Success() => () {
        obs.breadcrumb('team.reactivate.completed');
        return result;
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'team.reactivate.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return result;
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
