/// `acdg auth status` — show current login + roles + expiration.
///
/// Exit codes:
///   * 0 — logged in, session valid
///   * 1 — no session
///   * 2 — session expired (suggest re-login)
library;

import 'package:args/command_runner.dart';

import '../session/credential_store.dart';

/// `acdg auth status` — see file-level docstring.
final class AuthStatusCommand extends Command<int> {
  AuthStatusCommand({
    required this.credentialStore,
    this.now,
    this.stdout,
    this.stderr,
  });

  final CredentialStore credentialStore;
  final DateTime Function()? now;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'status';

  @override
  String get description => 'Show current login status, roles and expiration';

  @override
  Future<int> run() async {
    final session = await credentialStore.read();
    if (session == null) {
      _writeErr('Not logged in. Run: acdg auth login');
      return 1;
    }

    final clock = now?.call() ?? DateTime.now().toUtc();
    if (session.isExpired(now: clock)) {
      _writeErr(
        'Session expired (was valid until ${session.accessExpiresAt.toIso8601String()}).',
      );
      _writeErr('Run: acdg auth login');
      return 2;
    }

    _writeOut('Logged in as ${session.email}');
    if (session.roles.isNotEmpty) {
      _writeOut('Roles: ${session.roles.join(', ')}');
    }
    _writeOut(
      'Session valid until ${session.accessExpiresAt.toIso8601String()} '
      '(${_humanDelta(session.accessExpiresAt, clock)}).',
    );
    return 0;
  }

  String _humanDelta(DateTime target, DateTime from) {
    final delta = target.difference(from);
    if (delta.isNegative) return 'expired';
    final hours = delta.inHours;
    if (hours >= 1) {
      final minutes = delta.inMinutes - hours * 60;
      return 'in ${hours}h${minutes}m';
    }
    final minutes = delta.inMinutes;
    if (minutes >= 1) return 'in ${minutes}m';
    return 'in ${delta.inSeconds}s';
  }

  void _writeOut(String line) {
    final out = stdout;
    if (out != null) out.writeln(line);
  }

  void _writeErr(String line) {
    final err = stderr ?? stdout;
    if (err != null) err.writeln(line);
  }
}
