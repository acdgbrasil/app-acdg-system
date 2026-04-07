import 'package:auth/auth.dart';
import 'package:core/core.dart';

import 'oidc_config_factory.dart';

/// Factory that creates the appropriate [AuthService] for the current platform.
///
/// - **Web:** [BffAuthService] — delegates auth to the BFF server (HttpOnly cookies).
/// - **Desktop:** [OidcAuthService] — OIDC PKCE flow with Zitadel.
abstract final class AuthConfigFactory {
  const AuthConfigFactory._();

  /// Creates an [AuthService] suitable for the running platform.
  static AuthService createAuthService() {
    if (PlatformResolver.isWeb) {
      return BffAuthService(config: BffAuthConfig(bffBaseUrl: Env.bffBaseUrl));
    }

    return OidcAuthService(config: OidcConfigFactory.fromEnvironment());
  }
}
