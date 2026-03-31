import 'package:auth/auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OidcAuthConfig', () {
    test('stores all provided values', () {
      final config = OidcAuthConfig(
        issuer: Uri.parse('https://auth.example.com'),
        clientId: '123',
        redirectUri: Uri.parse('http://localhost:0'),
        postLogoutRedirectUri: Uri.parse('http://localhost:0'),
      );

      expect(config.issuer, Uri.parse('https://auth.example.com'));
      expect(config.clientId, '123');
      expect(config.redirectUri, Uri.parse('http://localhost:0'));
      expect(config.postLogoutRedirectUri, Uri.parse('http://localhost:0'));
    });

    test('uses default scopes when not provided', () {
      final config = OidcAuthConfig(
        issuer: Uri.parse('https://auth.example.com'),
        clientId: '123',
        redirectUri: Uri.parse('http://localhost:0'),
        postLogoutRedirectUri: Uri.parse('http://localhost:0'),
      );

      expect(config.scopes, OidcAuthConfig.defaultScopes);
      expect(config.scopes, contains('openid'));
      expect(config.scopes, contains('profile'));
      expect(config.scopes, contains('email'));
      expect(config.scopes, contains('offline_access'));
      expect(config.scopes, contains('urn:zitadel:iam:org:project:roles'));
    });

    test('allows custom scopes', () {
      final config = OidcAuthConfig(
        issuer: Uri.parse('https://auth.example.com'),
        clientId: '123',
        redirectUri: Uri.parse('http://localhost:0'),
        postLogoutRedirectUri: Uri.parse('http://localhost:0'),
        scopes: ['openid', 'profile'],
      );

      expect(config.scopes, ['openid', 'profile']);
    });

    test('builds discoveryDocumentUri from issuer', () {
      final config = OidcAuthConfig(
        issuer: Uri.parse('https://auth.example.com'),
        clientId: '123',
        redirectUri: Uri.parse('http://localhost:0'),
        postLogoutRedirectUri: Uri.parse('http://localhost:0'),
      );

      expect(
        config.discoveryDocumentUri.toString(),
        'https://auth.example.com/.well-known/openid-configuration',
      );
    });

    test('strips trailing slash from issuer in discoveryDocumentUri', () {
      final config = OidcAuthConfig(
        issuer: Uri.parse('https://auth.example.com/'),
        clientId: '123',
        redirectUri: Uri.parse('http://localhost:0'),
        postLogoutRedirectUri: Uri.parse('http://localhost:0'),
      );

      expect(
        config.discoveryDocumentUri.toString(),
        'https://auth.example.com/.well-known/openid-configuration',
      );
    });

    test('defaultScopes has 5 entries', () {
      expect(OidcAuthConfig.defaultScopes.length, 5);
    });
  });
}
