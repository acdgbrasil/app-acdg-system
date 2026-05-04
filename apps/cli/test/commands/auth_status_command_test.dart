/// W0 RED — `AuthStatusCommand` contract (C02).
///
/// W1 must create `apps/cli/lib/src/commands/auth_status_command.dart`:
///
/// ```dart
/// class AuthStatusCommand extends Command<int> {
///   AuthStatusCommand({
///     required this.credentialStore,
///     this.now,
///     this.stdout,
///     this.stderr,
///   });
///
///   final CredentialStore credentialStore;
///   final DateTime Function()? now;  // injectable wall-clock for tests
///   final StringSink? stdout;
///   final StringSink? stderr;
///
///   @override String get name => 'status';
///   @override Future<int> run();
/// }
/// ```
///
/// Exit codes:
///   * 0 = logged in, session valid
///   * 1 = no session
///   * 2 = session expired (suggest re-login)
library;

import 'package:args/command_runner.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/auth_status_command.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

void main() {
  group('AuthStatusCommand basics', () {
    test('extends Command<int> with name "status"', () {
      final cmd = AuthStatusCommand(credentialStore: _FakeStore());
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('status'));
      expect(cmd.description, isNotEmpty);
    });
  });

  group('AuthStatusCommand — no session', () {
    test('exits 1 and prints "Not logged in"', () async {
      final stdout = StringBuffer();
      final stderr = StringBuffer();
      final cmd = AuthStatusCommand(
        credentialStore: _FakeStore(),
        stdout: stdout,
        stderr: stderr,
      );

      final exitCode = await cmd.run();

      expect(exitCode, equals(1));
      final out = (stdout.toString() + stderr.toString()).toLowerCase();
      expect(out, contains('not logged in'));
    });
  });

  group('AuthStatusCommand — valid session', () {
    test('exits 0 and prints email + roles + expiration', () async {
      final now = DateTime.utc(2026, 1, 1, 12, 0, 0);
      final session = OidcSession(
        accessToken: 'at',
        refreshToken: 'rt',
        idToken: 'it',
        accessExpiresAt: now.add(const Duration(hours: 6)),
        sub: '363088829932634233',
        email: 'user@example.com',
        roles: const ['superadmin', 'owner', 'social_worker'],
      );
      final stdout = StringBuffer();
      final cmd = AuthStatusCommand(
        credentialStore: _FakeStore(stored: session),
        now: () => now,
        stdout: stdout,
      );

      final exitCode = await cmd.run();

      expect(exitCode, equals(0));
      final out = stdout.toString();
      expect(out, contains('user@example.com'));
      expect(out, contains('superadmin'));
      expect(out, anyOf(contains('Logged in'), contains('logged in')));
    });
  });

  group('AuthStatusCommand — expired session', () {
    test('exits 2 and suggests `acdg auth login`', () async {
      final now = DateTime.utc(2026, 1, 1, 12, 0, 0);
      final expiredSession = OidcSession(
        accessToken: 'at',
        refreshToken: 'rt',
        idToken: 'it',
        accessExpiresAt: now.subtract(const Duration(hours: 1)),
        sub: 's',
        email: 'user@example.com',
        roles: const ['social_worker'],
      );
      final stdout = StringBuffer();
      final stderr = StringBuffer();
      final cmd = AuthStatusCommand(
        credentialStore: _FakeStore(stored: expiredSession),
        now: () => now,
        stdout: stdout,
        stderr: stderr,
      );

      final exitCode = await cmd.run();

      expect(exitCode, equals(2));
      final out = (stdout.toString() + stderr.toString()).toLowerCase();
      expect(out, contains('expired'));
      expect(out, contains('acdg auth login'));
    });
  });
}

class _FakeStore implements CredentialStore {
  _FakeStore({this.stored});
  OidcSession? stored;

  @override
  Future<OidcSession?> read() async => stored;

  @override
  Future<void> write(OidcSession session) async {
    stored = session;
  }

  @override
  Future<void> clear() async {
    stored = null;
  }
}
