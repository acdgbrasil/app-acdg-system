import 'package:core/src/infrastructure/logging/sentry_client_adapter.dart';

class FakeSentryClient implements SentryClientAdapter {
  final List<String> capturedMessages = [];
  final List<Exception> capturedExceptions = [];
  final List<String> messageLevels = [];

  @override
  Future<void> captureMessage(String message, {String? level}) async {
    capturedMessages.add(message);
    if (level != null) messageLevels.add(level);
  }

  @override
  Future<void> captureException(
    Exception exception, {
    StackTrace? stackTrace,
  }) async {
    capturedExceptions.add(exception);
  }
}
