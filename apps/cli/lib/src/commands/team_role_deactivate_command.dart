/// `acdg team role deactivate <member-id> <role-id>` — deactivate a role
/// assignment (C09).
///
/// Path-only PUT `/team/<member-id>/roles/<role-id>/deactivate` —
/// `DeactivateRoleIntent.parseFromParams` has no body parser. Two positional
/// arguments, both validated as UUID v4 server-side. UUID failure short-
/// circuits left-to-right (memberId first, then roleId) per
/// `deactivate_role_intent.dart:21-23`.
///
/// Missing either positional → usage error 64, no BFF call. 200/204 →
/// exit 0. 4xx/5xx → non-zero exit + stderr.
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../session/bff_client.dart';
import '_command_helpers.dart';

/// `acdg team role deactivate`.
final class TeamRoleDeactivateCommand extends Command<int> {
  TeamRoleDeactivateCommand({
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
  String get name => 'deactivate';

  @override
  String get description => 'Deactivate a role assignment for a team member.';

  @override
  String get invocation => 'acdg team role deactivate <member-id> <role-id>';

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
      '/team/$memberId/roles/$roleId/deactivate',
    );
    switch (result) {
      case Success():
        return 0;
      case Failure(:final error):
        _writeErr(stderrMessageFor(error));
        return exitCodeFor(error);
    }
  }

  void _writeErr(String line) {
    final err = stderr ?? stdout;
    if (err != null) err.writeln(line);
  }
}
