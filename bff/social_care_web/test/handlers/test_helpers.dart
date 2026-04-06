import 'package:social_care_web/src/auth/session_store.dart';
import 'package:social_care_web/src/middleware/session_middleware.dart';
import 'package:shelf/shelf.dart';

/// A test session for use in handler tests.
final testSession = Session(
  id: 'test-session-id',
  accessToken: 'test-access-token',
  refreshToken: 'test-refresh-token',
  userId: 'test-user-id',
  roles: {'social_worker'},
  expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
);

/// Valid UUID for test fixtures.
const testPatientId = '550e8400-e29b-41d4-a716-446655440000';
const testPersonId = '660e8400-e29b-41d4-a716-446655440001';
const testMemberId = '770e8400-e29b-41d4-a716-446655440002';
const testLookupId = '880e8400-e29b-41d4-a716-446655440003';

/// Creates a shelf [Request] with the test session in context.
Request testRequest(
  String method,
  String path, {
  String? body,
  Map<String, String>? headers,
}) {
  return Request(
    method,
    Uri.parse('http://localhost$path'),
    body: body,
    headers: {
      if (body != null) 'Content-Type': 'application/json',
      ...?headers,
    },
    context: {sessionContextKey: testSession},
  );
}
