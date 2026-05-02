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
    Object throwable, {
    StackTrace? stackTrace,
  }) async {
    await Sentry.captureException(throwable, stackTrace: stackTrace);
  }

  @override
  Future<void> captureMessage(String message, {String? level}) async {
    final sentryLevel = _mapLevel(level);
    await Sentry.captureMessage(message, level: sentryLevel);
  }

  @override
  void setUser({required String id, String? email, String? username}) {
    Sentry.configureScope(
      (scope) =>
          scope.setUser(SentryUser(id: id, email: email, username: username)),
    );
  }

  @override
  void clearUser() {
    Sentry.configureScope((scope) => scope.setUser(null));
  }

  @override
  void addBreadcrumb({
    required String message,
    String? category,
    Map<String, String>? data,
  }) {
    Sentry.addBreadcrumb(
      Breadcrumb(message: message, category: category, data: data),
    );
  }

  SentryLevel _mapLevel(String? level) => switch (level) {
    'fatal' => SentryLevel.fatal,
    'error' => SentryLevel.error,
    'warning' => SentryLevel.warning,
    'info' => SentryLevel.info,
    _ => SentryLevel.error,
  };
}
