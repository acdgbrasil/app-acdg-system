import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/reactivate_role_intent.dart';
import '../observability/observability_context.dart';

/// Reactivates a previously deactivated role by delegating to
/// [TeamContract.reactivateRole].
///
/// Breadcrumb triad: `team.role.reactivate.{received,completed,failed}`.
final class ReactivateRoleUseCase {
  const ReactivateRoleUseCase({required TeamContract team}) : _team = team;

  final TeamContract _team;

  Future<Result<StandardResponse<void>>> execute(
    ReactivateRoleIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb('team.role.reactivate.received');

    final result = await _team.reactivateRole(intent.memberId, intent.roleId);

    return switch (result) {
      Success() => () {
        obs.breadcrumb('team.role.reactivate.completed');
        return result;
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'team.role.reactivate.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return result;
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
