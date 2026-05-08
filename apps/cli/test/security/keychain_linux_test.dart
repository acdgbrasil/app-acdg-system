/// B4 Wave 2 — RED tests for `KeychainLinuxAdapter`.
///
/// Adapter shells out to `secret-tool` (libsecret-tools). Critical
/// difference vs. macOS: the secret blob is piped via STDIN, NEVER on
/// argv — so `ps -ef` / `/proc/<pid>/cmdline` cannot disclose it.
///
/// Tests inject a fake `ProcessRunner` so:
///   1. real `Process.run` / `Process.start` is NEVER invoked,
///   2. real keychain entries are NEVER created,
///   3. argv shape is asserted byte-for-byte (DESIGN.md §4),
///   4. SECRET-IN-STDIN invariant is asserted (Stdin secrecy test).
///
/// EXPECTED STATE TODAY: RED.
/// `KeychainLinuxAdapter` and the error variants do not exist yet.
library;

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:core_contracts/core_contracts.dart';
import 'package:test/test.dart';

import 'package:cli/src/errors/cli_error.dart';
import 'package:cli/src/session/keychain_linux_adapter.dart';
import 'package:cli/src/session/oidc_session.dart';

void main() {
  group('KeychainLinuxAdapter — write', () {
    test('argv contains NO secret; secret arrives via stdinPayload', () async {
      final session = _fixtureSession();
      final blob = jsonEncode(session.toJson());

      final fake = _FakeRunner()..enqueue(_ok());
      final adapter = KeychainLinuxAdapter(
        service: 'com.acdgbrasil.acdg-cli',
        account: 'auth.acdgbrasil.com.br',
        processRunner: fake.call,
      );

      final result = await adapter.write(session);

      expect(result, isA<Success<void>>());

      // SEC: argv must be the constant-fragment list — no token anywhere.
      expect(
        fake.argvCalls[0],
        equals(<String>[
          'secret-tool',
          'store',
          '--label=ACDG CLI',
          'service',
          'com.acdgbrasil.acdg-cli',
          'account',
          'auth.acdgbrasil.com.br',
        ]),
      );

      // SEC: the secret JSON blob MUST be in stdin, not argv.
      expect(fake.stdinCalls[0], equals(blob));
      // Defense-in-depth — assert no token substring leaked into argv.
      for (final piece in fake.argvCalls[0]) {
        expect(
          piece.contains(session.accessToken),
          isFalse,
          reason: 'access token leaked into argv',
        );
        expect(
          piece.contains(session.refreshToken),
          isFalse,
          reason: 'refresh token leaked into argv',
        );
        expect(
          piece.contains(session.idToken),
          isFalse,
          reason: 'id token leaked into argv',
        );
      }
    });

    test('non-zero exit → Failure(KeychainOperationFailed)', () async {
      final fake = _FakeRunner()
        ..enqueue(_result(exit: 1, err: 'libsecret error'));
      final adapter = KeychainLinuxAdapter(
        service: 's',
        account: 'a',
        processRunner: fake.call,
      );

      final result = await adapter.write(_fixtureSession());

      expect(result, isA<Failure<void>>());
      final err = (result as Failure<void>).error;
      expect(err, isA<KeychainOperationFailed>());
      expect((err as KeychainOperationFailed).keychainExitCode, equals(1));
    });

    test(
      'ProcessException (binary missing) → KeychainUnavailable + hint',
      () async {
        final fake = _FakeRunner()
          ..enqueueException(
            const ProcessException(
              'secret-tool',
              <String>[],
              'No such file or directory',
              2,
            ),
          );
        final adapter = KeychainLinuxAdapter(
          service: 's',
          account: 'a',
          processRunner: fake.call,
        );

        final result = await adapter.write(_fixtureSession());

        expect(result, isA<Failure<void>>());
        final err = (result as Failure<void>).error;
        expect(err, isA<KeychainUnavailable>());
        // SEC: hint must surface the install command — operator visibility.
        final hint = (err as KeychainUnavailable).installHint;
        expect(hint.toLowerCase(), contains('libsecret'));
      },
    );
  });

  group('KeychainLinuxAdapter — read', () {
    test('exit 0 + JSON stdout → Success(session)', () async {
      final session = _fixtureSession();
      final blob = jsonEncode(session.toJson());
      final fake = _FakeRunner()..enqueue(_result(out: '$blob\n'));
      final adapter = KeychainLinuxAdapter(
        service: 'svc',
        account: 'acct',
        processRunner: fake.call,
      );

      final result = await adapter.read();

      expect(result, isA<Success<OidcSession?>>());
      final got = (result as Success<OidcSession?>).value;
      expect(got, isNotNull);
      expect(got!.accessToken, equals(session.accessToken));

      expect(
        fake.argvCalls[0],
        equals(<String>[
          'secret-tool',
          'lookup',
          'service',
          'svc',
          'account',
          'acct',
        ]),
      );
      // Read does not need stdin.
      expect(fake.stdinCalls[0], isNull);
    });

    test('exit 1 + empty stdout → Success(null) — entry not found', () async {
      final fake = _FakeRunner()..enqueue(_result(exit: 1, out: ''));
      final adapter = KeychainLinuxAdapter(
        service: 's',
        account: 'a',
        processRunner: fake.call,
      );

      final result = await adapter.read();

      expect(result, isA<Success<OidcSession?>>());
      expect((result as Success<OidcSession?>).value, isNull);
    });

    test('exit 0 + non-JSON stdout → Failure(KeychainCorruptEntry)', () async {
      final fake = _FakeRunner()..enqueue(_result(out: 'oops not json\n'));
      final adapter = KeychainLinuxAdapter(
        service: 's',
        account: 'a',
        processRunner: fake.call,
      );

      final result = await adapter.read();

      expect(result, isA<Failure<OidcSession?>>());
      expect(
        (result as Failure<OidcSession?>).error,
        isA<KeychainCorruptEntry>(),
      );
    });

    test('non-zero non-1 exit → Failure(KeychainOperationFailed)', () async {
      final fake = _FakeRunner()
        ..enqueue(_result(exit: 2, err: 'dbus failure'));
      final adapter = KeychainLinuxAdapter(
        service: 's',
        account: 'a',
        processRunner: fake.call,
      );

      final result = await adapter.read();

      expect(result, isA<Failure<OidcSession?>>());
      expect(
        (result as Failure<OidcSession?>).error,
        isA<KeychainOperationFailed>(),
      );
    });

    test('ProcessException (binary missing) → KeychainUnavailable', () async {
      final fake = _FakeRunner()
        ..enqueueException(
          const ProcessException(
            'secret-tool',
            <String>[],
            'No such file or directory',
            2,
          ),
        );
      final adapter = KeychainLinuxAdapter(
        service: 's',
        account: 'a',
        processRunner: fake.call,
      );

      final result = await adapter.read();

      expect(result, isA<Failure<OidcSession?>>());
      expect(
        (result as Failure<OidcSession?>).error,
        isA<KeychainUnavailable>(),
      );
    });
  });

  group('KeychainLinuxAdapter — delete', () {
    test('exit 0 → Success(void)', () async {
      final fake = _FakeRunner()..enqueue(_ok());
      final adapter = KeychainLinuxAdapter(
        service: 'svc',
        account: 'acct',
        processRunner: fake.call,
      );

      final result = await adapter.delete();

      expect(result, isA<Success<void>>());
      expect(
        fake.argvCalls[0],
        equals(<String>[
          'secret-tool',
          'clear',
          'service',
          'svc',
          'account',
          'acct',
        ]),
      );
    });

    test('ProcessException → KeychainUnavailable', () async {
      final fake = _FakeRunner()
        ..enqueueException(
          const ProcessException('secret-tool', <String>[], 'ENOENT', 2),
        );
      final adapter = KeychainLinuxAdapter(
        service: 's',
        account: 'a',
        processRunner: fake.call,
      );

      final result = await adapter.delete();

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<KeychainUnavailable>());
    });
  });

  group('KeychainLinuxAdapter — argv injection-proof', () {
    test(
      'account with shell metacharacters lands as ONE argv element',
      () async {
        const evil = '"; rm -rf /';
        final fake = _FakeRunner()..enqueue(_ok());
        final adapter = KeychainLinuxAdapter(
          service: 'svc',
          account: evil,
          processRunner: fake.call,
        );

        await adapter.write(_fixtureSession());

        final argv = fake.argvCalls[0];
        final accountIdx = argv.indexOf('account') + 1;
        expect(accountIdx, greaterThan(0));
        expect(argv[accountIdx], equals(evil));
        // SEC: `rm` must not appear as its own argv element.
        expect(argv.where((a) => a == 'rm'), isEmpty);
      },
    );

    test(
      'SECRET STDIN: token never appears in argv even with adversarial JSON',
      () async {
        // Build a session whose access token looks like a shell command.
        final adversarial = OidcSession(
          accessToken: '"; cat /etc/passwd; "',
          refreshToken: 'r',
          idToken: 'i',
          accessExpiresAt: DateTime.utc(2099, 1, 1),
          sub: 's',
          email: 'e@e',
          roles: const [],
        );
        final blob = jsonEncode(adversarial.toJson());

        final fake = _FakeRunner()..enqueue(_ok());
        final adapter = KeychainLinuxAdapter(
          service: 'svc',
          account: 'acct',
          processRunner: fake.call,
        );

        await adapter.write(adversarial);

        // SEC: the entire blob (and the adversarial token within) must arrive
        // through stdin — argv must be untouched.
        expect(fake.stdinCalls[0], equals(blob));
        for (final arg in fake.argvCalls[0]) {
          expect(
            arg.contains('cat /etc/passwd'),
            isFalse,
            reason: 'adversarial token leaked into argv',
          );
          expect(
            arg.contains(adversarial.accessToken),
            isFalse,
            reason: 'access token leaked into argv',
          );
        }
      },
    );
  });
}

// ---------------------------------------------------------------------------
// Test doubles
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

ProcessResult _ok() => ProcessResult(0, 0, '', '');

ProcessResult _result({int exit = 0, String out = '', String err = ''}) =>
    ProcessResult(0, exit, out, err);

class _FakeRunner {
  final List<List<String>> argvCalls = [];
  final List<String?> stdinCalls = [];
  final Queue<Object> _queue = Queue<Object>();

  void enqueue(ProcessResult r) => _queue.add(r);
  void enqueueException(Object e) => _queue.add(_Throw(e));

  Future<ProcessResult> call(
    String executable,
    List<String> arguments, {
    String? stdinPayload,
  }) async {
    argvCalls.add([executable, ...arguments]);
    stdinCalls.add(stdinPayload);
    final next = _queue.removeFirst();
    if (next is _Throw) throw next.error;
    return next as ProcessResult;
  }
}

class _Throw {
  const _Throw(this.error);
  final Object error;
}
