import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../auth/session_store.dart';
import '../intents/auth_callback_intent.dart';
import '../observability/observability_context.dart';

/// Handles the OIDC callback from Zitadel — exchanges `code` for tokens and
/// asks the [AuthContract] to establish a session. The handler then flips
/// the returned sessionId into a `Set-Cookie` + redirect.
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
  const AuthCallbackUseCase({
    required AuthContract auth,
    required SessionStore sessionStore,
  }) : _auth = auth,
       _sessionStore = sessionStore;

  final AuthContract _auth;
  final SessionStore _sessionStore;

  /// Returns the SessionStore-issued sessionId on success — that string
  /// MUST be the value the handler writes into the `__Host-session` cookie.
  /// Returns Failure on contract failure; the handler MUST NOT emit any
  /// Set-Cookie when this returns Failure.
  Future<Result<String>> execute(
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
        // SEC: persist the session BEFORE the cookie can leak. SessionStore
        // owns the cryptographically-secure id; we never invent our own.
        // Placeholder claim values: AuthContract.callback returns void today
        // (FakeAuthBff). When the real adapter ships and the contract
        // returns claims, swap these for the real fields. See B2 CONTEXT
        // §2 (Option A) and TRACEABILITY P0-3.
        final sessionId = _sessionStore.create(
          accessToken: '',
          refreshToken: '',
          // SEC: placeholder until contract returns claims (B5 ADR).
          userId: 'pending',
          roles: const <String>{},
        );
        obs.breadcrumb('auth.callback.session_established');
        return Success<String>(sessionId);
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'auth.callback.failed',
          data: {'errorCode': _errorCode(error)},
        );
        // SEC: propagate the contract failure as Result<String> so the type
        // matches the new return signature. No SessionStore.create() called
        // — confirms "token-exchange failure → no cookie + no entry".
        return Failure<String>(error);
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
