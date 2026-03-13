import 'package:auth/auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthUser', () {
    const user = AuthUser(
      id: '123',
      name: 'Maria Silva',
      email: 'maria@acdg.com.br',
      preferredUsername: 'maria.silva',
      roles: {AuthRole.socialWorker},
    );

    test('stores all fields correctly', () {
      expect(user.id, '123');
      expect(user.name, 'Maria Silva');
      expect(user.email, 'maria@acdg.com.br');
      expect(user.preferredUsername, 'maria.silva');
      expect(user.roles, {AuthRole.socialWorker});
    });

    group('displayName', () {
      test('prefers name', () {
        expect(user.displayName, 'Maria Silva');
      });

      test('falls back to preferredUsername when name is cleared', () {
        final noName = user.copyWith(name: () => null);
        expect(noName.displayName, 'maria.silva');
      });

      test('falls back to email', () {
        const u = AuthUser(id: '1', email: 'maria@acdg.com.br', roles: {});
        expect(u.displayName, 'maria@acdg.com.br');
      });

      test('falls back to id', () {
        const u = AuthUser(id: '1', roles: {});
        expect(u.displayName, '1');
      });
    });

    group('role checks', () {
      test('hasRole returns true for matching role', () {
        expect(user.hasRole(AuthRole.socialWorker), isTrue);
      });

      test('hasRole returns false for non-matching role', () {
        expect(user.hasRole(AuthRole.admin), isFalse);
      });

      test('hasAnyRole returns true when intersection exists', () {
        expect(
          user.hasAnyRole({AuthRole.socialWorker, AuthRole.admin}),
          isTrue,
        );
      });

      test('hasAnyRole returns false when no intersection', () {
        expect(user.hasAnyRole({AuthRole.owner, AuthRole.admin}), isFalse);
      });
    });

    group('permissions', () {
      test('canWrite is true for socialWorker', () {
        expect(user.canWrite, isTrue);
      });

      test('canWrite is false for owner', () {
        const ownerUser = AuthUser(id: '2', roles: {AuthRole.owner});
        expect(ownerUser.canWrite, isFalse);
      });

      test('canRead is true when any role is present', () {
        expect(user.canRead, isTrue);
      });

      test('canRead is false when no roles', () {
        const noRoles = AuthUser(id: '3', roles: {});
        expect(noRoles.canRead, isFalse);
      });
    });

    group('copyWith', () {
      test('copies with new values', () {
        final copy = user.copyWith(name: () => 'Ana Costa');
        expect(copy.name, 'Ana Costa');
        expect(copy.id, user.id);
        expect(copy.email, user.email);
      });

      test('preserves values when no arguments given', () {
        final copy = user.copyWith();
        expect(copy, user);
      });

      test('clears nullable field when set to null', () {
        final cleared = user.copyWith(name: () => null);
        expect(cleared.name, isNull);
        expect(cleared.email, user.email);
      });

      test('clears email via ValueGetter', () {
        final cleared = user.copyWith(email: () => null);
        expect(cleared.email, isNull);
        expect(cleared.name, user.name);
      });

      test('clears preferredUsername via ValueGetter', () {
        final cleared = user.copyWith(preferredUsername: () => null);
        expect(cleared.preferredUsername, isNull);
      });
    });

    group('equality', () {
      test('equal users are equal', () {
        const other = AuthUser(
          id: '123',
          name: 'Maria Silva',
          email: 'maria@acdg.com.br',
          preferredUsername: 'maria.silva',
          roles: {AuthRole.socialWorker},
        );
        expect(user, other);
        expect(user.hashCode, other.hashCode);
      });

      test('different id means not equal', () {
        final other = user.copyWith(id: '999');
        expect(user, isNot(other));
      });

      test('different roles means not equal', () {
        final other = user.copyWith(roles: {AuthRole.admin});
        expect(user, isNot(other));
      });
    });

    test('toString includes id, name and roles', () {
      final str = user.toString();
      expect(str, contains('123'));
      expect(str, contains('Maria Silva'));
      expect(str, contains('socialWorker'));
    });
  });
}
