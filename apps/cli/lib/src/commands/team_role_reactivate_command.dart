/// `acdg team role reactivate <member-id> <role-id>` — reactivate a role
/// assignment (C09).
///
/// Path-only PUT `/team/<member-id>/roles/<role-id>/reactivate` —
/// `ReactivateRoleIntent.parseFromParams` has no body parser. Two positional
/// arguments, both validated as UUID v4 server-side. UUID failure short-
/// circuits left-to-right (memberId first, then roleId) per
/// `reactivate_role_intent.dart:21-23`.
///
/// Missing either positional → usage error 64, no BFF call. 200/204 →
/// exit 0. 4xx/5xx → non-zero exit + stderr.
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../errors/cli_error.dart';
import '../session/bff_client.dart';

/// `acdg team role reactivate`.
final class TeamRoleReactivateCommand extends Command<int> {
  TeamRoleReactivateCommand({
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
  String get name => 'reactivate';

  @override
  String get description =>
      'Reactivate a previously deactivated role assignment.';

  @override
  String get invocation => 'acdg team role reactivate <member-id> <role-id>';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.length < 2) {
      usageException(
        'Missing required positional arguments: <member-id> <role-id>',
      );
    }
    final memberId = rest[0];
    final roleId = rest[1];

    final result = await bffClient.put<Object?>(
      '/team/$memberId/roles/$roleId/reactivate',
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
