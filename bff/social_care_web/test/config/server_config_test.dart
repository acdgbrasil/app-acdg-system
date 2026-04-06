import 'package:test/test.dart';
import 'package:social_care_web/src/config/server_config.dart';

void main() {
  group('ServerConfig', () {
    /// Minimal required env vars for a valid config.
    Map<String, String> requiredEnv() => {
      'API_BASE_URL': 'https://api.example.com',
      'OIDC_ISSUER': 'https://auth.example.com',
      'OIDC_CLIENT_ID': 'web-client',
      'OIDC_CLIENT_SECRET': 'super-secret',
      'OIDC_REDIRECT_URI': 'https://bff.example.com/callback',
      'SESSION_SECRET': 'a-very-long-secret-key-for-cookies',
    };

    test(
      'creates with all default values when only required env vars provided',
      () {
        final config = ServerConfig.fromEnvironment(requiredEnv());

        expect(config.port, equals(8081));
        expect(config.host, equals('0.0.0.0'));
        expect(config.apiBaseUrl, equals('https://api.example.com'));
        expect(config.oidcIssuer, equals('https://auth.example.com'));
        expect(config.oidcClientId, equals('web-client'));
        expect(config.oidcClientSecret, equals('super-secret'));
        expect(
          config.oidcRedirectUri,
          equals('https://bff.example.com/callback'),
        );
        expect(
          config.sessionSecret,
          equals('a-very-long-secret-key-for-cookies'),
        );
        expect(config.sessionTtl, equals(const Duration(hours: 1)));
      },
    );

    test('overrides port, host, and sessionTtl from env', () {
      final env = requiredEnv()
        ..['PORT'] = '9090'
        ..['HOST'] = '127.0.0.1'
        ..['SESSION_TTL_MINUTES'] = '30';

      final config = ServerConfig.fromEnvironment(env);

      expect(config.port, equals(9090));
      expect(config.host, equals('127.0.0.1'));
      expect(config.sessionTtl, equals(const Duration(minutes: 30)));
    });

    test('throws StateError when API_BASE_URL is missing', () {
      final env = requiredEnv()..remove('API_BASE_URL');
      expect(
        () => ServerConfig.fromEnvironment(env),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('API_BASE_URL'),
          ),
        ),
      );
    });

    test('throws StateError when OIDC_ISSUER is missing', () {
      final env = requiredEnv()..remove('OIDC_ISSUER');
      expect(
        () => ServerConfig.fromEnvironment(env),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('OIDC_ISSUER'),
          ),
        ),
      );
    });

    test('throws StateError when OIDC_CLIENT_ID is missing', () {
      final env = requiredEnv()..remove('OIDC_CLIENT_ID');
      expect(
        () => ServerConfig.fromEnvironment(env),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('OIDC_CLIENT_ID'),
          ),
        ),
      );
    });

    test('throws StateError when OIDC_CLIENT_SECRET is missing', () {
      final env = requiredEnv()..remove('OIDC_CLIENT_SECRET');
      expect(
        () => ServerConfig.fromEnvironment(env),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('OIDC_CLIENT_SECRET'),
          ),
        ),
      );
    });

    test('throws StateError when OIDC_REDIRECT_URI is missing', () {
      final env = requiredEnv()..remove('OIDC_REDIRECT_URI');
      expect(
        () => ServerConfig.fromEnvironment(env),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('OIDC_REDIRECT_URI'),
          ),
        ),
      );
    });

    test('throws StateError when SESSION_SECRET is missing', () {
      final env = requiredEnv()..remove('SESSION_SECRET');
      expect(
        () => ServerConfig.fromEnvironment(env),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('SESSION_SECRET'),
          ),
        ),
      );
    });

    test('derives discoveryDocumentUri correctly from issuer', () {
      final config = ServerConfig.fromEnvironment(requiredEnv());

      expect(
        config.discoveryDocumentUri,
        equals(
          Uri.parse(
            'https://auth.example.com/.well-known/openid-configuration',
          ),
        ),
      );
    });

    test('derives tokenEndpoint correctly from issuer', () {
      final config = ServerConfig.fromEnvironment(requiredEnv());

      expect(
        config.tokenEndpoint,
        equals(Uri.parse('https://auth.example.com/oauth/v2/token')),
      );
    });

    test('falls back to default port when PORT is non-numeric', () {
      final env = requiredEnv()..['PORT'] = 'not-a-number';
      final config = ServerConfig.fromEnvironment(env);
      expect(config.port, equals(8081));
    });

    test('throws StateError when SESSION_TTL_MINUTES is non-numeric', () {
      final env = requiredEnv()..['SESSION_TTL_MINUTES'] = 'abc';
      expect(
        () => ServerConfig.fromEnvironment(env),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('SESSION_TTL_MINUTES'),
          ),
        ),
      );
    });

    test('throws StateError when required var is present but empty', () {
      final env = requiredEnv()..['API_BASE_URL'] = '';
      expect(
        () => ServerConfig.fromEnvironment(env),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('API_BASE_URL'),
          ),
        ),
      );
    });
  });
}
