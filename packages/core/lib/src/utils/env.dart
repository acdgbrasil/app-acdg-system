import '../platform/platform_resolver.dart';

/// Utility to access environment variables.
///
/// In a monorepo setup, environment variables are captured at the app level
/// and injected into the core package via [configure].
abstract final class Env {
  const Env._();

  static String _oidcIssuer = '';
  static String _oidcClientId = '';
  static String _oidcScopes = '';
  static String _customScheme = 'com.acdg.system';
  static String _oidcWebRedirectUri = '';
  static String _oidcWebPostLogoutUri = '';
  static String _bffBaseUrl = 'http://localhost:8080';

  /// OIDC Configuration
  static String get oidcIssuer => _oidcIssuer;
  static String get oidcClientId => _oidcClientId;
  static String get oidcScopes => _oidcScopes;
  static String get customScheme => _customScheme;
  static String get oidcWebRedirectUri => _oidcWebRedirectUri;
  static String get oidcWebPostLogoutUri => _oidcWebPostLogoutUri;

  /// BFF Configuration
  static String get bffBaseUrl => _bffBaseUrl;

  /// Configures the environment with injected values.
  ///
  /// This should be called in main() before any other setup.
  static void configure({
    required String oidcIssuer,
    required String oidcClientId,
    String oidcScopes = '',
    String customScheme = 'com.acdg.system',
    String oidcWebRedirectUri = '',
    String oidcWebPostLogoutUri = '',
    String bffBaseUrl = 'http://localhost:8080',
  }) {
    _oidcIssuer = oidcIssuer;
    _oidcClientId = oidcClientId;
    _oidcScopes = oidcScopes;
    _customScheme = customScheme.isEmpty ? 'com.acdg.system' : customScheme;
    _oidcWebRedirectUri = oidcWebRedirectUri;
    _oidcWebPostLogoutUri = oidcWebPostLogoutUri;
    _bffBaseUrl = bffBaseUrl.isEmpty ? 'http://localhost:8080' : bffBaseUrl;

    validate();
  }

  /// Validates mandatory environment variables.
  ///
  /// On **web** OIDC variables are optional because the BFF handles the
  /// OIDC flow server-side; only `BFF_BASE_URL` is needed.
  /// On **desktop** `OIDC_ISSUER` and `OIDC_CLIENT_ID` are required.
  static void validate() {
    // Web delegates auth to the BFF — no OIDC client config needed.
    if (PlatformResolver.isWeb) return;

    final missing = <String>[];

    if (_oidcIssuer.isEmpty) missing.add('OIDC_ISSUER');
    if (_oidcClientId.isEmpty) missing.add('OIDC_CLIENT_ID');

    if (missing.isNotEmpty) {
      throw StateError(
        'Missing mandatory environment variables: ${missing.join(', ')}.\n'
        'Ensure you are running with --dart-define-from-file=.env and '
        'Env.configure() is called in main().',
      );
    }
  }
}
