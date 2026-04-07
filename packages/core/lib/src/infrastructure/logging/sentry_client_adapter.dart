/// Abstraction over the Sentry SDK client.
///
/// Allows injection of a Fake in tests and the real Sentry SDK
/// in production, following Dependency Inversion Principle (DIP).
/// The application never imports `package:sentry` directly —
/// only this adapter interface.
abstract class SentryClientAdapter {
  /// Sends a message to Sentry (used for fatal logs without an exception).
  Future<void> captureMessage(String message, {String? level});

  /// Sends an exception to Sentry (used for error logs with a thrown object).
  Future<void> captureException(Exception exception, {StackTrace? stackTrace});
}
