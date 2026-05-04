/// `acdg team role` — role assignment governance sub-parent (C09).
///
/// **Second sub-parent (parent of parents) in the CLI canon** — after
/// `lookup request` from C08. Owns the three role-assignment leaves:
///   `assign`, `deactivate`, `reactivate`.
///
/// Reachable via `acdg team role <leaf>`. The grouping mirrors the BFF
/// route topology (`/team/<id>/roles/<rid>/...`) and keeps the top-level
/// `team` parent at a manageable 7 entries.
///
/// Mirrors the top-level parents (`PatientCommand`, `FamilyCommand`,
/// `LookupCommand`, etc.) and the C08 sibling `LookupRequestCommand`: when
/// constructed without collaborators (e.g. by `args` introspection in
/// tests), it falls back to schema-only placeholder subcommands so `--help`
/// still advertises the canonical three names.
library;

import 'package:args/command_runner.dart';

import 'team_role_assign_command.dart';
import 'team_role_deactivate_command.dart';
import 'team_role_reactivate_command.dart';

/// Parent for `acdg team role assign|deactivate|reactivate`.
final class TeamRoleCommand extends Command<int> {
  TeamRoleCommand({
    TeamRoleAssignCommand? assign,
    TeamRoleDeactivateCommand? deactivate,
    TeamRoleReactivateCommand? reactivate,
  }) {
    if (assign != null) addSubcommand(assign);
    if (deactivate != null) addSubcommand(deactivate);
    if (reactivate != null) addSubcommand(reactivate);

    // Without wired collaborators (tests / `--help` introspection) register
    // schema-only placeholders so the three names appear under `subcommands`.
    if (subcommands.isEmpty) {
      addSubcommand(_PlaceholderCommand('assign'));
      addSubcommand(_PlaceholderCommand('deactivate'));
      addSubcommand(_PlaceholderCommand('reactivate'));
    }
  }

  @override
  String get name => 'role';

  @override
  String get description =>
      'Role assignments for a team member (assign, deactivate, reactivate).';

  @override
  Future<int> run() async {
    // `acdg team role` with no leaf → EX_USAGE.
    return 64;
  }
}

/// Schema-only placeholder used when [TeamRoleCommand] is constructed with
/// no collaborators. Real subcommands are injected by `cli_runner.dart`.
final class _PlaceholderCommand extends Command<int> {
  _PlaceholderCommand(this.name);

  @override
  final String name;

  @override
  String get description => 'team role $name';

  @override
  Future<int> run() async => 64;
}
