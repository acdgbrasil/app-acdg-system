import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'package:social_care_web/src/auth/oidc_server_client.dart';
import 'package:social_care_web/src/config/server_config.dart';

class MockHttpClient extends http.BaseClient {
  http.Response Function(http.Request) handler = (_) => http.Response('', 200);
  http.Request? lastRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request as http.Request;
    final response = handler(request);
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

void main() {
  group('OidcServerClient', () {
    late MockHttpClient mockClient;
    late OidcServerClient oidcClient;
    late ServerConfig config;

    setUp(() {
      mockClient = MockHttpClient();
      config = _testConfig();
      oidcClient = OidcServerClient(config: config, httpClient: mockClient);
    });

    group('buildAuthorizationUrl', () {
      test('includes correct query params', () {
        const state = 'random-state-123';
        const codeVerifier = 'test-code-verifier-value';

        final url = oidcClient.buildAuthorizationUrl(
          state: state,
          codeVerifier: codeVerifier,
        );

        expect(url.scheme, equals('https'));
        expect(url.host, equals('auth.example.com'));
        expect(url.path, equals('/oauth/v2/authorize'));
        expect(url.queryParameters['client_id'], equals('test-client-id'));
        expect(
          url.queryParameters['redirect_uri'],
          equals('https://bff.example.com/auth/callback'),
        );
        expect(url.queryParameters['response_type'], equals('code'));
        expect(url.queryParameters['scope'], contains('openid'));
        expect(url.queryParameters['state'], equals(state));
        expect(url.queryParameters['code_challenge_method'], equals('S256'));
      });

      test('code_challenge is S256 hash of code_verifier', () {
        const codeVerifier = 'test-code-verifier-value';
        final expectedChallenge = base64Url
            .encode(sha256.convert(utf8.encode(codeVerifier)).bytes)
            .replaceAll('=', '');

        final url = oidcClient.buildAuthorizationUrl(
          state: 'state',
          codeVerifier: codeVerifier,
        );

        expect(
          url.queryParameters['code_challenge'],
          equals(expectedChallenge),
        );
      });
    });

    group('exchangeCode', () {
      test(
        'sends correct POST body to token endpoint with client_secret',
        () async {
          mockClient.handler = (_) => http.Response(
            jsonEncode({
              'access_token': 'new-access',
              'refresh_token': 'new-refresh',
              'id_token': 'new-id-token',
              'expires_in': 3600,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );

          await oidcClient.exchangeCode(
            'auth-code-123',
            codeVerifier: 'my-verifier',
          );

          final request = mockClient.lastRequest!;
          expect(request.method, equals('POST'));
          expect(
            request.url.toString(),
            equals('https://auth.example.com/oauth/v2/token'),
          );

          final body = Uri.splitQueryString(request.body);
          expect(body['grant_type'], equals('authorization_code'));
          expect(body['code'], equals('auth-code-123'));
          expect(
            body['redirect_uri'],
            equals('https://bff.example.com/auth/callback'),
          );
          expect(body['client_id'], equals('test-client-id'));
          expect(body['client_secret'], equals('test-client-secret'));
          expect(body['code_verifier'], equals('my-verifier'));
        },
      );

      test('returns TokenResponse from successful response', () async {
        mockClient.handler = (_) => http.Response(
          jsonEncode({
            'access_token': 'access-token-xyz',
            'refresh_token': 'refresh-token-xyz',
            'id_token': 'id-token-xyz',
            'expires_in': 7200,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );

        final result = await oidcClient.exchangeCode(
          'auth-code',
          codeVerifier: 'verifier',
        );

        expect(result.accessToken, equals('access-token-xyz'));
        expect(result.refreshToken, equals('refresh-token-xyz'));
        expect(result.idToken, equals('id-token-xyz'));
        expect(result.expiresIn, equals(7200));
      });

      test('throws on error response (e.g., invalid_grant)', () async {
        mockClient.handler = (_) => http.Response(
          jsonEncode({
            'error': 'invalid_grant',
            'error_description': 'The authorization code has expired',
          }),
          400,
          headers: {'content-type': 'application/json'},
        );

        expect(
          () =>
              oidcClient.exchangeCode('expired-code', codeVerifier: 'verifier'),
          throwsA(isA<OidcException>()),
        );
      });
    });

    group('refreshToken', () {
      test('sends correct POST body with grant_type=refresh_token', () async {
        mockClient.handler = (_) => http.Response(
          jsonEncode({
            'access_token': 'refreshed-access',
            'refresh_token': 'refreshed-refresh',
            'id_token': 'refreshed-id',
            'expires_in': 3600,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );

        await oidcClient.refreshToken('old-refresh-token');

        final request = mockClient.lastRequest!;
        expect(request.method, equals('POST'));
        expect(
          request.url.toString(),
          equals('https://auth.example.com/oauth/v2/token'),
        );

        final body = Uri.splitQueryString(request.body);
        expect(body['grant_type'], equals('refresh_token'));
        expect(body['refresh_token'], equals('old-refresh-token'));
        expect(body['client_id'], equals('test-client-id'));
        expect(body['client_secret'], equals('test-client-secret'));
      });

      test('returns TokenResponse from successful refresh', () async {
        mockClient.handler = (_) => http.Response(
          jsonEncode({
            'access_token': 'refreshed-access',
            'refresh_token': 'refreshed-refresh',
            'id_token': 'refreshed-id',
            'expires_in': 1800,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );

        final result = await oidcClient.refreshToken('old-refresh');

        expect(result.accessToken, equals('refreshed-access'));
        expect(result.refreshToken, equals('refreshed-refresh'));
        expect(result.idToken, equals('refreshed-id'));
        expect(result.expiresIn, equals(1800));
      });

      test('throws on error response', () async {
        mockClient.handler = (_) => http.Response(
          jsonEncode({
            'error': 'invalid_grant',
            'error_description': 'Token has been revoked',
          }),
          400,
          headers: {'content-type': 'application/json'},
        );

        expect(
          () => oidcClient.refreshToken('revoked-token'),
          throwsA(isA<OidcException>()),
        );
      });
    });

    group('revokeToken', () {
      test('sends POST to revocation endpoint', () async {
        mockClient.handler = (_) => http.Response('', 200);

        await oidcClient.revokeToken('token-to-revoke');

        final request = mockClient.lastRequest!;
        expect(request.method, equals('POST'));
        expect(
          request.url.toString(),
          equals('https://auth.example.com/oauth/v2/revoke'),
        );

        final body = Uri.splitQueryString(request.body);
        expect(body['token'], equals('token-to-revoke'));
        expect(body['client_id'], equals('test-client-id'));
        expect(body['client_secret'], equals('test-client-secret'));
      });

      test('does not throw on successful revocation', () async {
        mockClient.handler = (_) => http.Response('', 200);

        await expectLater(oidcClient.revokeToken('some-token'), completes);
      });
    });

    group('parseIdTokenClaims', () {
      test('decodes JWT payload correctly', () {
        final payload = {
          'sub': 'user-id-123',
          'email': 'test@example.com',
          'urn:zitadel:iam:org:project:roles': {
            'social_worker': {'org-id': 'org-1'},
          },
          'iat': 1700000000,
          'exp': 1700003600,
        };

        // Build a fake JWT: header.payload.signature
        final header = base64Url
            .encode(utf8.encode(jsonEncode({'alg': 'RS256', 'typ': 'JWT'})))
            .replaceAll('=', '');
        final payloadEncoded = base64Url
            .encode(utf8.encode(jsonEncode(payload)))
            .replaceAll('=', '');
        final fakeJwt = '$header.$payloadEncoded.fake-signature';

        final claims = oidcClient.parseIdTokenClaims(fakeJwt);

        expect(claims['sub'], equals('user-id-123'));
        expect(claims['email'], equals('test@example.com'));
        expect(claims['urn:zitadel:iam:org:project:roles'], isA<Map>());
        expect(
          (claims['urn:zitadel:iam:org:project:roles'] as Map).containsKey(
            'social_worker',
          ),
          isTrue,
        );
      });
    });
  });
}
