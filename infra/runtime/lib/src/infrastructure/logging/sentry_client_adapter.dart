/// Abstraction over the Sentry SDK client.
///
/// Allows injection of a Fake in tests and the real Sentry SDK
/// in production, following Dependency Inversion Principle (DIP).
/// The application never imports `package:sentry` directly —
/// only this adapter interface.
abstract class SentryClientAdapter {
  /// Sends a message to Sentry (used for fatal logs without an exception).
  Future<void> captureMessage(String message, {String? level});

  /// Sends an exception/error to Sentry (used for error logs).
  ///
  /// Accepts any [Object] — not just [Exception] — so that Dart [Error]
  /// types (TypeError, RangeError, etc.) are also captured.
  Future<void> captureException(Object throwable, {StackTrace? stackTrace});

  /// Sets the current user context on Sentry events.
  ///
  /// Call with user details after authentication succeeds.
  void setUser({required String id, String? email, String? username});

  /// Clears the current user context (e.g. on logout).
  void clearUser();

  /// Adds a breadcrumb for contextual tracing of user/domain actions.
  void addBreadcrumb({
    required String message,
    String? category,
    Map<String, String>? data,
  });
}
