import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'root.dart';

void main() {
  // Ensure Flutter bindings are initialized before any core setup
  WidgetsFlutterBinding.ensureInitialized();

  // Capture environment variables at the app level and inject into Core.
  // This ensures variables from .env are correctly picked up in monorepo builds.
  Env.configure(
    oidcIssuer: const String.fromEnvironment('OIDC_ISSUER'),
    oidcClientId: const String.fromEnvironment('OIDC_CLIENT_ID'),
    oidcScopes: const String.fromEnvironment('OIDC_SCOPES'),
    customScheme: const String.fromEnvironment('CUSTOM_SCHEME'),
    oidcWebRedirectUri: const String.fromEnvironment('OIDC_WEB_REDIRECT_URI'),
    oidcWebPostLogoutUri: const String.fromEnvironment(
      'OIDC_WEB_POST_LOGOUT_URI',
    ),
    bffBaseUrl: const String.fromEnvironment('BFF_BASE_URL'),
  );

  // Initialize logging
  AcdgLogger.initialize();

  // Run the Root widget which handles app-wide configuration
  runApp(const Root());
}
