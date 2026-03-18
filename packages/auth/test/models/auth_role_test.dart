import 'package:auth/auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthRole', () {
    test('has correct string values', () {
      expect(AuthRole.socialWorker.value, 'social_worker');
      expect(AuthRole.owner.value, 'owner');
      expect(AuthRole.admin.value, 'admin');
    });

    group('fromString', () {
      test('resolves known roles', () {
        expect(AuthRole.fromString('social_worker'), AuthRole.socialWorker);
        expect(AuthRole.fromString('owner'), AuthRole.owner);
        expect(AuthRole.fromString('admin'), AuthRole.admin);
      });

      test('returns null for unknown role', () {
        expect(AuthRole.fromString('superuser'), isNull);
        expect(AuthRole.fromString(''), isNull);
      });
    });

    group('fromJwtClaim', () {
      test('extracts roles from valid claim map', () {
        final claim = {
          'social_worker': {'363110312318140539': 'acdgbrasil.com.br'},
          'admin': {'363110312318140539': 'acdgbrasil.com.br'},
        };

        final roles = AuthRole.fromJwtClaim(claim);

        expect(roles, {AuthRole.socialWorker, AuthRole.admin});
      });

      test('ignores unknown role keys', () {
        final claim = {
          'social_worker': {'363110312318140539': 'acdgbrasil.com.br'},
          'superuser': {'363110312318140539': 'acdgbrasil.com.br'},
        };

        final roles = AuthRole.fromJwtClaim(claim);

        expect(roles, {AuthRole.socialWorker});
      });

      test('returns empty set for null claim', () {
        expect(AuthRole.fromJwtClaim(null), isEmpty);
      });

      test('returns empty set for empty claim', () {
        expect(AuthRole.fromJwtClaim({}), isEmpty);
      });

      test('extracts all three roles when present', () {
        final claim = {
          'social_worker': {'id': 'org'},
          'owner': {'id': 'org'},
          'admin': {'id': 'org'},
        };

        final roles = AuthRole.fromJwtClaim(claim);

        expect(roles, {AuthRole.socialWorker, AuthRole.owner, AuthRole.admin});
      });
    });
  });
}
