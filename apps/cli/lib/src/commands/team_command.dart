/// `acdg team` — team management parent command (C09).
///
/// Holds the six top-level Contract A team verbs plus a sub-parent for the
/// three role-assignment governance verbs:
///   `list`, `register`, `get`, `deactivate`, `reactivate`, `reset-password`,
///   `role` (sub-parent).
///
/// **Sub-parent decision.** Mirrors C08's `lookup request` pattern: three
/// verbs share a common scope (`role` actions on a worker) so we group them
/// under a single sub-parent rather than flattening them as
/// `team-role-assign`. This matches the BFF route topology
/// (`/team/<id>/roles/<rid>/...`) and keeps the top-level `team` parent at
/// a manageable 7 entries.
///
/// Mirrors the other top-level parents (`PatientCommand`, `FamilyCommand`,
/// `AssessmentCommand`, `CareCommand`, `ProtectionCommand`, `LookupCommand`):
/// when constructed without collaborators (e.g. by `args` introspection in
/// tests), it falls back to schema-only placeholder subcommands so `--help`
/// still advertises the canonical seven entries. The sub-parent placeholder
/// is itself a real [TeamRoleCommand] (with its own three placeholder leaves)
/// so the contract test for "the role entry is itself a parent command" passes
/// without requiring a wired sub-parent.
library;

import 'package:args/command_runner.dart';

import 'team_deactivate_command.dart';
import 'team_get_command.dart';
import 'team_list_command.dart';
import 'team_reactivate_command.dart';
import 'team_register_command.dart';
import 'team_reset_password_command.dart';
import 'team_role_command.dart';

/// Parent for `acdg team list|register|get|deactivate|reactivate|`
/// `reset-password|role`.
final class TeamCommand extends Command<int> {
  TeamCommand({
    TeamListCommand? list,
    TeamRegisterCommand? register,
    TeamGetCommand? get,
    TeamDeactivateCommand? deactivate,
    TeamReactivateCommand? reactivate,
    TeamResetPasswordCommand? resetPassword,
    TeamRoleCommand? role,
  }) {
    if (list != null) addSubcommand(list);
    if (register != null) addSubcommand(register);
    if (get != null) addSubcommand(get);
    if (deactivate != null) addSubcommand(deactivate);
    if (reactivate != null) addSubcommand(reactivate);
    if (resetPassword != null) addSubcommand(resetPassword);
    if (role != null) addSubcommand(role);

    // Without wired collaborators (tests / `--help` introspection) register
    // schema-only placeholders so the seven canonical names appear under
    // `subcommands`. The `role` placeholder is itself a parent (real
    // `TeamRoleCommand` with its own three placeholder leaves) so the
    // contract test for "role is itself a parent command" passes when no
    // injected sub-parent is provided.
    if (subcommands.isEmpty) {
      addSubcommand(_PlaceholderLeafCommand('list'));
      addSubcommand(_PlaceholderLeafCommand('register'));
      addSubcommand(_PlaceholderLeafCommand('get'));
      addSubcommand(_PlaceholderLeafCommand('deactivate'));
      addSubcommand(_PlaceholderLeafCommand('reactivate'));
      addSubcommand(_PlaceholderLeafCommand('reset-password'));
      addSubcommand(TeamRoleCommand());
    }
  }

  @override
  String get name => 'team';

  @override
  String get description =>
      'Team management '
      '(list, register, get, deactivate, reactivate, reset-password, role).';

  @override
  Future<int> run() async {
    // `acdg team` with no subcommand → EX_USAGE.
    // Avoid `printUsage()` here: it reaches `runner.usage` which is null
    // when the parent is invoked directly from a test (without a runner
    // attached). The CommandRunner path renders the usage banner before
    // calling `run`, so production invocations still see helpful output.
    return 64;
  }
}

/// Schema-only leaf placeholder used when [TeamCommand] is constructed with
/// no collaborators. Real subcommands are injected by `cli_runner.dart`.
final class _PlaceholderLeafCommand extends Command<int> {
  _PlaceholderLeafCommand(this.name);

  @override
  final String name;

  @override
  String get description => 'team $name';

  @override
  Future<int> run() async => 64;
}
