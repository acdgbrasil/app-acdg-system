import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../infrastructure/logging/log_level.dart';
import '../infrastructure/logging/sentry_client_adapter.dart';
import '../infrastructure/logging/sentry_logger_impl.dart';

/// Centralized logger for the ACDG ecosystem.
///
/// Uses [package:logging] and outputs to [dart:developer.log] in debug mode.
/// When a [SentryClientAdapter] is provided at initialization, error and fatal
/// logs are forwarded to Sentry via [SentryLoggerImpl].
abstract final class AcdgLogger {
  static bool _initialized = false;
  static SentryLoggerImpl? _sentryLogger;
  static SentryClientAdapter? _sentryClient;

  /// Initializes the logging system.
  ///
  /// Should be called at app startup (e.g., in main()).
  /// When [sentryClient] is provided, error/fatal logs are forwarded to Sentry.
  static void initialize({SentryClientAdapter? sentryClient}) {
    if (_initialized) return;

    _sentryClient = sentryClient;

    if (sentryClient != null) {
      _sentryLogger = SentryLoggerImpl(sentryClient: sentryClient);
    }

    Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;

    Logger.root.onRecord.listen((record) {
      if (kDebugMode) {
        dev.log(
          record.message,
          time: record.time,
          sequenceNumber: record.sequenceNumber,
          level: record.level.value,
          name: record.loggerName,
          error: record.error,
          stackTrace: record.stackTrace,
        );
      }

      // Forward to Sentry when configured
      if (_sentryLogger != null) {
        final level = _mapRecordLevel(record.level);
        if (level != null) {
          _sentryLogger!.log(
            record.message,
            level,
            error: record.error,
            stackTrace: record.stackTrace,
          );
        }
      }
    });

    _initialized = true;
  }

  /// Returns a logger for a specific [name].
  static Logger get(String name) => Logger(name);

  /// Sets the authenticated user context on Sentry events.
  ///
  /// Call after successful login so all subsequent events are
  /// associated with the user.
  static void setUser({required String id, String? email, String? username}) {
    _sentryClient?.setUser(id: id, email: email, username: username);
  }

  /// Clears the user context (e.g. on logout).
  static void clearUser() {
    _sentryClient?.clearUser();
  }

  /// Adds a breadcrumb for contextual tracing.
  ///
  /// Breadcrumbs provide a trail of events leading up to an error,
  /// making it easier to reproduce and debug issues in Sentry.
  static void addBreadcrumb({
    required String message,
    String? category,
    Map<String, String>? data,
  }) {
    _sentryClient?.addBreadcrumb(
      message: message,
      category: category,
      data: data,
    );
  }

  /// Maps [package:logging] levels to our [LogLevel].
  ///
  /// Only [Level.SEVERE] and [Level.SHOUT] are forwarded to Sentry.
  static LogLevel? _mapRecordLevel(Level level) {
    if (level >= Level.SHOUT) return LogLevel.fatal;
    if (level >= Level.SEVERE) return LogLevel.error;
    return null;
  }
}
