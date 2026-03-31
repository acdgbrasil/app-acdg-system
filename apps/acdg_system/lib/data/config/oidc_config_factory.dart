import 'package:auth/auth.dart';
import 'package:core/core.dart';

/// Factory to build OIDC configuration from environment variables.
class OidcConfigFactory {
  const OidcConfigFactory._();

  static OidcAuthConfig fromEnvironment() {
    final issuer = Env.oidcIssuer;
    final clientId = Env.oidcClientId;

    if (issuer.isEmpty || clientId.isEmpty) {
      throw StateError(
        'Missing OIDC configuration. '
        'Ensure you are running with --dart-define-from-file=.env and '
        'Env.configure() is called in main().',
      );
    }

    final redirectUri = _resolveRedirectUri(issuer);
    final postLogoutUri = _resolveLogoutUri(issuer);

    // Convert scopes string to List
    final scopes = Env.oidcScopes.isNotEmpty
        ? Env.oidcScopes.split(' ')
        : const <String>[];

    return OidcAuthConfig(
      issuer: Uri.parse(issuer),
      clientId: clientId,
      redirectUri: redirectUri,
      postLogoutRedirectUri: postLogoutUri,
      scopes: scopes.isNotEmpty ? scopes : OidcAuthConfig.defaultScopes,
    );
  }

  static Uri _resolveRedirectUri(String issuer) {
    if (PlatformResolver.isWeb) {
      final uri = Env.oidcWebRedirectUri;
      return Uri.parse(uri.isNotEmpty ? uri : '$issuer/callback');
    }
    if (PlatformResolver.isMacOS) {
      return Uri.parse('${Env.customScheme}://callback');
    }
    return Uri.parse('http://localhost:0');
  }

  static Uri _resolveLogoutUri(String issuer) {
    if (PlatformResolver.isWeb) {
      final uri = Env.oidcWebPostLogoutUri;
      return Uri.parse(uri.isNotEmpty ? uri : issuer);
    }
    if (PlatformResolver.isMacOS) {
      return Uri.parse('${Env.customScheme}://logout');
    }
    return Uri.parse('http://localhost:0');
  }
}
