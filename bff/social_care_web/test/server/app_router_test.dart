import 'dart:convert';

import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/auth/oidc_server_client.dart';
import 'package:social_care_web/src/auth/session_store.dart';
import 'package:social_care_web/src/config/server_config.dart';
import 'package:social_care_web/src/server/app_router.dart';

/// Fake OIDC client that returns predictable values without HTTP calls.
class _FakeOidcServerClient extends OidcServerClient {
  _FakeOidcServerClient() : super(config: _testConfig);
}

/// Fake contract factory that always returns a [FakeSocialCareBff].
FakeSocialCareBff _fakeContract(Session session) =>
    FakeSocialCareBff(delay: Duration.zero);

const _requiredEnv = {
  'API_BASE_URL': 'http://localhost:3000',
  'OIDC_ISSUER': 'https://auth.example.com',
  'OIDC_CLIENT_ID': 'test-client',
  'OIDC_CLIENT_SECRET': 'test-secret',
  'OIDC_REDIRECT_URI': 'http://localhost:8081/auth/callback',
  'SESSION_SECRET': 'super-secret-key-for-testing-only',
};

final _testConfig = ServerConfig.fromEnvironment(_requiredEnv);

void main() {
  late SessionStore sessionStore;
  late AppRouter appRouter;
  late Handler handler;

  setUp(() {
    sessionStore = SessionStore(ttl: const Duration(hours: 1));
    appRouter = AppRouter(
      config: _testConfig,
      sessionStore: sessionStore,
      oidcClient: _FakeOidcServerClient(),
      contractFactory: _fakeContract,
    );
    handler = appRouter.handler;
  });

  /// Helper to create a request with an optional session cookie.
  Request request(String method, String path, {String? sessionCookie}) {
    return Request(
      method,
      Uri.parse('http://localhost$path'),
      headers: {
        if (sessionCookie != null) 'cookie': '__session=$sessionCookie',
      },
    );
  }

  /// Creates a valid session in the store and returns its ID.
  String createSession() {
    return sessionStore.create(
      accessToken: 'test-access-token',
      refreshToken: 'test-refresh-token',
      userId: 'test-user-id',
      roles: {'social_worker'},
    );
  }

  group('AppRouter', () {
    group('health endpoints (public)', () {
      test('GET /health/live returns 200 without auth', () async {
        final response = await handler(request('GET', '/health/live'));

        expect(response.statusCode, equals(200));
        final body = jsonDecode(await response.readAsString());
        expect(body['status'], equals('ok'));
      });

      test('GET /health/ready returns 200 without auth', () async {
        final response = await handler(request('GET', '/health/ready'));

        expect(response.statusCode, equals(200));
        final body = jsonDecode(await response.readAsString());
        expect(body['status'], equals('ready'));
      });
    });

    group('auth endpoints (session middleware, no auth guard)', () {
      test('GET /auth/login returns 302 redirect without session', () async {
        final response = await handler(request('GET', '/auth/login'));

        expect(response.statusCode, equals(302));
        final location = response.headers['location']!;
        expect(location, contains('authorize'));
        expect(location, contains('client_id=test-client'));
      });

      test('GET /auth/me returns 401 without session', () async {
        final response = await handler(request('GET', '/auth/me'));

        expect(response.statusCode, equals(401));
        final body = jsonDecode(await response.readAsString());
        expect(body['error'], contains('session'));
      });

      test('GET /auth/me returns 200 with valid session', () async {
        final sessionId = createSession();
        final response = await handler(
          request('GET', '/auth/me', sessionCookie: sessionId),
        );

        expect(response.statusCode, equals(200));
        final body = jsonDecode(await response.readAsString());
        expect(body['userId'], equals('test-user-id'));
      });
    });

    group('patient endpoints (protected)', () {
      test('GET /patients returns 401 without session', () async {
        final response = await handler(request('GET', '/patients'));

        expect(response.statusCode, equals(401));
        final body = jsonDecode(await response.readAsString());
        expect(body['error'], equals('Unauthorized'));
      });

      test('GET /patients returns 200 with valid session', () async {
        final sessionId = createSession();
        final response = await handler(
          request('GET', '/patients', sessionCookie: sessionId),
        );

        expect(response.statusCode, equals(200));
      });
    });

    group('lookup endpoints (protected)', () {
      test('GET /lookups/gender returns 401 without session', () async {
        final response = await handler(request('GET', '/lookups/gender'));

        expect(response.statusCode, equals(401));
      });

      test('GET /lookups/gender returns 200 with valid session', () async {
        final sessionId = createSession();
        final response = await handler(
          request('GET', '/lookups/gender', sessionCookie: sessionId),
        );

        expect(response.statusCode, equals(200));
      });
    });

    group('unknown routes', () {
      test('GET /unknown without session returns 401', () async {
        // Auth guard blocks before route matching for unauthenticated users,
        // which avoids revealing route existence to unauthenticated clients.
        final response = await handler(request('GET', '/unknown'));

        expect(response.statusCode, equals(401));
      });

      test('GET /unknown with session returns 404', () async {
        final sessionId = createSession();
        final response = await handler(
          request('GET', '/unknown', sessionCookie: sessionId),
        );

        expect(response.statusCode, equals(404));
      });
    });
  });
}
