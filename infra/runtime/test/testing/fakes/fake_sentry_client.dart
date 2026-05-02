import 'package:core/src/infrastructure/logging/sentry_client_adapter.dart';

class FakeSentryClient implements SentryClientAdapter {
  final List<String> capturedMessages = [];
  final List<Object> capturedExceptions = [];
  final List<String> messageLevels = [];
  final List<Map<String, String?>> users = [];
  final List<Map<String, dynamic>> breadcrumbs = [];
  bool userCleared = false;

  @override
  Future<void> captureMessage(String message, {String? level}) async {
    capturedMessages.add(message);
    if (level != null) messageLevels.add(level);
  }

  @override
  Future<void> captureException(
    Object throwable, {
    StackTrace? stackTrace,
  }) async {
    capturedExceptions.add(throwable);
  }

  @override
  void setUser({required String id, String? email, String? username}) {
    userCleared = false;
    users.add({'id': id, 'email': email, 'username': username});
  }

  @override
  void clearUser() {
    userCleared = true;
  }

  @override
  void addBreadcrumb({
    required String message,
    String? category,
    Map<String, String>? data,
  }) {
    breadcrumbs.add({'message': message, 'category': category, 'data': data});
  }
}
