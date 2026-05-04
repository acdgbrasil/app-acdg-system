/// W0 RED — `OidcSession` value object contract (C02 §5.12).
///
/// W1 must create `apps/cli/lib/src/session/oidc_session.dart` with:
///
/// ```dart
/// final class OidcSession with Equatable {
///   const OidcSession({
///     required this.accessToken,
///     required this.refreshToken,
///     required this.idToken,
///     required this.accessExpiresAt,
///     required this.sub,
///     required this.email,
///     required this.roles,
///   });
///
///   final String accessToken;
///   final String refreshToken;
///   final String idToken;
///   final DateTime accessExpiresAt;
///   final String sub;
///   final String email;
///   final List<String> roles;
///
///   factory OidcSession.fromJson(Map<String, Object?> json);
///   Map<String, Object?> toJson();
///
///   /// True when accessExpiresAt - now < 60s (proactive-refresh window).
///   /// `now` is injectable so tests don't depend on wall-clock.
///   bool isExpired({DateTime? now});
/// }
/// ```
///
/// **Migration concern (Credentials → OidcSession):** C01 ships `Credentials`
/// with only `accessToken`, `refreshToken`, `expiresAt`. The C02 contract is
/// strictly additive (extra non-null fields), so the cleanest evolution is
/// for W1 to:
///
/// 1. Introduce `OidcSession` as the new authoritative session model.
/// 2. Update `CredentialStore` to read/write `OidcSession`.
/// 3. Delete the old `Credentials` class (C01-only consumer is its own test
///    file — it can be migrated alongside, OR `Credentials` can be kept as a
///    `typedef Credentials = OidcSession` deprecated alias).
///
/// W0 declares the `OidcSession` contract here without speaking to migration
/// strategy — the test-writer flags both options in REPORT.md and lets W1
/// choose.
library;

import 'package:test/test.dart';

import 'package:cli/src/session/oidc_session.dart';

void main() {
  group('OidcSession — JSON round-trip', () {
    test('toJson/fromJson preserves every field', () {
      final original = OidcSession(
        accessToken: 'at-abc',
        refreshToken: 'rt-xyz',
        idToken: 'it-eyJ',
        accessExpiresAt: DateTime.utc(2099, 1, 2, 3, 4, 5),
        sub: '363088829932634233',
        email: 'gabriel@example.com',
        roles: const ['superadmin', 'social_worker'],
      );

      final json = original.toJson();
      final reconstructed = OidcSession.fromJson(json);

      expect(reconstructed.accessToken, equals('at-abc'));
      expect(reconstructed.refreshToken, equals('rt-xyz'));
      expect(reconstructed.idToken, equals('it-eyJ'));
      expect(
        reconstructed.accessExpiresAt,
        equals(DateTime.utc(2099, 1, 2, 3, 4, 5)),
      );
      expect(reconstructed.sub, equals('363088829932634233'));
      expect(reconstructed.email, equals('gabriel@example.com'));
      expect(reconstructed.roles, equals(['superadmin', 'social_worker']));
    });

    test('toJson uses ISO-8601 for accessExpiresAt (interoperable)', () {
      final session = OidcSession(
        accessToken: 'a',
        refreshToken: 'r',
        idToken: 'i',
        accessExpiresAt: DateTime.utc(2099, 6, 15, 12, 0, 0),
        sub: 's',
        email: 'e@e',
        roles: const [],
      );

      final json = session.toJson();
      // ISO-8601 in UTC ends with 'Z' or has explicit offset.
      expect(
        json['access_expires_at'],
        anyOf(isA<String>().having((s) => s, 'iso', contains('2099-06-15'))),
      );
    });
  });

  group('OidcSession — value equality (Equatable)', () {
    test('two sessions with the same fields compare equal', () {
      final a = OidcSession(
        accessToken: 'at',
        refreshToken: 'rt',
        idToken: 'it',
        accessExpiresAt: DateTime.utc(2099, 1, 1),
        sub: '1',
        email: 'e@e',
        roles: const ['owner'],
      );
      final b = OidcSession(
        accessToken: 'at',
        refreshToken: 'rt',
        idToken: 'it',
        accessExpiresAt: DateTime.utc(2099, 1, 1),
        sub: '1',
        email: 'e@e',
        roles: const ['owner'],
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different access tokens compare unequal', () {
      final a = OidcSession(
        accessToken: 'at-1',
        refreshToken: 'rt',
        idToken: 'it',
        accessExpiresAt: DateTime.utc(2099, 1, 1),
        sub: '1',
        email: 'e@e',
        roles: const [],
      );
      final b = OidcSession(
        accessToken: 'at-2',
        refreshToken: 'rt',
        idToken: 'it',
        accessExpiresAt: DateTime.utc(2099, 1, 1),
        sub: '1',
        email: 'e@e',
        roles: const [],
      );

      expect(a, isNot(equals(b)));
    });
  });

  group('OidcSession.isExpired — proactive 60s window', () {
    test('expires-far-in-future is NOT expired', () {
      final now = DateTime.utc(2026, 1, 1, 12, 0, 0);
      final session = OidcSession(
        accessToken: 'a',
        refreshToken: 'r',
        idToken: 'i',
        accessExpiresAt: now.add(const Duration(hours: 1)),
        sub: 's',
        email: 'e@e',
        roles: const [],
      );

      expect(session.isExpired(now: now), isFalse);
    });

    test('expires-in-30s IS expired (inside 60s buffer)', () {
      final now = DateTime.utc(2026, 1, 1, 12, 0, 0);
      final session = OidcSession(
        accessToken: 'a',
        refreshToken: 'r',
        idToken: 'i',
        accessExpiresAt: now.add(const Duration(seconds: 30)),
        sub: 's',
        email: 'e@e',
        roles: const [],
      );

      expect(session.isExpired(now: now), isTrue);
    });

    test('expires-in-the-past IS expired', () {
      final now = DateTime.utc(2026, 1, 1, 12, 0, 0);
      final session = OidcSession(
        accessToken: 'a',
        refreshToken: 'r',
        idToken: 'i',
        accessExpiresAt: now.subtract(const Duration(minutes: 5)),
        sub: 's',
        email: 'e@e',
        roles: const [],
      );

      expect(session.isExpired(now: now), isTrue);
    });

    test('expires-exactly-60s-out IS expired (boundary inclusive)', () {
      final now = DateTime.utc(2026, 1, 1, 12, 0, 0);
      final session = OidcSession(
        accessToken: 'a',
        refreshToken: 'r',
        idToken: 'i',
        accessExpiresAt: now.add(const Duration(seconds: 60)),
        sub: 's',
        email: 'e@e',
        roles: const [],
      );

      // `now >= accessExpiresAt - 60s` ⇒ now (12:00) >= 12:00 ⇒ true.
      expect(session.isExpired(now: now), isTrue);
    });
  });
}
