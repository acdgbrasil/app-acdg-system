import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/logout_intent.dart';
import '../observability/observability_context.dart';

/// Revokes the current session via [AuthContract.logout].
///
/// Observability canon: emits `auth.logout.received`,
/// `auth.logout.completed` on success and `auth.logout.failed` on backend
/// failure. Session identifiers NEVER appear in breadcrumb data.
final class LogoutUseCase {
  const LogoutUseCase({required AuthContract auth}) : _auth = auth;

  final AuthContract _auth;

  Future<Result<StandardResponse<void>>> execute(
    LogoutIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb('auth.logout.received');

    final result = await _auth.logout();

    return switch (result) {
      Success() => () {
        obs.breadcrumb('auth.logout.completed');
        return result;
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'auth.logout.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return result;
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
