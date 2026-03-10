import 'package:core/core.dart';
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
        expect(validToken.isExpired, isFalse);
      });

      test('returns true for past expiration', () {
        final expired = validToken.copyWith(expiresAt: pastDate);
        expect(expired.isExpired, isTrue);
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
        expect(
          validToken.expiresWithin(const Duration(seconds: 30)),
          isFalse,
        );
      });
    });

    test('refreshToken can be null (web Split-Token)', () {
      final webToken = AuthToken(
        accessToken: 'access',
        expiresAt: futureDate,
      );
      expect(webToken.refreshToken, isNull);
      expect(webToken.isExpired, isFalse);
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
