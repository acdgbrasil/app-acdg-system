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
        'Build with: flutter run --dart-define=OIDC_ISSUER=https://... '
        '--dart-define=OIDC_CLIENT_ID=...',
      );
    }

    final redirectUri = _resolveRedirectUri(issuer);
    final postLogoutUri = _resolveLogoutUri(issuer);

    return OidcAuthConfig(
      issuer: Uri.parse(issuer),
      clientId: clientId,
      redirectUri: redirectUri,
      postLogoutRedirectUri: postLogoutUri,
    );
  }

  static Uri _resolveRedirectUri(String issuer) {
    if (PlatformResolver.isWeb) {
      final uri = Env.oidcWebRedirectUri;
      return Uri.parse(uri.isNotEmpty ? uri : '$issuer/callback');
    }
    if (PlatformResolver.isMacOS) {
      return Uri.parse('com.acdg.system://callback');
    }
    return Uri.parse('http://localhost:0');
  }

  static Uri _resolveLogoutUri(String issuer) {
    if (PlatformResolver.isWeb) {
      final uri = Env.oidcWebPostLogoutUri;
      return Uri.parse(uri.isNotEmpty ? uri : issuer);
    }
    if (PlatformResolver.isMacOS) {
      return Uri.parse('com.acdg.system://logout');
    }
    return Uri.parse('http://localhost:0');
  }
}
