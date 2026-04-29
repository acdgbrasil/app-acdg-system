import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/deactivate_role_intent.dart';
import '../observability/observability_context.dart';

/// Soft-deactivates a role assignment by delegating to
/// [TeamContract.deactivateRole].
///
/// Breadcrumb triad: `team.role.deactivate.{received,completed,failed}`.
final class DeactivateRoleUseCase {
  const DeactivateRoleUseCase({required TeamContract team}) : _team = team;

  final TeamContract _team;

  Future<Result<StandardResponse<void>>> execute(
    DeactivateRoleIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb('team.role.deactivate.received');

    final result = await _team.deactivateRole(intent.memberId, intent.roleId);

    return switch (result) {
      Success() => () {
        obs.breadcrumb('team.role.deactivate.completed');
        return result;
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'team.role.deactivate.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return result;
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
