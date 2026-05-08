/// B4 Wave 2 — RED tests for the migration shim inside
/// `CredentialStoreFactory` + `KeychainCredentialStore` wrapper.
///
/// Migration semantics — DESIGN.md §6, §7, §8:
///   1. Cold start (no file, no keychain): no-op.
///   2. File-only (legacy plaintext exists, keychain empty): read file →
///      write keychain → read-after-write verify → delete file.
///   3. Keychain-only (canonical): no-op (file does not exist).
///   4. Both populated: keychain canonical → delete legacy file.
///   5. Write-fails-during-migration (CRITICAL): keychain.write fails →
///      file IS NOT deleted (no token loss). Operator gets fail-loud
///      stderr at next read.
///
/// Tests exercise the shim through a `_FakeKeychainAdapter` so we never
/// touch real OS keychains. The legacy `FileCredentialStore` is real
/// (its file I/O is its own code path; that file's tests already cover
/// the read/write cycle).
///
/// EXPECTED STATE TODAY: RED.
/// `CredentialStoreFactory`, `KeychainCredentialStore`, `KeychainAdapter`
/// do not exist yet — Wave 3 will introduce them.
library;

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:core_contracts/core_contracts.dart';
import 'package:test/test.dart';

import 'package:cli/src/errors/cli_error.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/credential_store_factory.dart';
import 'package:cli/src/session/keychain_adapter.dart';
import 'package:cli/src/session/oidc_session.dart';

void main() {
  late Directory tempDir;
  late String legacyPath;
  late Map<String, String> env;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('acdg-creds-mig-');
    // Mirror FileCredentialStore.defaultPath layout: <XDG>/acdg/credentials.
    env = {'XDG_CONFIG_HOME': tempDir.path, 'HOME': tempDir.path};
    legacyPath = FileCredentialStore.defaultPath(env: env);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('CredentialStoreFactory.migrate — five scenarios', () {
    test('1. cold start — no file, no keychain → no-op', () async {
      final adapter = _FakeKeychainAdapter()
        // first call inside factory: keychainStore.read() returns null
        ..queueRead(const Success<OidcSession?>(null));

      // Sanity: legacy file does not exist.
      expect(await File(legacyPath).exists(), isFalse);

      final store = await CredentialStoreFactory.migrateForTest(
        keychain: adapter,
        env: env,
      );

      expect(store, isA<CredentialStore>());
      // No write should have been called — nothing to migrate.
      expect(adapter.writeCalls, isEmpty);
      // No legacy file → no clear() either.
      expect(adapter.deleteCalls, isEmpty);
      expect(await File(legacyPath).exists(), isFalse);
    });

    test(
      '2. file-only (legacy plaintext) → migrated to keychain + deleted',
      () async {
        // Plant a legacy plaintext file.
        final session = _fixtureSession();
        await _plantLegacyFile(legacyPath, session);
        expect(await File(legacyPath).exists(), isTrue);

        final adapter = _FakeKeychainAdapter()
          // 1st read (factory check) → empty
          ..queueRead(const Success<OidcSession?>(null))
          // write → success
          ..queueWrite(const Success<void>(null))
          // 2nd read (read-after-write verify) → returns the session
          ..queueRead(Success<OidcSession?>(session));

        await CredentialStoreFactory.migrateForTest(
          keychain: adapter,
          env: env,
        );

        // SEC: write was called with the migrated session.
        expect(adapter.writeCalls, hasLength(1));
        expect(adapter.writeCalls[0].accessToken, equals(session.accessToken));
        // Legacy file MUST be deleted post-verify.
        expect(await File(legacyPath).exists(), isFalse);
      },
    );

    test('3. keychain-only — keychain populated, no file → no-op', () async {
      expect(await File(legacyPath).exists(), isFalse);
      final session = _fixtureSession();

      final adapter = _FakeKeychainAdapter()
        ..queueRead(Success<OidcSession?>(session));

      await CredentialStoreFactory.migrateForTest(keychain: adapter, env: env);

      // SEC: keychain already canonical — never write again.
      expect(adapter.writeCalls, isEmpty);
      // No legacy file → no delete needed.
      expect(adapter.deleteCalls, isEmpty);
      expect(await File(legacyPath).exists(), isFalse);
    });

    test(
      '4. both populated — keychain canonical, legacy file deleted',
      () async {
        final session = _fixtureSession();
        await _plantLegacyFile(legacyPath, session);
        expect(await File(legacyPath).exists(), isTrue);

        final adapter = _FakeKeychainAdapter()
          // factory check: keychain already has session
          ..queueRead(Success<OidcSession?>(session));

        await CredentialStoreFactory.migrateForTest(
          keychain: adapter,
          env: env,
        );

        // Keychain is canonical — never re-write.
        expect(adapter.writeCalls, isEmpty);
        // Legacy file MUST be deleted (stale plaintext is the bug we fix).
        expect(await File(legacyPath).exists(), isFalse);
      },
    );

    test(
      '5. write-fails-during-migration — file PRESERVED (no token loss)',
      () async {
        final session = _fixtureSession();
        await _plantLegacyFile(legacyPath, session);
        expect(await File(legacyPath).exists(), isTrue);

        final adapter = _FakeKeychainAdapter()
          // factory check: keychain empty
          ..queueRead(const Success<OidcSession?>(null))
          // write → fail
          ..queueWrite(
            const Failure<void>(
              KeychainOperationFailed(1, 'simulated keychain unavailable'),
            ),
          );

        await CredentialStoreFactory.migrateForTest(
          keychain: adapter,
          env: env,
        );

        // SEC: write was attempted...
        expect(adapter.writeCalls, hasLength(1));
        // ... but failed, so the legacy plaintext MUST be preserved.
        // Losing it would orphan the user (no path to recover the session).
        expect(
          await File(legacyPath).exists(),
          isTrue,
          reason: 'legacy file MUST NOT be deleted when keychain.write fails',
        );

        // And the on-disk content must still be the original session JSON.
        final decoded = jsonDecode(await File(legacyPath).readAsString());
        expect(decoded, isA<Map<String, Object?>>());
        expect((decoded as Map)['access_token'], equals(session.accessToken));
      },
    );
  });

  group('KeychainCredentialStore wrapper', () {
    test(
      'read() returns null on Failure (no exception across boundary)',
      () async {
        final adapter = _FakeKeychainAdapter()
          ..queueRead(const Failure<OidcSession?>(KeychainCorruptEntry()));
        final store = KeychainCredentialStore(adapter: adapter);

        final got = await store.read();

        expect(got, isNull);
      },
    );

    test('read() returns the session on Success', () async {
      final session = _fixtureSession();
      final adapter = _FakeKeychainAdapter()
        ..queueRead(Success<OidcSession?>(session));
      final store = KeychainCredentialStore(adapter: adapter);

      final got = await store.read();

      expect(got, isNotNull);
      expect(got!.accessToken, equals(session.accessToken));
    });

    test('write() succeeds when adapter returns Success', () async {
      final adapter = _FakeKeychainAdapter()
        ..queueWrite(const Success<void>(null));
      final store = KeychainCredentialStore(adapter: adapter);

      // Must not throw.
      await store.write(_fixtureSession());

      expect(adapter.writeCalls, hasLength(1));
    });

    test(
      'write() throws StateError on Failure (fail-loud, no silent regress)',
      () async {
        final adapter = _FakeKeychainAdapter()
          ..queueWrite(
            const Failure<void>(KeychainOperationFailed(1, 'denied')),
          );
        final store = KeychainCredentialStore(adapter: adapter);

        // SEC: silent success on write failure would lose the user's session
        // without warning — fail loud.
        await expectLater(
          () => store.write(_fixtureSession()),
          throwsA(isA<StateError>()),
        );
      },
    );

    test('clear() is idempotent regardless of adapter delete result', () async {
      final adapter = _FakeKeychainAdapter()
        ..queueDelete(const Success<void>(null));
      final store = KeychainCredentialStore(adapter: adapter);

      // Must not throw on first call (Success path).
      await store.clear();
      expect(adapter.deleteCalls, hasLength(1));

      // Even on Failure, clear() must not throw — subsequent reads return
      // null and the user can re-auth.
      adapter.queueDelete(
        const Failure<void>(KeychainOperationFailed(1, 'denied')),
      );
      await store.clear();
      expect(adapter.deleteCalls, hasLength(2));
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

OidcSession _fixtureSession() => OidcSession(
  accessToken: 'tok-access',
  refreshToken: 'tok-refresh',
  idToken: 'tok-id',
  accessExpiresAt: DateTime.utc(2099, 1, 1),
  sub: '363088829932634233',
  email: 'user@example.com',
  roles: const ['social_worker'],
);

Future<void> _plantLegacyFile(String path, OidcSession session) async {
  // Write the JSON shape that `FileCredentialStore.write` would produce.
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(session.toJson()));
}

/// Fake [KeychainAdapter] — records calls and dispenses canned [Result]s.
///
/// Production [KeychainAdapter] returns three method shapes:
///   * `write   → Future<Result<void>>`
///   * `read    → Future<Result<OidcSession?>>`
///   * `delete  → Future<Result<void>>`
class _FakeKeychainAdapter implements KeychainAdapter {
  final Queue<Result<OidcSession?>> _readQueue = Queue();
  final Queue<Result<void>> _writeQueue = Queue();
  final Queue<Result<void>> _deleteQueue = Queue();

  final List<OidcSession> writeCalls = [];
  // SEC: TYPO FIX — Wave 2 test fixture used `int` here, but every
  // assertion in this file (lines 73, 119, 242, 250) treats the field
  // as a collection (`isEmpty`, `hasLength(1)`). Aligning the field to
  // a `List` so the contract the assertions express is the contract
  // the fake exposes. (REGRA #2 typo exception — no semantic change.)
  final List<Object?> readCalls = <Object?>[];
  final List<Object?> deleteCalls = <Object?>[];

  void queueRead(Result<OidcSession?> r) => _readQueue.add(r);
  void queueWrite(Result<void> r) => _writeQueue.add(r);
  void queueDelete(Result<void> r) => _deleteQueue.add(r);

  @override
  Future<Result<OidcSession?>> read() async {
    readCalls.add(null);
    if (_readQueue.isEmpty) {
      // Default to "not found" when the test under-specifies — a well-
      // written test will always queue, this guard protects against
      // accidental hangs.
      return const Success<OidcSession?>(null);
    }
    return _readQueue.removeFirst();
  }

  @override
  Future<Result<void>> write(OidcSession session) async {
    writeCalls.add(session);
    if (_writeQueue.isEmpty) return const Success<void>(null);
    return _writeQueue.removeFirst();
  }

  @override
  Future<Result<void>> delete() async {
    deleteCalls.add(null);
    if (_deleteQueue.isEmpty) return const Success<void>(null);
    return _deleteQueue.removeFirst();
  }
}
