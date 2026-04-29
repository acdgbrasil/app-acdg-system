import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/refresh_intent.dart';
import '../observability/observability_context.dart';

/// Refreshes access tokens via [AuthContract.refresh].
///
/// Observability canon: `auth.refresh.received`, `auth.refresh.completed`,
/// `auth.refresh.failed`. Tokens and session identifiers never appear in
/// breadcrumb data.
final class RefreshUseCase {
  const RefreshUseCase({required AuthContract auth}) : _auth = auth;

  final AuthContract _auth;

  Future<Result<StandardResponse<void>>> execute(
    RefreshIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb('auth.refresh.received');

    final result = await _auth.refresh();

    return switch (result) {
      Success() => () {
        obs.breadcrumb('auth.refresh.completed');
        return result;
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'auth.refresh.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return result;
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
