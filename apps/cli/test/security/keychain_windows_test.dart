/// B4 Wave 2 — RED tests for `KeychainWindowsAdapter`.
///
/// Adapter shells out to `powershell.exe` with DPAPI-encrypted storage at
/// `%LOCALAPPDATA%\acdg\creds.dpapi` (LIM-1 resolution: `cmdkey` cannot
/// read passwords; PowerShell `ConvertTo-SecureString` / `ConvertFrom-
/// SecureString` ride DPAPI per-user encryption + first-party tooling).
///
/// SEC: secret never on argv — token is piped via stdin into the
/// PowerShell process which calls `[Console]::In.ReadToEnd()`.
///
/// EXPECTED STATE TODAY: RED. `KeychainWindowsAdapter` does not exist.
///
/// Platform note: these unit tests are platform-agnostic — they inject a
/// fake `ProcessRunner`, so `powershell.exe` is never invoked. The only
/// platform-sensitive bits are file-existence tests, for which we use a
/// real temp directory created inside `Directory.systemTemp`.
library;

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:core_contracts/core_contracts.dart';
import 'package:test/test.dart';

import 'package:cli/src/errors/cli_error.dart';
import 'package:cli/src/session/keychain_windows_adapter.dart';
import 'package:cli/src/session/oidc_session.dart';

void main() {
  late Directory tempDir;
  late String storePath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('acdg-keychain-win-');
    storePath = '${tempDir.path}/creds.dpapi';
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('KeychainWindowsAdapter — write', () {
    test(
      'argv = powershell + base flags + script; secret in stdin only',
      () async {
        final session = _fixtureSession();
        final blob = jsonEncode(session.toJson());

        final fake = _FakeRunner()..enqueue(_ok());
        final adapter = KeychainWindowsAdapter(
          service: 'com.acdgbrasil.acdg-cli',
          account: 'auth.acdgbrasil.com.br',
          storePath: storePath,
          processRunner: fake.call,
        );

        final result = await adapter.write(session);

        expect(result, isA<Success<void>>());
        expect(fake.argvCalls, hasLength(1));

        final argv = fake.argvCalls[0];
        expect(argv[0], equals('powershell.exe'));
        // SEC: locked PowerShell flags — no profile, no interactive prompts,
        // bypass execution policy ONLY for our literal -Command string.
        expect(
          argv,
          containsAll(<String>[
            '-NoProfile',
            '-NonInteractive',
            '-ExecutionPolicy',
            'Bypass',
            '-Command',
          ]),
        );
        // The script payload is the LAST argv element.
        final script = argv.last;
        expect(script, contains(r'[Console]::In.ReadToEnd()'));
        expect(script, contains(r'ConvertTo-SecureString'));
        expect(script, contains(r'ConvertFrom-SecureString'));
        expect(script, contains("Set-Content -Path '$storePath'"));

        // SEC: the token blob MUST be in stdin, NOT argv.
        expect(fake.stdinCalls[0], equals(blob));
        for (final arg in argv) {
          expect(
            arg.contains(session.accessToken),
            isFalse,
            reason: 'access token leaked into argv',
          );
          expect(
            arg.contains(session.refreshToken),
            isFalse,
            reason: 'refresh token leaked into argv',
          );
        }
      },
    );

    test(
      'storePath containing single-quote → KeychainOperationFailed',
      () async {
        // SEC: defense-in-depth. `%LOCALAPPDATA%` is OS-controlled so this
        // branch should never fire in production, but the adapter must
        // refuse anyway because the script embeds the path inside a single-
        // quoted PowerShell literal.
        final fake = _FakeRunner();
        final adapter = KeychainWindowsAdapter(
          service: 's',
          account: 'a',
          storePath: r"C:\evil'path\creds.dpapi",
          processRunner: fake.call,
        );

        final result = await adapter.write(_fixtureSession());

        expect(result, isA<Failure<void>>());
        expect((result as Failure<void>).error, isA<KeychainOperationFailed>());
        // Runner must NEVER be called when path is invalid.
        expect(fake.argvCalls, isEmpty);
      },
    );

    test('non-zero exit → Failure(KeychainOperationFailed)', () async {
      final fake = _FakeRunner()..enqueue(_result(exit: 1, err: 'PS error'));
      final adapter = KeychainWindowsAdapter(
        service: 's',
        account: 'a',
        storePath: storePath,
        processRunner: fake.call,
      );

      final result = await adapter.write(_fixtureSession());

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<KeychainOperationFailed>());
    });

    test(
      'ProcessException → KeychainUnavailable (powershell missing)',
      () async {
        final fake = _FakeRunner()
          ..enqueueException(
            const ProcessException(
              'powershell.exe',
              <String>[],
              'No such file or directory',
              2,
            ),
          );
        final adapter = KeychainWindowsAdapter(
          service: 's',
          account: 'a',
          storePath: storePath,
          processRunner: fake.call,
        );

        final result = await adapter.write(_fixtureSession());

        expect(result, isA<Failure<void>>());
        final err = (result as Failure<void>).error;
        expect(err, isA<KeychainUnavailable>());
        expect((err as KeychainUnavailable).binary, contains('powershell'));
      },
    );
  });

  group('KeychainWindowsAdapter — read', () {
    test(
      'file does not exist → Success(null) without invoking PowerShell',
      () async {
        final fake = _FakeRunner();
        final adapter = KeychainWindowsAdapter(
          service: 's',
          account: 'a',
          storePath: storePath,
          processRunner: fake.call,
        );

        // Sanity — file must not exist for this branch.
        expect(await File(storePath).exists(), isFalse);

        final result = await adapter.read();

        expect(result, isA<Success<OidcSession?>>());
        expect((result as Success<OidcSession?>).value, isNull);
        // SEC: zero PowerShell invocations on the cold-start path.
        expect(fake.argvCalls, isEmpty);
      },
    );

    test(
      'file exists + PowerShell prints decrypted JSON → Success(session)',
      () async {
        // Plant a sentinel ciphertext (content irrelevant — fake runner
        // bypasses real DPAPI; only the file's existence drives the branch).
        await File(storePath).writeAsString('ciphertext-stub');

        final session = _fixtureSession();
        final blob = jsonEncode(session.toJson());
        // Decrypted output may end with CRLF on Windows; adapter must trim.
        final fake = _FakeRunner()..enqueue(_result(out: '$blob\r\n'));
        final adapter = KeychainWindowsAdapter(
          service: 's',
          account: 'a',
          storePath: storePath,
          processRunner: fake.call,
        );

        final result = await adapter.read();

        expect(result, isA<Success<OidcSession?>>());
        final got = (result as Success<OidcSession?>).value;
        expect(got, isNotNull);
        expect(got!.accessToken, equals(session.accessToken));

        // SEC: the read script reads the ciphertext file and runs Convert-
        // ToSecureString on its content — verify the right script ran.
        final script = fake.argvCalls[0].last;
        expect(script, contains("Get-Content -Path '$storePath'"));
        expect(script, contains(r'ConvertTo-SecureString'));
        expect(script, contains(r'NetworkCredential'));
      },
    );

    test(
      'PowerShell exit non-zero → Failure(KeychainOperationFailed)',
      () async {
        await File(storePath).writeAsString('ciphertext');
        final fake = _FakeRunner()
          ..enqueue(_result(exit: 1, err: 'decrypt failed'));
        final adapter = KeychainWindowsAdapter(
          service: 's',
          account: 'a',
          storePath: storePath,
          processRunner: fake.call,
        );

        final result = await adapter.read();

        expect(result, isA<Failure<OidcSession?>>());
        expect(
          (result as Failure<OidcSession?>).error,
          isA<KeychainOperationFailed>(),
        );
      },
    );

    test('exit 0 + non-JSON stdout → Failure(KeychainCorruptEntry)', () async {
      await File(storePath).writeAsString('ciphertext');
      final fake = _FakeRunner()..enqueue(_result(out: 'oops not json\r\n'));
      final adapter = KeychainWindowsAdapter(
        service: 's',
        account: 'a',
        storePath: storePath,
        processRunner: fake.call,
      );

      final result = await adapter.read();

      expect(result, isA<Failure<OidcSession?>>());
      expect(
        (result as Failure<OidcSession?>).error,
        isA<KeychainCorruptEntry>(),
      );
    });

    test('ProcessException on read → KeychainUnavailable', () async {
      await File(storePath).writeAsString('ciphertext');
      final fake = _FakeRunner()
        ..enqueueException(
          const ProcessException('powershell.exe', <String>[], 'missing', 2),
        );
      final adapter = KeychainWindowsAdapter(
        service: 's',
        account: 'a',
        storePath: storePath,
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

  group('KeychainWindowsAdapter — delete', () {
    test(
      'exit 0 → Success(void); script invokes Remove-Item if present',
      () async {
        final fake = _FakeRunner()..enqueue(_ok());
        final adapter = KeychainWindowsAdapter(
          service: 's',
          account: 'a',
          storePath: storePath,
          processRunner: fake.call,
        );

        final result = await adapter.delete();

        expect(result, isA<Success<void>>());
        final script = fake.argvCalls[0].last;
        expect(script, contains("Test-Path '$storePath'"));
        expect(script, contains("Remove-Item '$storePath'"));
      },
    );

    test('non-zero exit → Failure(KeychainOperationFailed)', () async {
      final fake = _FakeRunner()..enqueue(_result(exit: 1, err: 'denied'));
      final adapter = KeychainWindowsAdapter(
        service: 's',
        account: 'a',
        storePath: storePath,
        processRunner: fake.call,
      );

      final result = await adapter.delete();

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<KeychainOperationFailed>());
    });
  });

  group('KeychainWindowsAdapter — argv injection-proof', () {
    test(
      'SECRET STDIN: token never on argv even with adversarial JSON',
      () async {
        final adversarial = OidcSession(
          accessToken: '"; rm -rf /; ',
          refreshToken: 'r',
          idToken: 'i',
          accessExpiresAt: DateTime.utc(2099, 1, 1),
          sub: 's',
          email: 'e@e',
          roles: const [],
        );
        final blob = jsonEncode(adversarial.toJson());

        final fake = _FakeRunner()..enqueue(_ok());
        final adapter = KeychainWindowsAdapter(
          service: 'com.acdgbrasil.acdg-cli',
          account: 'acct',
          storePath: storePath,
          processRunner: fake.call,
        );

        await adapter.write(adversarial);

        expect(fake.stdinCalls[0], equals(blob));
        for (final arg in fake.argvCalls[0]) {
          expect(
            arg.contains(adversarial.accessToken),
            isFalse,
            reason: 'access token leaked into argv',
          );
          expect(
            arg.contains('rm -rf'),
            isFalse,
            reason: 'shell payload leaked into argv',
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
