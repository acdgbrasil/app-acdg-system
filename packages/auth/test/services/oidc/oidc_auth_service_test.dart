import 'package:auth/auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OidcAuthService', () {
    test('can be instantiated with config', () {
      final config = OidcAuthConfig(
        issuer: Uri.parse('https://auth.example.com'),
        clientId: '123',
        redirectUri: Uri.parse('http://localhost:0'),
        postLogoutRedirectUri: Uri.parse('http://localhost:0'),
      );

      final service = OidcAuthService(config: config);
      expect(service, isNotNull);
      expect(service.currentStatus, isA<AuthLoading>());
      expect(service.currentUser, isNull);
      expect(service.currentToken, isNull);
    });

    test('initial status is AuthLoading', () {
      final service = OidcAuthService(
        config: OidcAuthConfig(
          issuer: Uri.parse('https://auth.example.com'),
          clientId: '123',
          redirectUri: Uri.parse('http://localhost:0'),
          postLogoutRedirectUri: Uri.parse('http://localhost:0'),
        ),
      );

      expect(service.currentStatus, isA<AuthLoading>());
    });

    test('statusStream emits values', () {
      final service = OidcAuthService(
        config: OidcAuthConfig(
          issuer: Uri.parse('https://auth.example.com'),
          clientId: '123',
          redirectUri: Uri.parse('http://localhost:0'),
          postLogoutRedirectUri: Uri.parse('http://localhost:0'),
        ),
      );

      expect(service.statusStream, isA<Stream<AuthStatus>>());
    });
  });
}
