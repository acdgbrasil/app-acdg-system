import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/login_intent.dart';
import '../observability/observability_context.dart';

/// Dispatches an OIDC login — delegates to [AuthContract.login] to obtain
/// the redirect URL the APP will navigate to.
///
/// Emits the `auth.login.received` breadcrumb on dispatch,
/// `auth.login.redirect_issued` on success and `auth.login.failed` on error
/// (Wave 0 observability canon). PII is scrubbed: we never log the full
/// redirect URL, only the intent metadata.
final class LoginUseCase {
  const LoginUseCase({required AuthContract auth}) : _auth = auth;

  final AuthContract _auth;

  Future<Result<String>> execute(
    LoginIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'auth.login.received',
      data: {if (intent.returnTo != null) 'returnTo': intent.returnTo},
    );

    final result = await _auth.login();
    return switch (result) {
      Success() => () {
        obs.breadcrumb('auth.login.redirect_issued');
        return result;
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'auth.login.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return result;
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
