import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/list_team_intent.dart';
import '../observability/observability_context.dart';

/// Lists team professionals by delegating to [TeamContract.listTeam].
///
/// Emits the canonical breadcrumb triad:
/// - `team.list.received` (carries `hasRole`, `hasActive`, `hasSearch`)
/// - `team.list.completed` (carries `count`)
/// - `team.list.failed` (carries `errorCode`)
///
/// Filter values themselves are NEVER attached to the breadcrumb data —
/// `search` is free-text and could carry PII (worker name fragments,
/// CPFs being typed into the team admin filter). Only the *presence*
/// of each filter is recorded.
final class ListTeamUseCase {
  const ListTeamUseCase({required TeamContract team}) : _team = team;

  final TeamContract _team;

  Future<Result<StandardResponse<List<TeamMemberResponse>>>> execute(
    ListTeamIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'team.list.received',
      data: {
        'hasRole': intent.role != null,
        'hasActive': intent.active != null,
        'hasSearch': intent.search != null,
      },
    );

    final result = await _team.listTeam(
      role: intent.role,
      active: intent.active,
      search: intent.search,
    );

    return switch (result) {
      Success(:final value) => () {
        obs.breadcrumb(
          'team.list.completed',
          data: {'count': value.data.length},
        );
        return result;
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'team.list.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return result;
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
