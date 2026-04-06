import 'package:test/test.dart';
import 'package:social_care_web/src/auth/session_store.dart';

void main() {
  group('Session', () {
    test('roles set is unmodifiable', () {
      final session = Session(
        id: 'test-id',
        accessToken: 'access',
        refreshToken: 'refresh',
        userId: 'user-1',
        roles: {'social_worker'},
        expiresAt: DateTime.utc(2026, 1, 1, 12, 0),
      );

      expect(
        () => session.roles.add('admin'),
        throwsUnsupportedError,
      );
    });

    test('isExpired returns true when now is after expiresAt', () {
      final session = Session(
        id: 'test-id',
        accessToken: 'access',
        refreshToken: 'refresh',
        userId: 'user-1',
        roles: {'social_worker'},
        expiresAt: DateTime.utc(2026, 1, 1, 12, 0),
      );

      expect(session.isExpired(now: DateTime.utc(2026, 1, 1, 12, 1)), isTrue);
    });

    test('isExpired returns false when now is before expiresAt', () {
      final session = Session(
        id: 'test-id',
        accessToken: 'access',
        refreshToken: 'refresh',
        userId: 'user-1',
        roles: {'social_worker'},
        expiresAt: DateTime.utc(2026, 1, 1, 12, 0),
      );

      expect(session.isExpired(now: DateTime.utc(2026, 1, 1, 11, 59)), isFalse);
    });
  });

  group('SessionStore', () {
    late SessionStore store;
    late DateTime currentTime;

    setUp(() {
      currentTime = DateTime.utc(2026, 1, 1, 12, 0);
      store = SessionStore(
        ttl: const Duration(hours: 1),
        clock: () => currentTime,
      );
    });

    test('create() returns a unique session ID', () {
      final id1 = store.create(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        userId: 'user-1',
        roles: {'social_worker'},
      );
      final id2 = store.create(
        accessToken: 'access-2',
        refreshToken: 'refresh-2',
        userId: 'user-2',
        roles: {'admin'},
      );

      expect(id1, isNotEmpty);
      expect(id2, isNotEmpty);
      expect(id1, isNot(equals(id2)));
    });

    test('get() returns the session after create', () {
      final id = store.create(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        userId: 'user-1',
        roles: {'social_worker', 'admin'},
      );

      final session = store.get(id);

      expect(session, isNotNull);
      expect(session!.id, equals(id));
      expect(session.accessToken, equals('access-1'));
      expect(session.refreshToken, equals('refresh-1'));
      expect(session.userId, equals('user-1'));
      expect(session.roles, equals({'social_worker', 'admin'}));
      expect(session.expiresAt, equals(DateTime.utc(2026, 1, 1, 13, 0)));
    });

    test('get() returns null for unknown ID', () {
      expect(store.get('nonexistent'), isNull);
    });

    test('get() returns null for expired session', () {
      final id = store.create(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        userId: 'user-1',
        roles: {'social_worker'},
      );

      // Advance clock past TTL
      currentTime = DateTime.utc(2026, 1, 1, 13, 1);

      expect(store.get(id), isNull);
    });

    test('updateTokens() updates tokens and extends TTL', () {
      final id = store.create(
        accessToken: 'old-access',
        refreshToken: 'old-refresh',
        userId: 'user-1',
        roles: {'social_worker'},
      );

      // Advance clock by 30 minutes (still valid)
      currentTime = DateTime.utc(2026, 1, 1, 12, 30);

      final result = store.updateTokens(
        id,
        accessToken: 'new-access',
        refreshToken: 'new-refresh',
      );

      expect(result, isTrue);

      final session = store.get(id);
      expect(session, isNotNull);
      expect(session!.accessToken, equals('new-access'));
      expect(session.refreshToken, equals('new-refresh'));
      // TTL extended from 12:30 + 1h = 13:30
      expect(session.expiresAt, equals(DateTime.utc(2026, 1, 1, 13, 30)));
      // Other fields unchanged
      expect(session.userId, equals('user-1'));
      expect(session.roles, equals({'social_worker'}));
    });

    test('updateTokens() returns false for expired session', () {
      final id = store.create(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        userId: 'user-1',
        roles: {'social_worker'},
      );

      // Advance past expiry
      currentTime = DateTime.utc(2026, 1, 1, 13, 1);

      final result = store.updateTokens(
        id,
        accessToken: 'new-access',
        refreshToken: 'new-refresh',
      );

      expect(result, isFalse);
      expect(store.get(id), isNull);
    });

    test('updateTokens() returns false for unknown session', () {
      final result = store.updateTokens(
        'nonexistent',
        accessToken: 'new-access',
        refreshToken: 'new-refresh',
      );

      expect(result, isFalse);
    });

    test('destroy() removes a session', () {
      final id = store.create(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        userId: 'user-1',
        roles: {'social_worker'},
      );

      expect(store.get(id), isNotNull);
      store.destroy(id);
      expect(store.get(id), isNull);
    });

    test(
      'destroyExpired() removes only expired sessions, keeps valid ones',
      () {
        // Create session at T=12:00, expires at T=13:00
        final earlyId = store.create(
          accessToken: 'access-early',
          refreshToken: 'refresh-early',
          userId: 'user-early',
          roles: {'social_worker'},
        );

        // Advance clock to 12:30, create another session expiring at 13:30
        currentTime = DateTime.utc(2026, 1, 1, 12, 30);
        final lateId = store.create(
          accessToken: 'access-late',
          refreshToken: 'refresh-late',
          userId: 'user-late',
          roles: {'admin'},
        );

        // Advance clock to 13:10 — early session expired, late session valid
        currentTime = DateTime.utc(2026, 1, 1, 13, 10);

        store.destroyExpired();

        expect(store.get(earlyId), isNull);
        expect(store.get(lateId), isNotNull);
      },
    );

    test('multiple sessions can coexist', () {
      final id1 = store.create(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        userId: 'user-1',
        roles: {'social_worker'},
      );
      final id2 = store.create(
        accessToken: 'access-2',
        refreshToken: 'refresh-2',
        userId: 'user-2',
        roles: {'admin'},
      );
      final id3 = store.create(
        accessToken: 'access-3',
        refreshToken: 'refresh-3',
        userId: 'user-3',
        roles: {'owner'},
      );

      expect(store.get(id1)?.userId, equals('user-1'));
      expect(store.get(id2)?.userId, equals('user-2'));
      expect(store.get(id3)?.userId, equals('user-3'));
    });
  });
}
