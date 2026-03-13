import 'package:auth/auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OidcClaimsParser', () {
    group('userFromClaims', () {
      test('extracts all fields from complete claims', () {
        final user = OidcClaimsParser.userFromClaims(
          uid: 'zitadel-uid-123',
          claims: {
            'sub': 'sub-456',
            'name': 'Maria Silva',
            'email': 'maria@acdg.com.br',
            'preferred_username': 'maria.silva',
            'urn:zitadel:iam:org:project:roles': {
              'social_worker': {'363110312318140539': 'acdgbrasil.com.br'},
              'admin': {'363110312318140539': 'acdgbrasil.com.br'},
            },
          },
        );

        expect(user.id, 'zitadel-uid-123');
        expect(user.name, 'Maria Silva');
        expect(user.email, 'maria@acdg.com.br');
        expect(user.preferredUsername, 'maria.silva');
        expect(user.roles, {AuthRole.socialWorker, AuthRole.admin});
      });

      test('falls back to sub claim when uid is null', () {
        final user = OidcClaimsParser.userFromClaims(
          uid: null,
          claims: {'sub': 'sub-789'},
        );

        expect(user.id, 'sub-789');
      });

      test('falls back to empty string when uid and sub are both null', () {
        final user = OidcClaimsParser.userFromClaims(
          uid: null,
          claims: {},
        );

        expect(user.id, '');
      });

      test('returns empty roles when roles claim is absent', () {
        final user = OidcClaimsParser.userFromClaims(
          uid: 'uid',
          claims: {'sub': 'sub'},
        );

        expect(user.roles, isEmpty);
      });

      test('returns empty roles when roles claim is not a Map', () {
        final user = OidcClaimsParser.userFromClaims(
          uid: 'uid',
          claims: {
            'urn:zitadel:iam:org:project:roles': 'invalid_type',
          },
        );

        expect(user.roles, isEmpty);
      });

      test('handles null optional fields gracefully', () {
        final user = OidcClaimsParser.userFromClaims(
          uid: 'uid',
          claims: {'sub': 'sub'},
        );

        expect(user.name, isNull);
        expect(user.email, isNull);
        expect(user.preferredUsername, isNull);
      });

      test('ignores unknown roles in claims', () {
        final user = OidcClaimsParser.userFromClaims(
          uid: 'uid',
          claims: {
            'urn:zitadel:iam:org:project:roles': {
              'social_worker': {'id': 'org'},
              'superuser': {'id': 'org'},
              'root': {'id': 'org'},
            },
          },
        );

        expect(user.roles, {AuthRole.socialWorker});
      });

      test('extracts single role correctly', () {
        final user = OidcClaimsParser.userFromClaims(
          uid: 'uid',
          claims: {
            'urn:zitadel:iam:org:project:roles': {
              'owner': {'id': 'org'},
            },
          },
        );

        expect(user.roles, {AuthRole.owner});
        expect(user.canWrite, isFalse);
        expect(user.canRead, isTrue);
      });
    });

    group('tokenFromRaw', () {
      test('creates token with all fields', () {
        final expiresAt = DateTime(2030, 6, 15);
        final token = OidcClaimsParser.tokenFromRaw(
          accessToken: 'access_abc',
          refreshToken: 'refresh_def',
          idToken: 'id_ghi',
          expiresAt: expiresAt,
        );

        expect(token.accessToken, 'access_abc');
        expect(token.refreshToken, 'refresh_def');
        expect(token.idToken, 'id_ghi');
        expect(token.expiresAt, expiresAt);
      });

      test('allows null refreshToken (web Split-Token)', () {
        final token = OidcClaimsParser.tokenFromRaw(
          accessToken: 'access',
          expiresAt: DateTime(2030, 1, 1),
        );

        expect(token.refreshToken, isNull);
        expect(token.idToken, isNull);
      });

      test('falls back to DateTime.now() when expiresAt is null', () {
        final before = DateTime.now();
        final token = OidcClaimsParser.tokenFromRaw(
          accessToken: 'access',
        );
        final after = DateTime.now();

        expect(token.expiresAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
        expect(token.expiresAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      });

      test('token with future expiry is not expired', () {
        final token = OidcClaimsParser.tokenFromRaw(
          accessToken: 'access',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        expect(token.isExpired(), isFalse);
      });

      test('token with past expiry is expired', () {
        final token = OidcClaimsParser.tokenFromRaw(
          accessToken: 'access',
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        expect(token.isExpired(), isTrue);
      });
    });
  });
}
