import 'package:auth/auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthToken', () {
    final futureDate = DateTime.now().add(const Duration(hours: 1));
    final pastDate = DateTime.now().subtract(const Duration(hours: 1));

    final validToken = AuthToken(
      accessToken: 'access_123',
      refreshToken: 'refresh_456',
      idToken: 'id_789',
      expiresAt: futureDate,
    );

    test('stores all fields correctly', () {
      expect(validToken.accessToken, 'access_123');
      expect(validToken.refreshToken, 'refresh_456');
      expect(validToken.idToken, 'id_789');
      expect(validToken.expiresAt, futureDate);
    });

    group('isExpired', () {
      test('returns false for future expiration', () {
        expect(validToken.isExpired(), isFalse);
      });

      test('returns true for past expiration', () {
        final expired = validToken.copyWith(expiresAt: pastDate);
        expect(expired.isExpired(), isTrue);
      });

      test('accepts injectable now for deterministic testing', () {
        final token = AuthToken(
          accessToken: 'a',
          expiresAt: DateTime(2030, 1, 1),
        );
        final before = DateTime(2029, 12, 31);
        final after = DateTime(2030, 1, 2);

        expect(token.isExpired(now: before), isFalse);
        expect(token.isExpired(now: after), isTrue);
      });
    });

    group('expiresWithin', () {
      test('returns true when token expires within threshold', () {
        final soonToken = validToken.copyWith(
          expiresAt: DateTime.now().add(const Duration(seconds: 20)),
        );
        expect(soonToken.expiresWithin(const Duration(seconds: 30)), isTrue);
      });

      test('returns false when token has plenty of time left', () {
        expect(validToken.expiresWithin(const Duration(seconds: 30)), isFalse);
      });

      test('accepts injectable now for deterministic testing', () {
        final token = AuthToken(
          accessToken: 'a',
          expiresAt: DateTime(2030, 1, 1, 0, 1, 0), // 00:01:00
        );
        final now = DateTime(2030, 1, 1, 0, 0, 40); // 00:00:40 → 20s left

        expect(
          token.expiresWithin(const Duration(seconds: 30), now: now),
          isTrue,
        );
        expect(
          token.expiresWithin(const Duration(seconds: 10), now: now),
          isFalse,
        );
      });
    });

    test('refreshToken can be null (web Split-Token)', () {
      final webToken = AuthToken(accessToken: 'access', expiresAt: futureDate);
      expect(webToken.refreshToken, isNull);
      expect(webToken.isExpired(), isFalse);
    });

    group('copyWith', () {
      test('copies with new values', () {
        final copy = validToken.copyWith(accessToken: 'new_access');
        expect(copy.accessToken, 'new_access');
        expect(copy.refreshToken, validToken.refreshToken);
      });

      test('preserves values when no arguments given', () {
        final copy = validToken.copyWith();
        expect(copy, validToken);
      });

      test('clears refreshToken via ValueGetter', () {
        final cleared = validToken.copyWith(refreshToken: () => null);
        expect(cleared.refreshToken, isNull);
        expect(cleared.accessToken, validToken.accessToken);
      });

      test('clears idToken via ValueGetter', () {
        final cleared = validToken.copyWith(idToken: () => null);
        expect(cleared.idToken, isNull);
      });

      test('sets new refreshToken via ValueGetter', () {
        final updated = validToken.copyWith(refreshToken: () => 'new_refresh');
        expect(updated.refreshToken, 'new_refresh');
      });
    });

    group('equality', () {
      test('equal tokens are equal', () {
        final other = AuthToken(
          accessToken: 'access_123',
          refreshToken: 'refresh_456',
          idToken: 'id_789',
          expiresAt: futureDate,
        );
        expect(validToken, other);
        expect(validToken.hashCode, other.hashCode);
      });

      test('different accessToken means not equal', () {
        final other = validToken.copyWith(accessToken: 'different');
        expect(validToken, isNot(other));
      });
    });

    test('toString does not expose token values', () {
      final str = validToken.toString();
      expect(str, isNot(contains('access_123')));
      expect(str, contains('expiresAt'));
    });
  });
}
