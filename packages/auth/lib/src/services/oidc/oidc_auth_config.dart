/// Configuration for the OIDC authentication service.
///
/// Immutable model holding all parameters needed to initialize
/// the [OidcUserManager] against a Zitadel instance.
final class OidcAuthConfig {
  const OidcAuthConfig({
    required this.issuer,
    required this.clientId,
    required this.redirectUri,
    required this.postLogoutRedirectUri,
    this.scopes = defaultScopes,
  });

  /// Zitadel issuer URL (e.g. `https://auth.acdgbrasil.com.br`).
  final Uri issuer;

  /// OIDC client ID registered in Zitadel.
  final String clientId;

  /// Platform-specific redirect URI for the auth callback.
  ///
  /// - Web: `https://app.example.com/callback`
  /// - Desktop: `http://localhost:0` (OS picks available port)
  final Uri redirectUri;

  /// Where to redirect after logout.
  final Uri postLogoutRedirectUri;

  /// OIDC scopes to request.
  final List<String> scopes;

  /// Discovery document URI derived from [issuer].
  Uri get discoveryDocumentUri => Uri.parse(
    '${issuer.toString().replaceAll(RegExp(r'/$'), '')}/.well-known/openid-configuration',
  );

  /// Default scopes for ACDG Zitadel.
  static const defaultScopes = [
    'openid',
    'profile',
    'email',
    'offline_access',
    'urn:zitadel:iam:org:project:roles',
  ];
}
