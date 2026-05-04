/// W0 RED — `TeamRoleCommand` sub-parent contract (C09).
///
/// **Sub-parent of TeamCommand.** Second sub-parent in the CLI canon
/// (after `lookup request` from C08). It owns 3 role-management leaves:
///   * `assign`     → POST `/team/<id>/roles`
///   * `deactivate` → PUT  `/team/<id>/roles/<roleId>/deactivate`
///   * `reactivate` → PUT  `/team/<id>/roles/<roleId>/reactivate`
///
/// Reachable via `acdg team role <leaf>`. The grouping mirrors the BFF
/// route topology (`/team/<id>/roles/<rid>/...`) and keeps the top-level
/// `team` parent at a manageable 7 entries.
///
/// W1 must create `apps/cli/lib/src/commands/team_role_command.dart`:
///
/// ```dart
/// class TeamRoleCommand extends Command<int> {
///   TeamRoleCommand({
///     TeamRoleAssignCommand? assign,
///     TeamRoleDeactivateCommand? deactivate,
///     TeamRoleReactivateCommand? reactivate,
///   }) {
///     // wire injected children; fall back to schema-only placeholders so
///     // `--help` still advertises the canonical 3 names. Mirrors the
///     // top-level parents (PatientCommand, FamilyCommand, LookupCommand,
///     // LookupRequestCommand).
///   }
///   @override String get name => 'role';
///   @override String get description => '...non-empty...';
/// }
/// ```
///
/// Subcommand-level orchestration tests live in:
///   * `team_role_assign_command_test.dart`
///   * `team_role_deactivate_command_test.dart`
///   * `team_role_reactivate_command_test.dart`
library;

import 'package:args/command_runner.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/team_role_command.dart';

void main() {
  group('TeamRoleCommand sub-parent (C09)', () {
    test('extends args.Command<int>', () {
      expect(TeamRoleCommand(), isA<Command<int>>());
    });

    test('name is "role"', () {
      expect(TeamRoleCommand().name, equals('role'));
    });

    test('description is non-empty', () {
      expect(TeamRoleCommand().description, isNotEmpty);
    });

    test(
      'registers exactly the 3 governance leaves: assign/deactivate/reactivate',
      () {
        final cmd = TeamRoleCommand();
        final names = cmd.subcommands.keys.toSet();

        expect(names, contains('assign'));
        expect(names, contains('deactivate'));
        expect(names, contains('reactivate'));
      },
    );

    test(
      'parent without subcommand returns non-zero exit (EX_USAGE)',
      () async {
        // `acdg team role` with no leaf → non-zero exit. Mirrors the
        // top-level parent contract.
        final cmd = TeamRoleCommand();

        final exitCode = await cmd.run();

        expect(exitCode, isNot(equals(0)));
      },
    );
  });
}
