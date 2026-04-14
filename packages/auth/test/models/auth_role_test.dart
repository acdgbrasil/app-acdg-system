import 'package:auth/auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthRole', () {
    test('has correct string values', () {
      expect(AuthRole.superAdmin.value, 'superadmin');
      expect(AuthRole.worker.value, 'worker');
      expect(AuthRole.owner.value, 'owner');
      expect(AuthRole.admin.value, 'admin');
    });

    group('fromString', () {
      test('resolves simple roles', () {
        expect(AuthRole.fromString('worker'), AuthRole.worker);
        expect(AuthRole.fromString('owner'), AuthRole.owner);
        expect(AuthRole.fromString('admin'), AuthRole.admin);
        expect(AuthRole.fromString('superadmin'), AuthRole.superAdmin);
      });

      test('resolves composite roles (system:role)', () {
        expect(AuthRole.fromString('social-care:worker'), AuthRole.worker);
        expect(AuthRole.fromString('social-care:admin'), AuthRole.admin);
        expect(AuthRole.fromString('social-care:owner'), AuthRole.owner);
        expect(AuthRole.fromString('analysis-bi:admin'), AuthRole.admin);
        expect(AuthRole.fromString('queue-manager:worker'), AuthRole.worker);
      });

      test('returns null for unknown role', () {
        expect(AuthRole.fromString('superuser'), isNull);
        expect(AuthRole.fromString(''), isNull);
        expect(AuthRole.fromString('social-care:unknown'), isNull);
      });
    });

    group('fromJwtClaim', () {
      test('extracts roles from composite claim map', () {
        final claim = {
          'social-care:worker': {'363110312318140539': 'acdgbrasil.com.br'},
          'social-care:admin': {'363110312318140539': 'acdgbrasil.com.br'},
        };

        final roles = AuthRole.fromJwtClaim(claim);

        expect(roles, {AuthRole.worker, AuthRole.admin});
      });

      test('extracts superadmin (no system prefix)', () {
        final claim = {
          'superadmin': {'363110312318140539': 'acdgbrasil.com.br'},
          'social-care:worker': {'363110312318140539': 'acdgbrasil.com.br'},
        };

        final roles = AuthRole.fromJwtClaim(claim);

        expect(roles, {AuthRole.superAdmin, AuthRole.worker});
      });

      test('ignores unknown role keys', () {
        final claim = {
          'social-care:worker': {'363110312318140539': 'acdgbrasil.com.br'},
          'social-care:unknown': {'363110312318140539': 'acdgbrasil.com.br'},
        };

        final roles = AuthRole.fromJwtClaim(claim);

        expect(roles, {AuthRole.worker});
      });

      test('returns empty set for null claim', () {
        expect(AuthRole.fromJwtClaim(null), isEmpty);
      });

      test('returns empty set for empty claim', () {
        expect(AuthRole.fromJwtClaim({}), isEmpty);
      });

      test('extracts all roles when present', () {
        final claim = {
          'superadmin': {'id': 'org'},
          'social-care:worker': {'id': 'org'},
          'social-care:owner': {'id': 'org'},
          'social-care:admin': {'id': 'org'},
        };

        final roles = AuthRole.fromJwtClaim(claim);

        expect(roles, {
          AuthRole.superAdmin,
          AuthRole.worker,
          AuthRole.owner,
          AuthRole.admin,
        });
      });
    });
  });
}
