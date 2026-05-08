/// `acdg team role assign <member-id> --system --role-id` — assign a role to
/// a team member (C09).
///
/// POSTs `/team/<member-id>/roles` with the [AssignRoleRequest] body shape:
///
/// ```json
/// {
///   "system": "<system>",
///   "role":   "<role-id>"
/// }
/// ```
///
/// On success, decodes the BFF envelope `{data:{id:"<uuid>"}, meta:{...}}`
/// (per `team_handler.dart:_respondWithId` + `StandardResponse<IdData>`)
/// via the shared [decodeStandardIdResponse] helper and surfaces the new
/// role-assignment id on stdout.
///
/// **DTO-as-canon (deviation from CLI flag spelling).** The CLI flag is
/// `--role-id` (kebab-friendly, distinguishes the role identifier from the
/// system identifier). The wire field is `role` per the
/// [AssignRoleRequest:8] DTO — the CLI translates `--role-id` → `role` on
/// the wire. (W0 §3 + D6 — pinned.)
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../errors/cli_error.dart';
import '../session/bff_client.dart';
import '_command_helpers.dart';

/// `acdg team role assign`.
final class TeamRoleAssignCommand extends Command<int> {
  TeamRoleAssignCommand({
    required this.bffClient,
    required this.formatter,
    this.stdout,
    this.stderr,
  }) {
    argParser
      ..addOption(
        'system',
        help: 'Target system, e.g. "social_care" / "analytics_bi" (required)',
      )
      ..addOption(
        'role-id',
        help:
            'Role identifier within the system, e.g. "social_worker" '
            '(required, DTO `role`)',
      );
  }

  final BffClient bffClient;
  final OutputFormatter formatter;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'assign';

  @override
  String get description => 'Assign a role to a team member.';

  @override
  String get invocation =>
      'acdg team role assign <member-id> --system=... --role-id=...';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      usageException('Missing required positional argument: <member-id>');
    }
    final memberId = rest.first;

    final system = argResults?['system'] as String?;
    if (system == null || system.isEmpty) {
      usageException('Missing required option: --system');
    }
    final roleId = argResults?['role-id'] as String?;
    if (roleId == null || roleId.isEmpty) {
      usageException('Missing required option: --role-id');
    }

    final body = <String, Object?>{'system': system, 'role': roleId};

    final result = await bffClient.post<String?>(
      '/team/$memberId/roles',
      body: body,
      decode: decodeStandardIdResponse,
    );
    switch (result) {
      case Success(:final value):
        if (value != null && value.isNotEmpty) {
          _writeOut('Assigned role $value');
        } else {
          _writeOut('Role assigned');
        }
        return 0;
      case Failure(:final error):
        final e = error as CliError;
        _writeErr(e.stderrMessage);
        return e.exitCode;
    }
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
