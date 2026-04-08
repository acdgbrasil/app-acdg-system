import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'root.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  const dsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
  const env = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  const release = String.fromEnvironment('SENTRY_RELEASE', defaultValue: '');
  const dist = String.fromEnvironment('SENTRY_DIST', defaultValue: '');

  // Initialize logging — with Sentry forwarding when DSN is configured
  final sentryAdapter = dsn.isNotEmpty ? RealSentryClientAdapter() : null;
  AcdgLogger.initialize(sentryClient: sentryAdapter);

  if (dsn.isNotEmpty) {
    await SentryFlutter.init((options) {
      options.dsn = dsn;
      options.environment = env;
      options.tracesSampleRate = env == 'production' ? 0.2 : 1.0;
      options.sendDefaultPii = true;
      options.debug = env != 'production' && !kReleaseMode;
      if (release.isNotEmpty) options.release = release;
      if (dist.isNotEmpty) options.dist = dist;
    }, appRunner: () => runApp(const Root()));
  } else {
    debugPrint('[Sentry] SKIPPED — SENTRY_DSN is empty');
    runApp(const Root());
  }
}
