import 'package:auth/auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthStatus', () {
    const user = AuthUser(
      id: '123',
      name: 'Maria',
      roles: {AuthRole.socialWorker},
    );

    group('Authenticated', () {
      test('holds user reference', () {
        const status = Authenticated(user);
        expect(status.user, user);
      });

      test('equality by user', () {
        const a = Authenticated(user);
        const b = Authenticated(user);
        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('not equal to different user', () {
        const other = AuthUser(id: '999', roles: {});
        const a = Authenticated(user);
        const b = Authenticated(other);
        expect(a, isNot(b));
      });

      test('toString includes display name', () {
        const status = Authenticated(user);
        expect(status.toString(), contains('Maria'));
      });
    });

    group('Unauthenticated', () {
      test('const instances are equal', () {
        const a = Unauthenticated();
        const b = Unauthenticated();
        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('toString', () {
        expect(const Unauthenticated().toString(), 'Unauthenticated');
      });
    });

    group('AuthLoading', () {
      test('const instances are equal', () {
        const a = AuthLoading();
        const b = AuthLoading();
        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('toString', () {
        expect(const AuthLoading().toString(), 'AuthLoading');
      });
    });

    group('AuthError', () {
      test('holds message', () {
        const status = AuthError('token expired');
        expect(status.message, 'token expired');
      });

      test('equality by message', () {
        const a = AuthError('fail');
        const b = AuthError('fail');
        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('not equal with different message', () {
        const a = AuthError('fail');
        const b = AuthError('timeout');
        expect(a, isNot(b));
      });

      test('toString includes message', () {
        const status = AuthError('network error');
        expect(status.toString(), contains('network error'));
      });
    });

    test('pattern matching is exhaustive', () {
      const AuthStatus status = Authenticated(user);

      final label = switch (status) {
        Authenticated(:final user) => 'logged in as ${user.displayName}',
        Unauthenticated() => 'logged out',
        AuthLoading() => 'loading',
        AuthError(:final message) => 'error: $message',
      };

      expect(label, 'logged in as Maria');
    });

    test('different subtypes are not equal', () {
      const auth = Authenticated(user);
      const unauth = Unauthenticated();
      const loading = AuthLoading();
      const error = AuthError('fail');

      expect(auth, isNot(unauth));
      expect(unauth, isNot(loading));
      expect(loading, isNot(error));
    });
  });
}
