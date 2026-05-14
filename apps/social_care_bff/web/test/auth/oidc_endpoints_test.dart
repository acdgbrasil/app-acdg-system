import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'package:social_care_web/src/auth/oidc_endpoints.dart';

/// MockHttpClient — handler customizavel para respostas controladas.
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

const _zitadelDiscovery = {
  'issuer': 'https://auth.example.com',
  'authorization_endpoint': 'https://auth.example.com/oauth/v2/authorize',
  'token_endpoint': 'https://auth.example.com/oauth/v2/token',
  'userinfo_endpoint': 'https://auth.example.com/oidc/v1/userinfo',
  'jwks_uri': 'https://auth.example.com/oauth/v2/keys',
  'revocation_endpoint': 'https://auth.example.com/oauth/v2/revoke',
  'end_session_endpoint': 'https://auth.example.com/oidc/v1/end_session',
  'introspection_endpoint': 'https://auth.example.com/oauth/v2/introspect',
};

const _authentikDiscovery = {
  'issuer': 'http://localhost:9000/application/o/social-care/',
  'authorization_endpoint': 'http://localhost:9000/application/o/authorize/',
  'token_endpoint': 'http://localhost:9000/application/o/token/',
  'userinfo_endpoint': 'http://localhost:9000/application/o/userinfo/',
  'jwks_uri': 'http://localhost:9000/application/o/social-care/jwks/',
  'revocation_endpoint': 'http://localhost:9000/application/o/revoke/',
  'end_session_endpoint':
      'http://localhost:9000/application/o/social-care/end-session/',
};

void main() {
  group('OidcEndpoints.fromDiscovery', () {
    late MockHttpClient mockClient;
    final discoveryUri = Uri.parse(
      'https://auth.example.com/.well-known/openid-configuration',
    );

    setUp(() {
      mockClient = MockHttpClient();
    });

    test('resolves endpoints do shape Zitadel', () async {
      mockClient.handler = (_) => http.Response(
        jsonEncode(_zitadelDiscovery),
        200,
        headers: {'content-type': 'application/json'},
      );

      final endpoints = await OidcEndpoints.fromDiscovery(
        discoveryUri: discoveryUri,
        httpClient: mockClient,
      );

      expect(endpoints.issuer, equals('https://auth.example.com'));
      expect(
        endpoints.tokenEndpoint,
        equals(Uri.parse('https://auth.example.com/oauth/v2/token')),
      );
      expect(
        endpoints.authorizationEndpoint,
        equals(Uri.parse('https://auth.example.com/oauth/v2/authorize')),
      );
      expect(
        endpoints.jwksUri,
        equals(Uri.parse('https://auth.example.com/oauth/v2/keys')),
      );
      expect(
        endpoints.revocationEndpoint,
        equals(Uri.parse('https://auth.example.com/oauth/v2/revoke')),
      );
      expect(endpoints.endSessionEndpoint, isNotNull);
      expect(endpoints.introspectionEndpoint, isNotNull);
    });

    test('resolves endpoints do shape Authentik (paths diferentes)', () async {
      mockClient.handler = (_) => http.Response(
        jsonEncode(_authentikDiscovery),
        200,
        headers: {'content-type': 'application/json'},
      );

      final endpoints = await OidcEndpoints.fromDiscovery(
        discoveryUri: discoveryUri,
        httpClient: mockClient,
      );

      // ADR-028: paths Authentik (`/application/o/...`) sao radicalmente
      // diferentes de Zitadel (`/oauth/v2/...`). Discovery resolve ambos
      // sem mudanca no consumer — torna o BFF agnostico de IdP.
      expect(
        endpoints.tokenEndpoint,
        equals(Uri.parse('http://localhost:9000/application/o/token/')),
      );
      expect(
        endpoints.jwksUri,
        equals(
          Uri.parse('http://localhost:9000/application/o/social-care/jwks/'),
        ),
      );
      expect(endpoints.introspectionEndpoint, isNull);
    });

    test('falha cedo (OidcDiscoveryException) em 404', () async {
      mockClient.handler = (_) => http.Response('Not Found', 404);

      expect(
        () => OidcEndpoints.fromDiscovery(
          discoveryUri: discoveryUri,
          httpClient: mockClient,
        ),
        throwsA(isA<OidcDiscoveryException>()),
      );
    });

    test('falha cedo em JSON malformado', () async {
      mockClient.handler = (_) => http.Response('not-json-at-all', 200);

      expect(
        () => OidcEndpoints.fromDiscovery(
          discoveryUri: discoveryUri,
          httpClient: mockClient,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('falha cedo se campo obrigatorio ausente', () async {
      final incompleteDiscovery = Map<String, Object?>.from(_zitadelDiscovery);
      incompleteDiscovery.remove('token_endpoint');
      mockClient.handler = (_) => http.Response(
        jsonEncode(incompleteDiscovery),
        200,
        headers: {'content-type': 'application/json'},
      );

      expect(
        () => OidcEndpoints.fromDiscovery(
          discoveryUri: discoveryUri,
          httpClient: mockClient,
        ),
        throwsA(
          isA<OidcDiscoveryException>().having(
            (e) => e.message,
            'message',
            contains('token_endpoint'),
          ),
        ),
      );
    });
  });
}
