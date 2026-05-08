/// B4 Wave 2 — RED tests for `KeychainMacosAdapter`.
///
/// Adapter shells out to `/usr/bin/security` (always present on macOS).
/// Tests inject a fake `ProcessRunner` so:
///   1. real `Process.run` is NEVER invoked,
///   2. real keychain entries are NEVER created,
///   3. argv shape is asserted byte-for-byte (locking the design contract
///      from B4 DESIGN.md §3),
///   4. argv-injection scenarios prove that shell metacharacters in
///      `account` / `service` land as a single literal positional argument
///      (no shell parses them — `Process.run(exe, [args])` form).
///
/// EXPECTED STATE TODAY: RED.
/// `KeychainMacosAdapter`, `ProcessRunner`, `KeychainUnavailable`,
/// `KeychainOperationFailed`, `KeychainCorruptEntry` do not exist yet —
/// Wave 3 will introduce them.
library;

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:core_contracts/core_contracts.dart';
import 'package:test/test.dart';

import 'package:cli/src/errors/cli_error.dart';
import 'package:cli/src/session/keychain_macos_adapter.dart';
import 'package:cli/src/session/oidc_session.dart';

void main() {
  group('KeychainMacosAdapter — write', () {
    test(
      'issues exact argv to /usr/bin/security and returns Success',
      () async {
        final session = _fixtureSession();
        final blob = jsonEncode(session.toJson());

        final fake = _FakeRunner()..enqueue(_ok());
        final adapter = KeychainMacosAdapter(
          service: 'com.acdgbrasil.acdg-cli',
          account: 'auth.acdgbrasil.com.br',
          processRunner: fake.call,
        );

        final result = await adapter.write(session);

        expect(result, isA<Success<void>>());
        expect(fake.argvCalls, hasLength(1));
        // SEC: argv form locks the design contract — `-w <blob>` is the LAST
        // positional, accepted as LIM-2 tradeoff (~10ms ps race window).
        expect(
          fake.argvCalls[0],
          equals(<String>[
            '/usr/bin/security',
            'add-generic-password',
            '-U',
            '-s',
            'com.acdgbrasil.acdg-cli',
            '-a',
            'auth.acdgbrasil.com.br',
            '-w',
            blob,
          ]),
        );
        // Write does NOT use stdin on macOS (`security` has no -w stdin path).
        expect(fake.stdinCalls[0], isNull);
      },
    );

    test('non-zero exit → Failure(KeychainOperationFailed)', () async {
      final fake = _FakeRunner()..enqueue(_result(exit: 25, err: 'denied'));
      final adapter = KeychainMacosAdapter(
        service: 's',
        account: 'a',
        processRunner: fake.call,
      );

      final result = await adapter.write(_fixtureSession());

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<KeychainOperationFailed>());
      final err = result.error as KeychainOperationFailed;
      expect(err.keychainExitCode, equals(25));
      expect(err.stderrSummary, contains('denied'));
    });

    test('ProcessException → Failure(KeychainUnavailable)', () async {
      final fake = _FakeRunner()
        ..enqueueException(
          const ProcessException(
            '/usr/bin/security',
            <String>[],
            'no such file',
            2,
          ),
        );
      final adapter = KeychainMacosAdapter(
        service: 's',
        account: 'a',
        processRunner: fake.call,
      );

      final result = await adapter.write(_fixtureSession());

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<KeychainUnavailable>());
      final err = result.error as KeychainUnavailable;
      expect(err.binary, equals('security'));
    });
  });

  group('KeychainMacosAdapter — read', () {
    test('exit 0 + JSON on stdout → Success(session)', () async {
      final session = _fixtureSession();
      final blob = jsonEncode(session.toJson());

      // SEC: `-w` echoes the password literal followed by '\n' — the
      // adapter must trim ONE trailing newline only.
      final fake = _FakeRunner()..enqueue(_result(out: '$blob\n'));
      final adapter = KeychainMacosAdapter(
        service: 'svc',
        account: 'acct',
        processRunner: fake.call,
      );

      final result = await adapter.read();

      expect(result, isA<Success<OidcSession?>>());
      final got = (result as Success<OidcSession?>).value;
      expect(got, isNotNull);
      expect(got!.accessToken, equals(session.accessToken));
      expect(got.refreshToken, equals(session.refreshToken));
      expect(got.sub, equals(session.sub));

      expect(
        fake.argvCalls[0],
        equals(<String>[
          '/usr/bin/security',
          'find-generic-password',
          '-s',
          'svc',
          '-a',
          'acct',
          '-w',
        ]),
      );
    });

    test('exit 44 (errSecItemNotFound) → Success(null)', () async {
      final fake = _FakeRunner()..enqueue(_result(exit: 44));
      final adapter = KeychainMacosAdapter(
        service: 's',
        account: 'a',
        processRunner: fake.call,
      );

      final result = await adapter.read();

      expect(result, isA<Success<OidcSession?>>());
      expect((result as Success<OidcSession?>).value, isNull);
    });

    test('exit 0 + non-JSON stdout → Failure(KeychainCorruptEntry)', () async {
      final fake = _FakeRunner()..enqueue(_result(out: 'not-json\n'));
      final adapter = KeychainMacosAdapter(
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

    test(
      'exit 0 + JSON of wrong shape (array) → KeychainCorruptEntry',
      () async {
        final fake = _FakeRunner()..enqueue(_result(out: '[1,2,3]\n'));
        final adapter = KeychainMacosAdapter(
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
      },
    );

    test('non-zero non-44 exit → Failure(KeychainOperationFailed)', () async {
      final fake = _FakeRunner()..enqueue(_result(exit: 17, err: 'oops'));
      final adapter = KeychainMacosAdapter(
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

    test('ProcessException on read → Failure(KeychainUnavailable)', () async {
      final fake = _FakeRunner()
        ..enqueueException(
          const ProcessException(
            '/usr/bin/security',
            <String>[],
            'binary missing',
            2,
          ),
        );
      final adapter = KeychainMacosAdapter(
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

  group('KeychainMacosAdapter — delete', () {
    test('exit 0 → Success(void)', () async {
      final fake = _FakeRunner()..enqueue(_ok());
      final adapter = KeychainMacosAdapter(
        service: 'svc',
        account: 'acct',
        processRunner: fake.call,
      );

      final result = await adapter.delete();

      expect(result, isA<Success<void>>());
      expect(
        fake.argvCalls[0],
        equals(<String>[
          '/usr/bin/security',
          'delete-generic-password',
          '-s',
          'svc',
          '-a',
          'acct',
        ]),
      );
    });

    test('exit 44 (already absent) → Success(void) — idempotent', () async {
      final fake = _FakeRunner()..enqueue(_result(exit: 44));
      final adapter = KeychainMacosAdapter(
        service: 's',
        account: 'a',
        processRunner: fake.call,
      );

      final result = await adapter.delete();

      expect(result, isA<Success<void>>());
    });

    test('non-zero non-44 → Failure(KeychainOperationFailed)', () async {
      final fake = _FakeRunner()..enqueue(_result(exit: 1, err: 'denied'));
      final adapter = KeychainMacosAdapter(
        service: 's',
        account: 'a',
        processRunner: fake.call,
      );

      final result = await adapter.delete();

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<KeychainOperationFailed>());
    });
  });

  group('KeychainMacosAdapter — argv injection-proof', () {
    test(
      'account containing shell metacharacters lands as a SINGLE argv arg',
      () async {
        // SEC: classic shell-injection payload — if anyone ever switched to
        // `runInShell: true` or string-concatenated a command, this would
        // execute `rm -rf /`. With `Process.run(exe, [args])` it's just a
        // string passed to execve(2) as one C string.
        const evilAccount = '"; rm -rf /';
        final fake = _FakeRunner()..enqueue(_ok());
        final adapter = KeychainMacosAdapter(
          service: 'com.acdgbrasil.acdg-cli',
          account: evilAccount,
          processRunner: fake.call,
        );

        await adapter.write(_fixtureSession());

        final argv = fake.argvCalls[0];
        // SEC: account must appear as ONE argv element at the canonical index
        // (after `-a`), not split across multiple args, not interpreted.
        final accountIdx = argv.indexOf('-a') + 1;
        expect(accountIdx, greaterThan(0));
        expect(argv[accountIdx], equals(evilAccount));
        // SEC: assert no shell metachar leaked elsewhere — in particular, the
        // `rm` token must not appear as its own argv element.
        expect(argv.where((a) => a == 'rm'), isEmpty);
        expect(argv.where((a) => a == '-rf'), isEmpty);
      },
    );

    test('service with newlines lands as a single arg', () async {
      const evilService = 'com.acdgbrasil.acdg-cli\ninjected';
      final fake = _FakeRunner()..enqueue(_ok());
      final adapter = KeychainMacosAdapter(
        service: evilService,
        account: 'a',
        processRunner: fake.call,
      );

      await adapter.write(_fixtureSession());

      final argv = fake.argvCalls[0];
      final serviceIdx = argv.indexOf('-s') + 1;
      expect(argv[serviceIdx], equals(evilService));
      // SEC: 'injected' must NOT appear as a separate argv element.
      expect(argv.where((a) => a == 'injected'), isEmpty);
    });
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

/// Fake `ProcessRunner` — records every (argv, stdinPayload) call and
/// dispenses pre-queued `ProcessResult`s (or throws pre-queued exceptions).
///
/// Pattern matches B4 DESIGN.md §10 verbatim — Wave 3 implementations
/// must accept this exact shape via their `processRunner` constructor arg.
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
