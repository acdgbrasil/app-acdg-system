import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'root.dart';

void main() async {
  const dsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
  const env = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  const release = String.fromEnvironment('SENTRY_RELEASE', defaultValue: '');
  const dist = String.fromEnvironment('SENTRY_DIST', defaultValue: '');

  if (dsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.environment = env;
        options.tracesSampleRate = env == 'production' ? 0.2 : 1.0;
        options.sendDefaultPii = true;
        options.debug = env != 'production' && !kReleaseMode;
        if (release.isNotEmpty) options.release = release;
        if (dist.isNotEmpty) options.dist = dist;
      },
      appRunner: () {
        _initializeApp();
        runApp(const Root());
      },
    );
  } else {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('[Sentry] SKIPPED — SENTRY_DSN is empty');
    _initializeApp();
    runApp(const Root());
  }
}

void _initializeApp() {
  const dsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');

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
    peopleContextBaseUrl: const String.fromEnvironment(
      'PEOPLE_CONTEXT_BASE_URL',
    ),
  );

  final sentryAdapter = dsn.isNotEmpty ? RealSentryClientAdapter() : null;
  AcdgLogger.initialize(sentryClient: sentryAdapter);
}
