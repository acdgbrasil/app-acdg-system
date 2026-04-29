import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/get_team_member_intent.dart';
import '../observability/observability_context.dart';

/// Fetches the full aggregate (person + roles + status) of a team member
/// by delegating to [TeamContract.getTeamMember].
///
/// Breadcrumb triad: `team.get.{received,completed,failed}`. The
/// `received` breadcrumb intentionally omits `memberId` to keep
/// individual-worker audit trails outside the structured-event surface.
final class GetTeamMemberUseCase {
  const GetTeamMemberUseCase({required TeamContract team}) : _team = team;

  final TeamContract _team;

  Future<Result<StandardResponse<TeamMemberDetailResponse>>> execute(
    GetTeamMemberIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb('team.get.received');

    final result = await _team.getTeamMember(intent.memberId);

    return switch (result) {
      Success(:final value) => () {
        obs.breadcrumb(
          'team.get.completed',
          data: {'roleCount': value.data.roles.length},
        );
        return result;
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'team.get.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return result;
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
