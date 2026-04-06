import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/auth/session_store.dart';
import 'package:social_care_web/src/middleware/session_middleware.dart';

void main() {
  late SessionStore store;
  late DateTime currentTime;
  late String validSessionId;
  late String expiredSessionId;

  setUp(() {
    currentTime = DateTime.utc(2026, 1, 1, 12, 0);
    store = SessionStore(
      ttl: const Duration(hours: 1),
      clock: () => currentTime,
    );

    validSessionId = store.create(
      accessToken: 'access-valid',
      refreshToken: 'refresh-valid',
      userId: 'user-1',
      roles: {'social_worker'},
    );

    // Create a session, then advance clock past expiration
    expiredSessionId = store.create(
      accessToken: 'access-expired',
      refreshToken: 'refresh-expired',
      userId: 'user-expired',
      roles: {'admin'},
    );
  });

  Request makeRequest({Map<String, String>? headers}) {
    return Request(
      'GET',
      Uri.parse('http://localhost/test'),
      headers: headers,
    );
  }

  group('SessionMiddleware', () {
    test('request without Cookie header passes through with no session in context', () async {
      Session? capturedSession;
      final handler = const Pipeline()
          .addMiddleware(sessionMiddleware(store))
          .addHandler((request) {
        capturedSession = request.context[sessionContextKey] as Session?;
        return Response.ok('ok');
      });

      final response = await handler(makeRequest());

      expect(response.statusCode, equals(200));
      expect(capturedSession, isNull);
    });

    test('request with valid __session cookie attaches session to context', () async {
      Session? capturedSession;
      final handler = const Pipeline()
          .addMiddleware(sessionMiddleware(store))
          .addHandler((request) {
        capturedSession = request.context[sessionContextKey] as Session?;
        return Response.ok('ok');
      });

      final response = await handler(
        makeRequest(headers: {'Cookie': '__session=$validSessionId'}),
      );

      expect(response.statusCode, equals(200));
      expect(capturedSession, isNotNull);
      expect(capturedSession!.id, equals(validSessionId));
      expect(capturedSession!.userId, equals('user-1'));
      expect(capturedSession!.roles, equals({'social_worker'}));
    });

    test('request with unknown __session cookie passes through with no session', () async {
      Session? capturedSession;
      final handler = const Pipeline()
          .addMiddleware(sessionMiddleware(store))
          .addHandler((request) {
        capturedSession = request.context[sessionContextKey] as Session?;
        return Response.ok('ok');
      });

      final response = await handler(
        makeRequest(headers: {'Cookie': '__session=nonexistent-id'}),
      );

      expect(response.statusCode, equals(200));
      expect(capturedSession, isNull);
    });

    test('request with expired __session cookie passes through with no session', () async {
      // Advance clock past TTL so the session expires
      currentTime = DateTime.utc(2026, 1, 1, 13, 1);

      Session? capturedSession;
      final handler = const Pipeline()
          .addMiddleware(sessionMiddleware(store))
          .addHandler((request) {
        capturedSession = request.context[sessionContextKey] as Session?;
        return Response.ok('ok');
      });

      final response = await handler(
        makeRequest(headers: {'Cookie': '__session=$expiredSessionId'}),
      );

      expect(response.statusCode, equals(200));
      expect(capturedSession, isNull);
    });

    test('correctly parses __session from multiple cookies', () async {
      Session? capturedSession;
      final handler = const Pipeline()
          .addMiddleware(sessionMiddleware(store))
          .addHandler((request) {
        capturedSession = request.context[sessionContextKey] as Session?;
        return Response.ok('ok');
      });

      final response = await handler(
        makeRequest(headers: {
          'Cookie': 'theme=dark; __session=$validSessionId; lang=pt-BR',
        }),
      );

      expect(response.statusCode, equals(200));
      expect(capturedSession, isNotNull);
      expect(capturedSession!.id, equals(validSessionId));
    });

    test('handler receives original request headers unchanged', () async {
      String? capturedHeader;
      final handler = const Pipeline()
          .addMiddleware(sessionMiddleware(store))
          .addHandler((request) {
        capturedHeader = request.headers['x-custom'];
        return Response.ok('ok');
      });

      final response = await handler(
        makeRequest(headers: {
          'Cookie': '__session=$validSessionId',
          'X-Custom': 'my-value',
        }),
      );

      expect(response.statusCode, equals(200));
      expect(capturedHeader, equals('my-value'));
    });
  });
}
