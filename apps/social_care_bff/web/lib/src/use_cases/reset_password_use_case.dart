import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/reset_password_intent.dart';
import '../observability/observability_context.dart';

/// Triggers a password reset flow for a team member by delegating to
/// [TeamContract.resetPassword].
///
/// Breadcrumb triad: `team.reset_password.{received,completed,failed}`.
/// The reset email itself is sent out-of-band by Zitadel — this UseCase
/// only signals intent.
final class ResetPasswordUseCase {
  const ResetPasswordUseCase({required TeamContract team}) : _team = team;

  final TeamContract _team;

  Future<Result<StandardResponse<void>>> execute(
    ResetPasswordIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb('team.reset_password.received');

    final result = await _team.resetPassword(intent.memberId);

    return switch (result) {
      Success() => () {
        obs.breadcrumb('team.reset_password.completed');
        return result;
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'team.reset_password.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return result;
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
