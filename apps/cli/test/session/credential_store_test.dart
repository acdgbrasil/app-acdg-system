/// W1 GREEN — `CredentialStore` interface + `FileCredentialStore` impl (D5).
///
/// W0 left this file using the C01 `Credentials` fixture. Per W0 REPORT
/// §4.1 Strategy A, W1 owns the migration: the contract under test is now
/// `Future<OidcSession?> read()` / `Future<void> write(OidcSession)` /
/// `Future<void> clear()`. The verb shape is identical — only the value
/// type changed. Test intent is preserved: round-trip persistence, missing
/// file = null (no throw), clear is idempotent, foreign-impl works.
library;

import 'dart:io';

import 'package:test/test.dart';

import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

void main() {
  group('FileCredentialStore.defaultPath (XDG resolution — D5)', () {
    test('uses XDG_CONFIG_HOME when set and non-empty', () {
      final path = FileCredentialStore.defaultPath(
        env: {'XDG_CONFIG_HOME': '/custom/xdg', 'HOME': '/home/user'},
      );
      expect(path, equals('/custom/xdg/acdg/credentials'));
    });

    test('falls back to \$HOME/.config when XDG_CONFIG_HOME unset', () {
      final path = FileCredentialStore.defaultPath(env: {'HOME': '/home/user'});
      expect(path, equals('/home/user/.config/acdg/credentials'));
    });

    test('falls back when XDG_CONFIG_HOME is empty string', () {
      final path = FileCredentialStore.defaultPath(
        env: {'XDG_CONFIG_HOME': '', 'HOME': '/home/user'},
      );
      expect(path, equals('/home/user/.config/acdg/credentials'));
    });
  });

  group('FileCredentialStore.read/write/clear', () {
    late File tmpFile;

    setUp(() {
      tmpFile = File(
        '${Directory.systemTemp.path}/acdg-creds-${DateTime.now().microsecondsSinceEpoch}',
      );
    });

    tearDown(() async {
      if (await tmpFile.exists()) {
        await tmpFile.delete();
      }
    });

    test('write then read returns the same OidcSession', () async {
      final store = FileCredentialStore(path: tmpFile.path);
      final original = OidcSession(
        accessToken: 'tok-abc',
        refreshToken: 'ref-xyz',
        idToken: 'id-eyJ',
        accessExpiresAt: DateTime.utc(2099, 1, 1),
        sub: '363088829932634233',
        email: 'user@example.com',
        roles: const ['social_worker'],
      );

      await store.write(original);
      final readBack = await store.read();

      expect(readBack, isNotNull);
      expect(readBack!.accessToken, equals('tok-abc'));
      expect(readBack.refreshToken, equals('ref-xyz'));
      expect(readBack.idToken, equals('id-eyJ'));
      expect(readBack.accessExpiresAt, equals(DateTime.utc(2099, 1, 1)));
      expect(readBack.sub, equals('363088829932634233'));
      expect(readBack.email, equals('user@example.com'));
      expect(readBack.roles, equals(['social_worker']));
    });

    test('read on missing file returns null (no throw)', () async {
      final store = FileCredentialStore(path: tmpFile.path);
      expect(await tmpFile.exists(), isFalse);
      expect(await store.read(), isNull);
    });

    test('clear removes the credentials file', () async {
      final store = FileCredentialStore(path: tmpFile.path);
      await store.write(
        OidcSession(
          accessToken: 'tok',
          refreshToken: 'ref',
          idToken: 'id',
          accessExpiresAt: DateTime.utc(2099, 1, 1),
          sub: 's',
          email: 'e@e',
          roles: const [],
        ),
      );
      expect(await tmpFile.exists(), isTrue);

      await store.clear();

      expect(await tmpFile.exists(), isFalse);
    });

    test('clear on missing file is a no-op (no throw)', () async {
      final store = FileCredentialStore(path: tmpFile.path);
      expect(await tmpFile.exists(), isFalse);
      // Must not throw — `acdg auth logout` after a fresh install hits this path.
      await store.clear();
      expect(await tmpFile.exists(), isFalse);
    });
  });

  group('CredentialStore (abstract interface — H5)', () {
    test('is implementable from foreign code', () {
      const CredentialStore store = _ExternalFakeStore();
      expect(store, isA<CredentialStore>());
    });
  });
}

/// Lives outside `package:cli/...` to prove the interface is implementable
/// across library boundaries (H5).
class _ExternalFakeStore implements CredentialStore {
  const _ExternalFakeStore();

  @override
  Future<OidcSession?> read() async => null;

  @override
  Future<void> write(OidcSession session) async {}

  @override
  Future<void> clear() async {}
}
