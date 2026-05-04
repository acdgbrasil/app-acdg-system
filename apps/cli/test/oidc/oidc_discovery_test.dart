/// W0 RED — OIDC discovery contract (C02 §5.3).
///
/// W1 must create `apps/cli/lib/src/oidc/oidc_discovery.dart` with:
///
/// ```dart
/// final class OidcDiscovery with Equatable {
///   const OidcDiscovery({
///     required this.issuer,
///     required this.authorizationEndpoint,
///     required this.tokenEndpoint,
///     required this.jwksUri,
///     required this.userinfoEndpoint,
///     required this.endSessionEndpoint,
///     required this.revocationEndpoint,
///     required this.deviceAuthorizationEndpoint,
///   });
///
///   final String issuer;
///   final String authorizationEndpoint;
///   final String tokenEndpoint;
///   final String jwksUri;
///   final String userinfoEndpoint;
///   final String endSessionEndpoint;
///   final String revocationEndpoint;
///   final String deviceAuthorizationEndpoint;
///
///   /// Boots discovery against `<issuer>/.well-known/openid-configuration`,
///   /// validates `issuer` claim matches exactly (defense against spoof),
///   /// returns `Failure` for HTTP non-200, malformed JSON, or issuer mismatch.
///   static Future<Result<OidcDiscovery>> load({
///     required http.Client httpClient,
///     required String issuer,
///   });
/// }
/// ```
///
/// Why a `http.Client` injected: keeps the test deterministic without
/// hitting real Zitadel. `MockClient` from `package:http/testing.dart`
/// (or a hand-rolled fake) is enough — no `mockito`, no magic mocks.
library;

import 'dart:convert';

import 'package:core_contracts/core_contracts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_test;
import 'package:test/test.dart';

import 'package:cli/src/errors/cli_error.dart';
import 'package:cli/src/oidc/oidc_discovery.dart';

void main() {
  group('OidcDiscovery.load — happy path', () {
    test('parses all 7 endpoints when issuer matches', () async {
      const issuer = 'https://auth.acdgbrasil.com.br';
      final body = jsonEncode({
        'issuer': issuer,
        'authorization_endpoint': '$issuer/oauth/v2/authorize',
        'token_endpoint': '$issuer/oauth/v2/token',
        'jwks_uri': '$issuer/oauth/v2/keys',
        'userinfo_endpoint': '$issuer/oidc/v1/userinfo',
        'end_session_endpoint': '$issuer/oidc/v1/end_session',
        'revocation_endpoint': '$issuer/oauth/v2/revoke',
        'device_authorization_endpoint':
            '$issuer/oauth/v2/device_authorization',
      });
      final client = http_test.MockClient((req) async {
        expect(
          req.url.toString(),
          equals('$issuer/.well-known/openid-configuration'),
        );
        return http.Response(
          body,
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await OidcDiscovery.load(
        httpClient: client,
        issuer: issuer,
      );

      expect(result, isA<Success<OidcDiscovery>>());
      final discovery = (result as Success<OidcDiscovery>).value;
      expect(discovery.issuer, equals(issuer));
      expect(discovery.authorizationEndpoint, contains('/authorize'));
      expect(discovery.tokenEndpoint, contains('/token'));
      expect(discovery.jwksUri, contains('/keys'));
      expect(discovery.userinfoEndpoint, contains('/userinfo'));
      expect(discovery.endSessionEndpoint, contains('/end_session'));
      expect(discovery.revocationEndpoint, contains('/revoke'));
      expect(
        discovery.deviceAuthorizationEndpoint,
        contains('/device_authorization'),
      );
    });
  });

  group('OidcDiscovery.load — failure paths', () {
    test('HTTP non-200 → Failure(NetworkError or ServerError)', () async {
      const issuer = 'https://auth.acdgbrasil.com.br';
      final client = http_test.MockClient(
        (req) async => http.Response('upstream down', 503),
      );

      final result = await OidcDiscovery.load(
        httpClient: client,
        issuer: issuer,
      );

      expect(result, isA<Failure<OidcDiscovery>>());
      final failure = result as Failure<OidcDiscovery>;
      expect(failure.error, isA<CliError>());
    });

    test('200 but issuer mismatch → Failure (anti-spoofing)', () async {
      const issuer = 'https://auth.acdgbrasil.com.br';
      final body = jsonEncode({
        'issuer': 'https://evil.example.com',
        'authorization_endpoint': '$issuer/oauth/v2/authorize',
        'token_endpoint': '$issuer/oauth/v2/token',
        'jwks_uri': '$issuer/oauth/v2/keys',
        'userinfo_endpoint': '$issuer/oidc/v1/userinfo',
        'end_session_endpoint': '$issuer/oidc/v1/end_session',
        'revocation_endpoint': '$issuer/oauth/v2/revoke',
        'device_authorization_endpoint':
            '$issuer/oauth/v2/device_authorization',
      });
      final client = http_test.MockClient(
        (req) async => http.Response(
          body,
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      final result = await OidcDiscovery.load(
        httpClient: client,
        issuer: issuer,
      );

      expect(result, isA<Failure<OidcDiscovery>>());
    });

    test('200 but malformed JSON → Failure', () async {
      const issuer = 'https://auth.acdgbrasil.com.br';
      final client = http_test.MockClient(
        (req) async => http.Response(
          'not-json',
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      final result = await OidcDiscovery.load(
        httpClient: client,
        issuer: issuer,
      );

      expect(result, isA<Failure<OidcDiscovery>>());
    });

    test('200 but missing required endpoint → Failure', () async {
      const issuer = 'https://auth.acdgbrasil.com.br';
      // Omits token_endpoint — must fail.
      final body = jsonEncode({
        'issuer': issuer,
        'authorization_endpoint': '$issuer/oauth/v2/authorize',
        'jwks_uri': '$issuer/oauth/v2/keys',
      });
      final client = http_test.MockClient(
        (req) async => http.Response(
          body,
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      final result = await OidcDiscovery.load(
        httpClient: client,
        issuer: issuer,
      );

      expect(result, isA<Failure<OidcDiscovery>>());
    });

    test(
      'client throws (DNS / TLS) → Failure (no exception escapes)',
      () async {
        const issuer = 'https://auth.acdgbrasil.com.br';
        final client = http_test.MockClient(
          (req) async => throw const _SimulatedNetworkException(),
        );

        final result = await OidcDiscovery.load(
          httpClient: client,
          issuer: issuer,
        );

        expect(result, isA<Failure<OidcDiscovery>>());
      },
    );
  });
}

/// Used to assert the discovery never lets a transport exception escape.
class _SimulatedNetworkException implements Exception {
  const _SimulatedNetworkException();
  @override
  String toString() => 'simulated network failure';
}
