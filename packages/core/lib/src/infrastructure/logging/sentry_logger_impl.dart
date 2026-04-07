import 'dart:developer' as developer;

import 'log_level.dart';
import 'sentry_client_adapter.dart';

/// Logger implementation that dispatches to Sentry based on [LogLevel].
///
/// - [LogLevel.info] and [LogLevel.warning]: local-only (dart:developer).
/// - [LogLevel.error]: sends `captureException` to Sentry (requires exception).
/// - [LogLevel.fatal]: sends `captureMessage` to Sentry (no exception needed).
///
/// The [SentryClientAdapter] is injected via constructor, following DIP.
/// ViewModels and UseCases only know about [SentryLoggerImpl] through
/// the logging abstraction — they never import Sentry directly.
class SentryLoggerImpl {
  SentryLoggerImpl({required SentryClientAdapter sentryClient})
    : _sentryClient = sentryClient;

  final SentryClientAdapter _sentryClient;

  void log(
    String message,
    LogLevel level, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Always log locally for development visibility
    developer.log(
      message,
      name: 'ACDG',
      level: _levelToInt(level),
      error: error,
      stackTrace: stackTrace,
    );

    // Only forward to Sentry for error and fatal
    switch (level) {
      case LogLevel.info:
      case LogLevel.warning:
        break;
      case LogLevel.error:
        if (error is Exception) {
          _sentryClient.captureException(error, stackTrace: stackTrace);
        }
      case LogLevel.fatal:
        if (error is Exception) {
          _sentryClient.captureException(error, stackTrace: stackTrace);
        } else {
          _sentryClient.captureMessage(message, level: 'fatal');
        }
    }
  }

  int _levelToInt(LogLevel level) => switch (level) {
    LogLevel.info => 800,
    LogLevel.warning => 900,
    LogLevel.error => 1000,
    LogLevel.fatal => 1200,
  };
}
