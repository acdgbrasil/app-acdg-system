import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/auth/oidc_server_client.dart';
import 'package:social_care_web/src/auth/session_store.dart';
import 'package:social_care_web/src/config/server_config.dart';
import 'package:social_care_web/src/handlers/auth_handler.dart';
import 'package:social_care_web/src/middleware/session_middleware.dart';

class MockHttpClient extends http.BaseClient {
  http.Response Function(http.Request) handler = (_) => http.Response('', 200);
  http.Request? lastRequest;
  final List<http.Request> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request as http.Request;
    requests.add(lastRequest!);
    final response = handler(lastRequest!);
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
    );
  }
}

ServerConfig _testConfig() {
  return const ServerConfig(
    port: 8081,
    host: '0.0.0.0',
    apiBaseUrl: 'https://api.example.com',
    oidcIssuer: 'https://auth.example.com',
    oidcClientId: 'test-client-id',
    oidcClientSecret: 'test-client-secret',
    oidcRedirectUri: 'https://bff.example.com/auth/callback',
    sessionSecret: 'super-secret-key',
  );
}

/// Builds a fake JWT with the given payload claims.
String _buildFakeJwt(Map<String, dynamic> payload) {
  final header = base64Url
      .encode(utf8.encode(jsonEncode({'alg': 'RS256', 'typ': 'JWT'})))
      .replaceAll('=', '');
  final payloadEncoded = base64Url
      .encode(utf8.encode(jsonEncode(payload)))
      .replaceAll('=', '');
  return '$header.$payloadEncoded.fake-signature';
}

/// Returns a mock handler that responds to token exchange requests
/// with a successful token response including a fake ID token.
http.Response Function(http.Request) _tokenExchangeHandler({
  String userId = 'user-123',
  Map<String, dynamic> roles = const {
    'social_worker': {'org-id': 'org-1'},
  },
}) {
  return (_) {
    final idToken = _buildFakeJwt({
      'sub': userId,
      'urn:zitadel:iam:org:project:roles': roles,
    });
    return http.Response(
      jsonEncode({
        'access_token': 'access-token-abc',
        'refresh_token': 'refresh-token-abc',
        'id_token': idToken,
        'expires_in': 3600,
      }),
      200,
      headers: {'content-type': 'application/json'},
    );
  };
}

void main() {
  group('AuthHandler', () {
    late MockHttpClient mockHttpClient;
    late SessionStore sessionStore;
    late OidcServerClient oidcClient;
    late AuthHandler authHandler;
    late Handler pipeline;

    setUp(() {
      mockHttpClient = MockHttpClient();
      sessionStore = SessionStore(ttl: const Duration(hours: 1));
      oidcClient = OidcServerClient(
        config: _testConfig(),
        httpClient: mockHttpClient,
      );
      authHandler = AuthHandler(
        oidcClient: oidcClient,
        sessionStore: sessionStore,
      );
      pipeline = const Pipeline()
          .addMiddleware(sessionMiddleware(sessionStore))
          .addHandler(authHandler.router.call);
    });

    group('GET /auth/login', () {
      test('returns 302 redirect to Zitadel', () async {
        final request = Request(
          'GET',
          Uri.parse('http://localhost/auth/login'),
        );

        final response = await pipeline(request);

        expect(response.statusCode, equals(302));
        expect(response.headers.containsKey('location'), isTrue);

        final location = Uri.parse(response.headers['location']!);
        expect(location.host, equals('auth.example.com'));
        expect(location.path, equals('/oauth/v2/authorize'));
      });

      test('redirect URL contains correct query params', () async {
        final request = Request(
          'GET',
          Uri.parse('http://localhost/auth/login'),
        );

        final response = await pipeline(request);

        final location = Uri.parse(response.headers['location']!);
        expect(location.queryParameters['client_id'], equals('test-client-id'));
        expect(
          location.queryParameters['redirect_uri'],
          equals('https://bff.example.com/auth/callback'),
        );
        expect(location.queryParameters['response_type'], equals('code'));
        expect(location.queryParameters['scope'], contains('openid'));
        expect(location.queryParameters['state'], isNotEmpty);
        expect(location.queryParameters['code_challenge'], isNotEmpty);
        expect(
          location.queryParameters['code_challenge_method'],
          equals('S256'),
        );
      });
    });

    group('GET /auth/callback', () {
      test('with valid code creates session and sets cookie', () async {
        // First, do login to get state
        final loginRequest = Request(
          'GET',
          Uri.parse('http://localhost/auth/login'),
        );
        final loginResponse = await pipeline(loginRequest);
        final location = Uri.parse(loginResponse.headers['location']!);
        final state = location.queryParameters['state']!;

        // Mock token exchange
        mockHttpClient.handler = _tokenExchangeHandler();

        // Simulate callback from Zitadel
        final callbackRequest = Request(
          'GET',
          Uri.parse(
            'http://localhost/auth/callback?code=auth-code-123&state=$state',
          ),
        );
        final callbackResponse = await pipeline(callbackRequest);

        expect(callbackResponse.statusCode, equals(302));
        expect(callbackResponse.headers['location'], equals('/'));

        final setCookie = callbackResponse.headers['set-cookie']!;
        expect(setCookie, contains('__session='));
      });

      test('cookie has HttpOnly, Secure, SameSite=Strict flags', () async {
        // Login to get state
        final loginRequest = Request(
          'GET',
          Uri.parse('http://localhost/auth/login'),
        );
        final loginResponse = await pipeline(loginRequest);
        final location = Uri.parse(loginResponse.headers['location']!);
        final state = location.queryParameters['state']!;

        mockHttpClient.handler = _tokenExchangeHandler();

        final callbackRequest = Request(
          'GET',
          Uri.parse(
            'http://localhost/auth/callback?code=auth-code-123&state=$state',
          ),
        );
        final callbackResponse = await pipeline(callbackRequest);

        final setCookie = callbackResponse.headers['set-cookie']!;
        expect(setCookie.toLowerCase(), contains('httponly'));
        expect(setCookie.toLowerCase(), contains('secure'));
        expect(setCookie.toLowerCase(), contains('samesite=strict'));
        expect(setCookie.toLowerCase(), contains('path=/'));
      });

      test('redirects to /', () async {
        final loginRequest = Request(
          'GET',
          Uri.parse('http://localhost/auth/login'),
        );
        final loginResponse = await pipeline(loginRequest);
        final location = Uri.parse(loginResponse.headers['location']!);
        final state = location.queryParameters['state']!;

        mockHttpClient.handler = _tokenExchangeHandler();

        final callbackRequest = Request(
          'GET',
          Uri.parse(
            'http://localhost/auth/callback?code=code-xyz&state=$state',
          ),
        );
        final callbackResponse = await pipeline(callbackRequest);

        expect(callbackResponse.headers['location'], equals('/'));
      });

      test('with missing code returns 400', () async {
        final callbackRequest = Request(
          'GET',
          Uri.parse('http://localhost/auth/callback?state=some-state'),
        );
        final callbackResponse = await pipeline(callbackRequest);

        expect(callbackResponse.statusCode, equals(400));
      });

      test('with invalid state returns 400', () async {
        final callbackRequest = Request(
          'GET',
          Uri.parse(
            'http://localhost/auth/callback?code=code-123&state=invalid-state',
          ),
        );
        final callbackResponse = await pipeline(callbackRequest);

        expect(callbackResponse.statusCode, equals(400));
      });
    });

    group('POST /auth/logout', () {
      test('destroys session and clears cookie', () async {
        // Setup: login + callback to create session
        final loginRequest = Request(
          'GET',
          Uri.parse('http://localhost/auth/login'),
        );
        final loginResponse = await pipeline(loginRequest);
        final location = Uri.parse(loginResponse.headers['location']!);
        final state = location.queryParameters['state']!;

        mockHttpClient.handler = _tokenExchangeHandler();

        final callbackRequest = Request(
          'GET',
          Uri.parse('http://localhost/auth/callback?code=code&state=$state'),
        );
        final callbackResponse = await pipeline(callbackRequest);
        final setCookie = callbackResponse.headers['set-cookie']!;
        final sessionCookie = RegExp(
          r'__session=([^;]+)',
        ).firstMatch(setCookie)!.group(1)!;

        // Reset mock to handle revocation
        mockHttpClient.handler = (_) => http.Response('', 200);

        final logoutRequest = Request(
          'POST',
          Uri.parse('http://localhost/auth/logout'),
          headers: {'Cookie': '__session=$sessionCookie'},
        );
        final logoutResponse = await pipeline(logoutRequest);

        expect(logoutResponse.statusCode, equals(200));

        // Cookie should be cleared (Max-Age=0 or expired)
        final clearCookie = logoutResponse.headers['set-cookie']!;
        expect(clearCookie, contains('__session='));
        expect(clearCookie.toLowerCase(), contains('max-age=0'));

        // Session should be destroyed - verify with /auth/me
        final meRequest = Request(
          'GET',
          Uri.parse('http://localhost/auth/me'),
          headers: {'Cookie': '__session=$sessionCookie'},
        );
        final meResponse = await pipeline(meRequest);
        expect(meResponse.statusCode, equals(401));
      });
    });

    group('GET /auth/me', () {
      test('with valid session returns user info JSON', () async {
        // Setup session via login flow
        final loginRequest = Request(
          'GET',
          Uri.parse('http://localhost/auth/login'),
        );
        final loginResponse = await pipeline(loginRequest);
        final location = Uri.parse(loginResponse.headers['location']!);
        final state = location.queryParameters['state']!;

        mockHttpClient.handler = _tokenExchangeHandler(
          userId: 'user-456',
          roles: {
            'social_worker': {'org-id': 'org-1'},
            'admin': {'org-id': 'org-1'},
          },
        );

        final callbackRequest = Request(
          'GET',
          Uri.parse('http://localhost/auth/callback?code=code&state=$state'),
        );
        final callbackResponse = await pipeline(callbackRequest);
        final setCookie = callbackResponse.headers['set-cookie']!;
        final sessionCookie = RegExp(
          r'__session=([^;]+)',
        ).firstMatch(setCookie)!.group(1)!;

        final meRequest = Request(
          'GET',
          Uri.parse('http://localhost/auth/me'),
          headers: {'Cookie': '__session=$sessionCookie'},
        );
        final meResponse = await pipeline(meRequest);

        expect(meResponse.statusCode, equals(200));

        final body = jsonDecode(await meResponse.readAsString());
        expect(body['userId'], equals('user-456'));
        expect(body['roles'], containsAll(['social_worker', 'admin']));
      });

      test('without session returns 401', () async {
        final meRequest = Request('GET', Uri.parse('http://localhost/auth/me'));
        final meResponse = await pipeline(meRequest);

        expect(meResponse.statusCode, equals(401));
      });
    });

    group('POST /auth/refresh', () {
      test('updates tokens in session', () async {
        // Setup session via login flow
        final loginRequest = Request(
          'GET',
          Uri.parse('http://localhost/auth/login'),
        );
        final loginResponse = await pipeline(loginRequest);
        final location = Uri.parse(loginResponse.headers['location']!);
        final state = location.queryParameters['state']!;

        mockHttpClient.handler = _tokenExchangeHandler();

        final callbackRequest = Request(
          'GET',
          Uri.parse('http://localhost/auth/callback?code=code&state=$state'),
        );
        final callbackResponse = await pipeline(callbackRequest);
        final setCookie = callbackResponse.headers['set-cookie']!;
        final sessionCookie = RegExp(
          r'__session=([^;]+)',
        ).firstMatch(setCookie)!.group(1)!;

        // Mock refresh response
        mockHttpClient.handler = (_) => http.Response(
          jsonEncode({
            'access_token': 'refreshed-access',
            'refresh_token': 'refreshed-refresh',
            'id_token': _buildFakeJwt({'sub': 'user-123'}),
            'expires_in': 3600,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );

        final refreshRequest = Request(
          'POST',
          Uri.parse('http://localhost/auth/refresh'),
          headers: {'Cookie': '__session=$sessionCookie'},
        );
        final refreshResponse = await pipeline(refreshRequest);

        expect(refreshResponse.statusCode, equals(200));

        // Verify tokens were updated by checking /auth/me still works
        final meRequest = Request(
          'GET',
          Uri.parse('http://localhost/auth/me'),
          headers: {'Cookie': '__session=$sessionCookie'},
        );
        final meResponse = await pipeline(meRequest);
        expect(meResponse.statusCode, equals(200));
      });

      test('without session returns 401', () async {
        final refreshRequest = Request(
          'POST',
          Uri.parse('http://localhost/auth/refresh'),
        );
        final refreshResponse = await pipeline(refreshRequest);

        expect(refreshResponse.statusCode, equals(401));
      });

      test('returns 409 when session update fails', () async {
        // Scenario: OIDC refresh succeeds but sessionStore.updateTokens
        // returns false (e.g., session was destroyed concurrently).
        // The handler must not return 200 in this case.

        // Create session directly in the store to control the ID
        final sessionId = sessionStore.create(
          accessToken: 'old-access',
          refreshToken: 'old-refresh',
          userId: 'user-123',
          roles: {'social_worker'},
        );

        // Mock OIDC refresh succeeds
        mockHttpClient.handler = (_) => http.Response(
          jsonEncode({
            'access_token': 'refreshed-access',
            'refresh_token': 'refreshed-refresh',
            'id_token': _buildFakeJwt({'sub': 'user-123'}),
            'expires_in': 3600,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );

        // Destroy the session AFTER the middleware reads it but BEFORE
        // updateTokens runs. We simulate this by providing the session
        // in request context directly (bypassing middleware) and
        // destroying it in the store before calling refresh.
        final session = sessionStore.get(sessionId)!;
        sessionStore.destroy(sessionId);

        final refreshRequest = Request(
          'POST',
          Uri.parse('http://localhost/auth/refresh'),
          context: {sessionContextKey: session},
        );
        final refreshResponse = await authHandler.router.call(refreshRequest);

        // Should be 409 (conflict) — not 200
        expect(refreshResponse.statusCode, equals(409));
      });
    });
  });
}
