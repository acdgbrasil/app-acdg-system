/// `acdg team reset-password <member-id>` — kick off a password reset (C09).
///
/// Path-only **POST** `/team/<member-id>/reset-password` —
/// `ResetPasswordIntent.parseFromPath` has no body parser. The handler at
/// `team_handler.dart:92` deliberately routes this as POST (not PUT)
/// because the operation kicks off an out-of-band Zitadel side effect — the
/// semantics are "create reset request" rather than "update worker status",
/// even though it lives on the same `/team/<id>/...` namespace as the
/// PUT-based `deactivate`/`reactivate` verbs.
///
/// UUID v4 validation is enforced server-side; the CLI forwards the path
/// verbatim and surfaces `INVALID_RESET_PASSWORD_PARAMS` from the BFF when
/// a non-UUID id is passed. 200/204 → exit 0. 4xx/5xx → non-zero exit +
/// stderr.
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../errors/cli_error.dart';
import '../session/bff_client.dart';

/// `acdg team reset-password`.
final class TeamResetPasswordCommand extends Command<int> {
  TeamResetPasswordCommand({
    required this.bffClient,
    required this.formatter,
    this.stdout,
    this.stderr,
  });

  final BffClient bffClient;
  final OutputFormatter formatter;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'reset-password';

  @override
  String get description =>
      'Kick off a password reset for a team member (Zitadel side effect).';

  @override
  String get invocation => 'acdg team reset-password <member-id>';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      usageException('Missing required positional argument: <member-id>');
    }
    final memberId = rest.first;

    final result = await bffClient.post<Object?>(
      '/team/$memberId/reset-password',
    );
    switch (result) {
      case Success():
        return 0;
      case Failure(:final error):
        final e = error as CliError;
        _writeErr(e.stderrMessage);
        return e.exitCode;
    }
  }

  void _writeErr(String line) {
    final err = stderr ?? stdout;
    if (err != null) err.writeln(line);
  }
}
