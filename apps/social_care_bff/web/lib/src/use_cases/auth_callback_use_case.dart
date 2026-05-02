import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/auth_callback_intent.dart';
import '../observability/observability_context.dart';

/// Handles the OIDC callback from Zitadel — exchanges `code` for tokens and
/// asks the [AuthContract] to establish a session. The handler then flips
/// the returned [StandardResponse] into a `Set-Cookie` + redirect.
///
/// Observability canon (Wave 0):
/// - `auth.callback.received` on dispatch (with masked codePrefix)
/// - `auth.callback.session_established` on success
/// - `auth.callback.failed` on backend failure
///
/// PII masking: we log only the first 6 chars of [AuthCallbackIntent.code]
/// followed by `***`. The full code and the state value never leave the
/// UseCase boundary.
final class AuthCallbackUseCase {
  const AuthCallbackUseCase({required AuthContract auth}) : _auth = auth;

  final AuthContract _auth;

  Future<Result<StandardResponse<void>>> execute(
    AuthCallbackIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'auth.callback.received',
      data: {'codePrefix': _maskCode(intent.code)},
    );

    final result = await _auth.callback(code: intent.code, state: intent.state);

    return switch (result) {
      Success() => () {
        obs.breadcrumb('auth.callback.session_established');
        return result;
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'auth.callback.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return result;
      }(),
    };
  }

  /// Masks the OIDC code for breadcrumbs: first 6 chars + `***`.
  ///
  /// Short codes (< 6 chars) are fully masked so we never end up logging
  /// the whole value as a "prefix".
  String _maskCode(String code) {
    if (code.length < 6) return '***';
    return '${code.substring(0, 6)}***';
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
