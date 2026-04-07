import 'package:sentry_flutter/sentry_flutter.dart';

import 'sentry_client_adapter.dart';

/// Production implementation of [SentryClientAdapter] backed by the
/// real Sentry SDK.
///
/// This class is the only place in the codebase that imports
/// `package:sentry_flutter` — everything else depends on the abstract
/// [SentryClientAdapter] interface.
class RealSentryClientAdapter implements SentryClientAdapter {
  @override
  Future<void> captureException(
    Exception exception, {
    StackTrace? stackTrace,
  }) async {
    await Sentry.captureException(exception, stackTrace: stackTrace);
  }

  @override
  Future<void> captureMessage(String message, {String? level}) async {
    final sentryLevel = _mapLevel(level);
    await Sentry.captureMessage(message, level: sentryLevel);
  }

  SentryLevel _mapLevel(String? level) => switch (level) {
    'fatal' => SentryLevel.fatal,
    'error' => SentryLevel.error,
    'warning' => SentryLevel.warning,
    'info' => SentryLevel.info,
    _ => SentryLevel.error,
  };
}
