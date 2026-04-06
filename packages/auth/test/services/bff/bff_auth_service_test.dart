import 'dart:async';
import 'dart:convert';

import 'package:auth/auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class MockHttpClient extends http.BaseClient {
  http.Response Function(http.BaseRequest) handler = (_) =>
      http.Response('', 200);
  http.BaseRequest? lastRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request;
    final response = handler(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
    );
  }
}

void main() {
  late MockHttpClient mockClient;
  late BffAuthService service;

  const baseUrl = 'http://localhost:8081';
  const config = BffAuthConfig(bffBaseUrl: baseUrl);

  setUp(() {
    mockClient = MockHttpClient();
    service = BffAuthService(config: config, httpClient: mockClient);
  });

  tearDown(() {
    service.dispose();
  });

  group('init', () {
    test('sets status to Unauthenticated', () async {
      await service.init();
      expect(service.currentStatus, isA<Unauthenticated>());
    });

    test('is idempotent — calling twice does not change state', () async {
      await service.init();
      expect(service.currentStatus, isA<Unauthenticated>());

      // Calling init again should be a no-op
      await service.init();
      expect(service.currentStatus, isA<Unauthenticated>());
    });
  });

  group('loginUrl', () {
    test('returns correct BFF auth login URL', () {
      expect(service.loginUrl, '$baseUrl/auth/login');
    });
  });

  group('tryRestoreSession', () {
    test('with 200 response sets Authenticated status', () async {
      await service.init();

      mockClient.handler = (_) => http.Response(
        jsonEncode({
          'userId': 'user-123',
          'roles': ['social_worker', 'admin'],
        }),
        200,
      );

      await service.tryRestoreSession();
      expect(service.currentStatus, isA<Authenticated>());
    });

    test(
      'with 200 response populates currentUser with userId and roles',
      () async {
        await service.init();

        mockClient.handler = (_) => http.Response(
          jsonEncode({
            'userId': 'user-456',
            'roles': ['owner'],
          }),
          200,
        );

        await service.tryRestoreSession();

        final user = service.currentUser;
        expect(user, isNotNull);
        expect(user!.id, 'user-456');
        expect(user.roles, {AuthRole.owner});
      },
    );

    test('with 401 response sets Unauthenticated', () async {
      await service.init();

      mockClient.handler = (_) => http.Response('', 401);

      await service.tryRestoreSession();
      expect(service.currentStatus, isA<Unauthenticated>());
      expect(service.currentUser, isNull);
    });

    test('with network error sets Unauthenticated', () async {
      await service.init();

      mockClient.handler = (_) => throw Exception('network error');

      await service.tryRestoreSession();
      expect(service.currentStatus, isA<Unauthenticated>());
      expect(service.currentUser, isNull);
    });
  });

  group('logout', () {
    test('calls POST /auth/logout', () async {
      await service.init();

      await service.logout();

      expect(mockClient.lastRequest, isNotNull);
      expect(mockClient.lastRequest!.method, 'POST');
      expect(mockClient.lastRequest!.url.toString(), '$baseUrl/auth/logout');
    });

    test('sets Unauthenticated status', () async {
      await service.init();

      // First, set up an authenticated session
      mockClient.handler = (_) => http.Response(
        jsonEncode({
          'userId': 'user-123',
          'roles': ['social_worker'],
        }),
        200,
      );
      await service.tryRestoreSession();
      expect(service.currentStatus, isA<Authenticated>());

      // Now logout
      mockClient.handler = (_) => http.Response('', 200);
      await service.logout();
      expect(service.currentStatus, isA<Unauthenticated>());
    });

    test('clears currentUser', () async {
      await service.init();

      // Set up authenticated session
      mockClient.handler = (_) => http.Response(
        jsonEncode({
          'userId': 'user-123',
          'roles': ['social_worker'],
        }),
        200,
      );
      await service.tryRestoreSession();
      expect(service.currentUser, isNotNull);

      // Logout
      mockClient.handler = (_) => http.Response('', 200);
      await service.logout();
      expect(service.currentUser, isNull);
    });
  });

  group('refreshToken', () {
    test('calls POST /auth/refresh', () async {
      await service.init();

      await service.refreshToken();

      expect(mockClient.lastRequest, isNotNull);
      expect(mockClient.lastRequest!.method, 'POST');
      expect(mockClient.lastRequest!.url.toString(), '$baseUrl/auth/refresh');
    });

    test('on error sets Unauthenticated', () async {
      await service.init();

      // First authenticate
      mockClient.handler = (_) => http.Response(
        jsonEncode({
          'userId': 'user-123',
          'roles': ['social_worker'],
        }),
        200,
      );
      await service.tryRestoreSession();
      expect(service.currentStatus, isA<Authenticated>());

      // Refresh fails
      mockClient.handler = (_) => http.Response('', 500);
      await service.refreshToken();
      expect(service.currentStatus, isA<Unauthenticated>());
    });
  });

  group('currentToken', () {
    test('is always null — tokens managed server-side', () async {
      await service.init();

      // Even after authenticating
      mockClient.handler = (_) => http.Response(
        jsonEncode({
          'userId': 'user-123',
          'roles': ['social_worker'],
        }),
        200,
      );
      await service.tryRestoreSession();
      expect(service.currentToken, isNull);
    });
  });

  group('statusStream', () {
    test('emits status changes', () async {
      await service.init();

      mockClient.handler = (_) => http.Response(
        jsonEncode({
          'userId': 'user-123',
          'roles': ['social_worker'],
        }),
        200,
      );

      // Listen after init so we capture only the tryRestoreSession emission
      final future = expectLater(
        service.statusStream,
        emits(isA<Authenticated>()),
      );

      await service.tryRestoreSession();
      await future;
    });
  });

  group('dispose', () {
    test('closes statusController', () async {
      await service.init();
      service.dispose();

      // After dispose, adding to the stream should fail or the stream should be done.
      expectLater(service.statusStream, emitsDone);
    });
  });
}
