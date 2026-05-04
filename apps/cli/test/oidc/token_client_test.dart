/// W0 RED — TokenClient contract (C02 §5.8 + §5.9).
///
/// W1 must create `apps/cli/lib/src/oidc/token_client.dart` with:
///
/// ```dart
/// final class TokenResponse with Equatable {
///   const TokenResponse({
///     required this.accessToken,
///     required this.refreshToken,
///     required this.idToken,
///     required this.tokenType,
///     required this.expiresIn,
///   });
///   final String accessToken;
///   final String refreshToken;
///   final String idToken;
///   final String tokenType;
///   final Duration expiresIn;
/// }
///
/// /// NOT `final class` — command-level orchestration tests
/// /// `implements TokenClient` to inject canned exchange/refresh Results.
/// class TokenClient {
///   TokenClient({required OidcDiscovery discovery, required http.Client httpClient})
///       : _discovery = discovery, _httpClient = httpClient;
///
///   final OidcDiscovery _discovery;       // private — fakes don't need to expose
///   final http.Client _httpClient;        // private — fakes don't need to expose
///
///   OidcDiscovery get discovery => _discovery; // public read
///
///   Future<Result<TokenResponse>> exchangeCode({
///     required String code,
///     required String codeVerifier,
///     required String redirectUri,
///     String clientId = OidcConfig.clientId,
///   });
///
///   Future<Result<TokenResponse>> refresh({
///     required String refreshToken,
///     String clientId = OidcConfig.clientId,
///     String scopes = OidcConfig.scopes,
///   });
/// }
/// ```
///
/// CliError extension — `RefreshTokenInvalidError` (sealed family member):
///
/// ```dart
/// final class RefreshTokenInvalidError extends CliError {
///   const RefreshTokenInvalidError([String? detail])
///       : super('Refresh token rotated/revoked. Run: acdg auth login');
/// }
/// ```
///
/// This file MUST also pin two non-negotiable behaviors:
///   * NEVER include `client_secret` in the form body (PKCE-only).
///   * `error: invalid_grant` AND description containing `RefreshTokenInvalid`
///     in the 400 response body MUST surface as `RefreshTokenInvalidError`.
library;

import 'dart:convert';

import 'package:core_contracts/core_contracts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_test;
import 'package:test/test.dart';

import 'package:cli/src/errors/cli_error.dart';
import 'package:cli/src/oidc/oidc_discovery.dart';
import 'package:cli/src/oidc/token_client.dart';

void main() {
  final discovery = const OidcDiscovery(
    issuer: 'https://auth.acdgbrasil.com.br',
    authorizationEndpoint: 'https://auth.acdgbrasil.com.br/oauth/v2/authorize',
    tokenEndpoint: 'https://auth.acdgbrasil.com.br/oauth/v2/token',
    jwksUri: 'https://auth.acdgbrasil.com.br/oauth/v2/keys',
    userinfoEndpoint: 'https://auth.acdgbrasil.com.br/oidc/v1/userinfo',
    endSessionEndpoint: 'https://auth.acdgbrasil.com.br/oidc/v1/end_session',
    revocationEndpoint: 'https://auth.acdgbrasil.com.br/oauth/v2/revoke',
    deviceAuthorizationEndpoint:
        'https://auth.acdgbrasil.com.br/oauth/v2/device_authorization',
  );

  group('TokenClient.exchangeCode', () {
    test('200 with token JSON → Success(TokenResponse)', () async {
      final body = jsonEncode({
        'access_token': 'at-1',
        'refresh_token': 'rt-1',
        'id_token': 'it-1',
        'token_type': 'Bearer',
        'expires_in': 43200,
      });
      final client = http_test.MockClient(
        (req) async => http.Response(
          body,
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      final tokenClient = TokenClient(discovery: discovery, httpClient: client);

      final result = await tokenClient.exchangeCode(
        code: 'CODE',
        codeVerifier: 'VERIFIER',
        redirectUri: 'http://127.0.0.1:55123/callback',
      );

      expect(result, isA<Success<TokenResponse>>());
      final tokens = (result as Success<TokenResponse>).value;
      expect(tokens.accessToken, equals('at-1'));
      expect(tokens.refreshToken, equals('rt-1'));
      expect(tokens.idToken, equals('it-1'));
      expect(tokens.tokenType, equals('Bearer'));
      expect(tokens.expiresIn, equals(const Duration(seconds: 43200)));
    });

    test(
      'POSTs to discovery.tokenEndpoint with form-urlencoded body',
      () async {
        String? capturedUrl;
        String? capturedContentType;
        String? capturedBody;
        final client = http_test.MockClient((req) async {
          capturedUrl = req.url.toString();
          capturedContentType = req.headers['content-type'];
          capturedBody = req.body;
          return http.Response(
            jsonEncode({
              'access_token': 'a',
              'refresh_token': 'r',
              'id_token': 'i',
              'token_type': 'Bearer',
              'expires_in': 60,
            }),
            200,
          );
        });
        final tokenClient = TokenClient(
          discovery: discovery,
          httpClient: client,
        );

        await tokenClient.exchangeCode(
          code: 'CODE-X',
          codeVerifier: 'V-X',
          redirectUri: 'http://127.0.0.1:5555/callback',
        );

        expect(capturedUrl, equals(discovery.tokenEndpoint));
        expect(
          capturedContentType,
          anyOf(
            equals('application/x-www-form-urlencoded'),
            startsWith('application/x-www-form-urlencoded'),
          ),
        );
        // Required PKCE form fields:
        expect(capturedBody, contains('grant_type=authorization_code'));
        expect(capturedBody, contains('code=CODE-X'));
        expect(capturedBody, contains('code_verifier=V-X'));
        expect(capturedBody, contains('client_id='));
        expect(
          capturedBody,
          contains(Uri.encodeQueryComponent('http://127.0.0.1:5555/callback')),
        );
      },
    );

    test('NEVER sends client_secret (PKCE-only)', () async {
      String? capturedBody;
      final client = http_test.MockClient((req) async {
        capturedBody = req.body;
        return http.Response(
          jsonEncode({
            'access_token': 'a',
            'refresh_token': 'r',
            'id_token': 'i',
            'token_type': 'Bearer',
            'expires_in': 60,
          }),
          200,
        );
      });
      final tokenClient = TokenClient(discovery: discovery, httpClient: client);

      await tokenClient.exchangeCode(
        code: 'C',
        codeVerifier: 'V',
        redirectUri: 'http://127.0.0.1:1/callback',
      );

      expect(capturedBody, isNot(contains('client_secret')));
    });

    test('400 invalid_grant → Failure(CliError)', () async {
      final client = http_test.MockClient(
        (req) async => http.Response(
          jsonEncode({
            'error': 'invalid_grant',
            'error_description': 'Code expired or already used',
          }),
          400,
          headers: {'content-type': 'application/json'},
        ),
      );
      final tokenClient = TokenClient(discovery: discovery, httpClient: client);

      final result = await tokenClient.exchangeCode(
        code: 'STALE',
        codeVerifier: 'V',
        redirectUri: 'http://127.0.0.1:1/callback',
      );

      expect(result, isA<Failure<TokenResponse>>());
      final failure = result as Failure<TokenResponse>;
      expect(failure.error, isA<CliError>());
    });

    test('5xx → Failure(ServerError)', () async {
      final client = http_test.MockClient(
        (req) async => http.Response('boom', 503),
      );
      final tokenClient = TokenClient(discovery: discovery, httpClient: client);

      final result = await tokenClient.exchangeCode(
        code: 'C',
        codeVerifier: 'V',
        redirectUri: 'http://127.0.0.1:1/callback',
      );

      expect(result, isA<Failure<TokenResponse>>());
      final failure = result as Failure<TokenResponse>;
      // ServerError is the natural fit; but accept any CliError.
      expect(failure.error, isA<CliError>());
    });

    test('http client throws → Failure (no exception escapes)', () async {
      final client = http_test.MockClient(
        (req) async => throw const _SimulatedNetworkException(),
      );
      final tokenClient = TokenClient(discovery: discovery, httpClient: client);

      final result = await tokenClient.exchangeCode(
        code: 'C',
        codeVerifier: 'V',
        redirectUri: 'http://127.0.0.1:1/callback',
      );

      expect(result, isA<Failure<TokenResponse>>());
    });
  });

  group('TokenClient.refresh', () {
    test('200 → Success(TokenResponse) with rotated tokens', () async {
      final body = jsonEncode({
        'access_token': 'at-2',
        'refresh_token': 'rt-2',
        'id_token': 'it-2',
        'token_type': 'Bearer',
        'expires_in': 43200,
      });
      final client = http_test.MockClient(
        (req) async => http.Response(
          body,
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      final tokenClient = TokenClient(discovery: discovery, httpClient: client);

      final result = await tokenClient.refresh(refreshToken: 'rt-1');

      expect(result, isA<Success<TokenResponse>>());
      final tokens = (result as Success<TokenResponse>).value;
      expect(tokens.refreshToken, equals('rt-2'));
      expect(tokens.accessToken, equals('at-2'));
    });

    test(
      'POSTs grant_type=refresh_token + refresh_token + client_id + scope',
      () async {
        String? capturedBody;
        final client = http_test.MockClient((req) async {
          capturedBody = req.body;
          return http.Response(
            jsonEncode({
              'access_token': 'a',
              'refresh_token': 'r',
              'id_token': 'i',
              'token_type': 'Bearer',
              'expires_in': 60,
            }),
            200,
          );
        });
        final tokenClient = TokenClient(
          discovery: discovery,
          httpClient: client,
        );

        await tokenClient.refresh(refreshToken: 'rt-old');

        expect(capturedBody, contains('grant_type=refresh_token'));
        expect(capturedBody, contains('refresh_token=rt-old'));
        expect(capturedBody, contains('client_id='));
        expect(capturedBody, contains('scope='));
        expect(capturedBody, isNot(contains('client_secret')));
      },
    );

    test(
      '400 invalid_grant + RefreshTokenInvalid → Failure(RefreshTokenInvalidError)',
      () async {
        final client = http_test.MockClient(
          (req) async => http.Response(
            jsonEncode({
              'error': 'invalid_grant',
              'error_description':
                  'Errors.User.RefreshToken.RefreshTokenInvalid (was rotated)',
            }),
            400,
            headers: {'content-type': 'application/json'},
          ),
        );
        final tokenClient = TokenClient(
          discovery: discovery,
          httpClient: client,
        );

        final result = await tokenClient.refresh(refreshToken: 'rt-stale');

        expect(result, isA<Failure<TokenResponse>>());
        final failure = result as Failure<TokenResponse>;
        // CRITICAL: the exact error type matters — AuthCommand keys off it.
        expect(failure.error, isA<RefreshTokenInvalidError>());
      },
    );

    test(
      '400 with other error_description → Failure (NOT RefreshTokenInvalidError)',
      () async {
        final client = http_test.MockClient(
          (req) async => http.Response(
            jsonEncode({
              'error': 'invalid_request',
              'error_description': 'malformed parameter',
            }),
            400,
            headers: {'content-type': 'application/json'},
          ),
        );
        final tokenClient = TokenClient(
          discovery: discovery,
          httpClient: client,
        );

        final result = await tokenClient.refresh(refreshToken: 'rt');

        expect(result, isA<Failure<TokenResponse>>());
        final failure = result as Failure<TokenResponse>;
        expect(failure.error, isNot(isA<RefreshTokenInvalidError>()));
        expect(failure.error, isA<CliError>());
      },
    );

    test('5xx → Failure(ServerError)', () async {
      final client = http_test.MockClient(
        (req) async => http.Response('zitadel down', 502),
      );
      final tokenClient = TokenClient(discovery: discovery, httpClient: client);

      final result = await tokenClient.refresh(refreshToken: 'rt');

      expect(result, isA<Failure<TokenResponse>>());
      expect((result as Failure<TokenResponse>).error, isA<CliError>());
    });
  });

  group('CliError sealed family — RefreshTokenInvalidError', () {
    test('is a CliError variant (sealed family extension)', () {
      const err = RefreshTokenInvalidError();
      expect(err, isA<CliError>());
      expect(err, isA<Exception>());
    });
  });
}

class _SimulatedNetworkException implements Exception {
  const _SimulatedNetworkException();
  @override
  String toString() => 'simulated network failure';
}
