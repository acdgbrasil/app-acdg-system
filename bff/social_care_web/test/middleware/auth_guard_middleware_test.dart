import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/auth/session_store.dart';
import 'package:social_care_web/src/middleware/auth_guard_middleware.dart';
import 'package:social_care_web/src/middleware/session_middleware.dart';

void main() {
  late SessionStore store;
  late DateTime currentTime;
  late String validSessionId;

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
  });

  Request makeRequest({Map<String, String>? headers}) {
    return Request('GET', Uri.parse('http://localhost/test'), headers: headers);
  }

  group('AuthGuardMiddleware', () {
    test('request with valid session passes through to handler', () async {
      final handler = const Pipeline()
          .addMiddleware(sessionMiddleware(store))
          .addMiddleware(authGuardMiddleware())
          .addHandler((request) {
            final session = request.context[sessionContextKey] as Session;
            return Response.ok('hello ${session.userId}');
          });

      final response = await handler(
        makeRequest(headers: {'Cookie': '__session=$validSessionId'}),
      );

      expect(response.statusCode, equals(200));
      expect(await response.readAsString(), equals('hello user-1'));
    });

    test('request without session returns 401 JSON response', () async {
      final handler = const Pipeline()
          .addMiddleware(sessionMiddleware(store))
          .addMiddleware(authGuardMiddleware())
          .addHandler((request) {
            return Response.ok('should not reach');
          });

      final response = await handler(makeRequest());

      expect(response.statusCode, equals(401));
      expect(response.headers['content-type'], equals('application/json'));
    });

    test('401 response body contains error and message fields', () async {
      final handler = const Pipeline()
          .addMiddleware(sessionMiddleware(store))
          .addMiddleware(authGuardMiddleware())
          .addHandler((request) {
            return Response.ok('should not reach');
          });

      final response = await handler(makeRequest());
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;

      expect(body, containsPair('error', 'Unauthorized'));
      expect(body, containsPair('message', 'Valid session required'));
    });

    test('request with invalid session cookie returns 401', () async {
      final handler = const Pipeline()
          .addMiddleware(sessionMiddleware(store))
          .addMiddleware(authGuardMiddleware())
          .addHandler((request) {
            return Response.ok('should not reach');
          });

      final response = await handler(
        makeRequest(headers: {'Cookie': '__session=bad-id'}),
      );

      expect(response.statusCode, equals(401));
    });

    test(
      'handler response is returned unchanged when session is valid',
      () async {
        final handler = const Pipeline()
            .addMiddleware(sessionMiddleware(store))
            .addMiddleware(authGuardMiddleware())
            .addHandler((request) {
              return Response(
                201,
                body: 'created',
                headers: {'x-custom': 'value'},
              );
            });

        final response = await handler(
          makeRequest(headers: {'Cookie': '__session=$validSessionId'}),
        );

        expect(response.statusCode, equals(201));
        expect(await response.readAsString(), equals('created'));
        expect(response.headers['x-custom'], equals('value'));
      },
    );
  });
}
