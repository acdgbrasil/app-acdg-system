/// W0.5 RED — `CredentialStore` interface + `FileCredentialStore` impl (D5).
///
/// W1 must create `apps/cli/lib/src/session/credential_store.dart` with:
///
/// ```dart
/// abstract interface class CredentialStore {
///   Future<Credentials?> read();
///   Future<void> write(Credentials credentials);
///   Future<void> clear();
/// }
///
/// final class Credentials with Equatable { ... accessToken, refreshToken, expiresAt }
///
/// final class FileCredentialStore implements CredentialStore {
///   FileCredentialStore({required this.path});
///   final String path;
///
///   /// XDG path resolution — D5.
///   /// `XDG_CONFIG_HOME` env var if set+non-empty, else `$HOME/.config`,
///   /// then suffixed with `/acdg/credentials`.
///   /// `env` is injectable so tests don't depend on Platform.environment.
///   static String defaultPath({required Map<String, String> env});
///
///   @override Future<Credentials?> read();
///   @override Future<void> write(Credentials credentials);
///   @override Future<void> clear();
/// }
/// ```
///
/// PKCE flow + chmod 600 + JSON serialization happen here too, but real
/// PKCE login lands in C02. C01 just needs read/write/clear correctness +
/// path resolution.
library;

import 'dart:io';

import 'package:test/test.dart';

import 'package:cli/src/session/credential_store.dart';

void main() {
  group('FileCredentialStore.defaultPath (XDG resolution — D5)', () {
    test('uses XDG_CONFIG_HOME when set and non-empty', () {
      final path = FileCredentialStore.defaultPath(env: {
        'XDG_CONFIG_HOME': '/custom/xdg',
        'HOME': '/home/user',
      });
      expect(path, equals('/custom/xdg/acdg/credentials'));
    });

    test('falls back to \$HOME/.config when XDG_CONFIG_HOME unset', () {
      final path = FileCredentialStore.defaultPath(env: {
        'HOME': '/home/user',
      });
      expect(path, equals('/home/user/.config/acdg/credentials'));
    });

    test('falls back when XDG_CONFIG_HOME is empty string', () {
      final path = FileCredentialStore.defaultPath(env: {
        'XDG_CONFIG_HOME': '',
        'HOME': '/home/user',
      });
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

    test('write then read returns the same Credentials', () async {
      final store = FileCredentialStore(path: tmpFile.path);
      final original = Credentials(
        accessToken: 'tok-abc',
        refreshToken: 'ref-xyz',
        expiresAt: DateTime.utc(2099, 1, 1),
      );

      await store.write(original);
      final readBack = await store.read();

      expect(readBack, isNotNull);
      expect(readBack!.accessToken, equals('tok-abc'));
      expect(readBack.refreshToken, equals('ref-xyz'));
      expect(readBack.expiresAt, equals(DateTime.utc(2099, 1, 1)));
    });

    test('read on missing file returns null (no throw)', () async {
      final store = FileCredentialStore(path: tmpFile.path);
      // tmpFile guaranteed not to exist (setUp just builds the path).
      expect(await tmpFile.exists(), isFalse);
      expect(await store.read(), isNull);
    });

    test('clear removes the credentials file', () async {
      final store = FileCredentialStore(path: tmpFile.path);
      await store.write(Credentials(
        accessToken: 'tok',
        refreshToken: 'ref',
        expiresAt: DateTime.utc(2099, 1, 1),
      ));
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
  Future<Credentials?> read() async => null;

  @override
  Future<void> write(Credentials credentials) async {}

  @override
  Future<void> clear() async {}
}
