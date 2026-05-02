import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/register_worker_intent.dart';
import '../observability/observability_context.dart';

/// Registers a new team professional by delegating to
/// [TeamContract.registerWorker].
///
/// Emits the canonical breadcrumb triad:
/// - `team.register.received` (carries no PII — only the literal event)
/// - `team.register.completed` (carries the generated `id`)
/// - `team.register.failed` (carries `errorCode`)
///
/// PII discipline: full name, birth date, email, CPF and initial password
/// NEVER appear in breadcrumb data. The `received` breadcrumb intentionally
/// has an empty data map to preserve auditability without leakage.
final class RegisterWorkerUseCase {
  const RegisterWorkerUseCase({required TeamContract team}) : _team = team;

  final TeamContract _team;

  Future<Result<StandardIdResponse>> execute(
    RegisterWorkerIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb('team.register.received');

    final result = await _team.registerWorker(intent.request);

    return switch (result) {
      Success(:final value) => () {
        obs.breadcrumb(
          'team.register.completed',
          data: {'id': value.data.id},
        );
        return result;
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'team.register.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return result;
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
