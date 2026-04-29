import 'package:core_contracts/core_contracts.dart';

/// Intent produced by the OIDC callback endpoint after Zitadel redirects.
///
/// Carries the authorization [code] and PKCE [state] returned by the IdP.
/// Parsing happens via [parseFromQuery] which returns a [Result] — failures
/// never echo the raw [code] in error messages (PII masking, Wave 0).
final class AuthCallbackIntent with Equatable {
  const AuthCallbackIntent({required this.code, required this.state});

  /// Authorization code granted by the IdP. Opaque to the BFF; forwarded
  /// to [AuthContract.callback] for token exchange.
  final String code;

  /// Opaque PKCE/CSRF state token returned alongside [code].
  final String state;

  @override
  List<Object?> get props => [code, state];

  /// Parses shelf query parameters into an [AuthCallbackIntent].
  ///
  /// Uses P2 if-case to enforce that both `code` and `state` are present
  /// and non-empty. Failure messages are PII-safe: they mention which
  /// field is missing without echoing the raw values.
  static Result<AuthCallbackIntent> parseFromQuery(Map<String, String> query) {
    if (query case {
      'code': final String code,
      'state': final String state,
    } when code.isNotEmpty && state.isNotEmpty) {
      return Success(AuthCallbackIntent(code: code, state: state));
    }

    final missing = <String>[];
    if ((query['code'] ?? '').isEmpty) missing.add('code');
    if ((query['state'] ?? '').isEmpty) missing.add('state');

    return Failure(
      _AuthCallbackParseError(
        'Invalid OIDC callback: missing or empty fields '
        '[${missing.join(', ')}]',
      ),
    );
  }
}

/// Internal parse error for [AuthCallbackIntent.parseFromQuery].
///
/// Deliberately avoids carrying the raw authorization code or state so the
/// error cannot be weaponized to leak secrets via logs or response bodies.
final class _AuthCallbackParseError with Equatable implements Exception {
  const _AuthCallbackParseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}
