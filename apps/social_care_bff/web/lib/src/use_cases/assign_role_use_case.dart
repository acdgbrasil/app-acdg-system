import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/assign_role_intent.dart';
import '../observability/observability_context.dart';

/// Assigns a role to a team member by delegating to
/// [TeamContract.assignRole].
///
/// Breadcrumb triad: `team.role.assign.{received,completed,failed}`.
/// Note: `system` and `role` themselves are NOT considered PII (they are
/// fixed enum-like strings such as `social_worker` / `admin`), but they
/// are still kept out of the breadcrumb data to preserve a consistent
/// "structured events carry no business values" discipline across the
/// canon.
final class AssignRoleUseCase {
  const AssignRoleUseCase({required TeamContract team}) : _team = team;

  final TeamContract _team;

  Future<Result<StandardIdResponse>> execute(
    AssignRoleIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb('team.role.assign.received');

    final result = await _team.assignRole(intent.memberId, intent.request);

    return switch (result) {
      Success(:final value) => () {
        obs.breadcrumb(
          'team.role.assign.completed',
          data: {'roleId': value.data.id},
        );
        return result;
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'team.role.assign.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return result;
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
