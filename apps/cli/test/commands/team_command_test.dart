/// W0 RED — `TeamCommand` parent contract under C09.
///
/// **Replaces the C01 stub contract.** C01 declared `TeamCommand` as a leaf
/// command that printed "Not implemented yet — pending C09". C09 makes it a
/// parent command holding 7 entries: 6 leaf verbs + 1 sub-parent (`role`)
/// that itself owns 3 governance leaves.
///
/// The 9 underlying endpoints (cf. ticket §Escopo) collapse onto this shape:
///
/// ```
/// acdg team list                           # leaf — GET  /team?role=&active=&search=
/// acdg team register                       # leaf — POST /team
/// acdg team get <member-id>                # leaf — GET  /team/<id>
/// acdg team deactivate <member-id>         # leaf — PUT  /team/<id>/deactivate
/// acdg team reactivate <member-id>         # leaf — PUT  /team/<id>/reactivate
/// acdg team reset-password <member-id>     # leaf — POST /team/<id>/reset-password
/// acdg team role assign <id>               # via sub-parent — POST /team/<id>/roles
/// acdg team role deactivate <id> <role-id> # via sub-parent — PUT  /team/<id>/roles/<rid>/deactivate
/// acdg team role reactivate <id> <role-id> # via sub-parent — PUT  /team/<id>/roles/<rid>/reactivate
/// ```
///
/// **Sub-parent decision.** Mirrors C08's `lookup request` pattern: 3 verbs
/// share a common scope (`role` actions on a worker) so we group them under
/// a single sub-parent rather than flattening them as `team-role-assign`.
/// This matches the BFF route topology (`/team/<id>/roles/<rid>/...`) and
/// keeps the top-level `team` parent at a manageable 7 entries.
///
/// W1 must update `apps/cli/lib/src/commands/team_command.dart` so that:
///
/// ```dart
/// class TeamCommand extends Command<int> {
///   TeamCommand({
///     TeamListCommand? list,
///     TeamRegisterCommand? register,
///     TeamGetCommand? get,
///     TeamDeactivateCommand? deactivate,
///     TeamReactivateCommand? reactivate,
///     TeamResetPasswordCommand? resetPassword,
///     TeamRoleCommand? role,  // sub-parent
///   }) {
///     // wire injected sub-commands; fall back to schema-only placeholders
///     // so `--help` still advertises all 7 names when ctor is called with
///     // no collaborators (mirrors LookupCommand C08 + PatientCommand C03).
///   }
///   @override String get name => 'team';
///   @override String get description => '...non-empty...';
/// }
/// ```
///
/// Subcommand-level orchestration tests live in:
///   * `team_list_command_test.dart`
///   * `team_register_command_test.dart`
///   * `team_get_command_test.dart`
///   * `team_deactivate_command_test.dart`
///   * `team_reactivate_command_test.dart`
///   * `team_reset_password_command_test.dart`
///   * `team_role_command_test.dart` (sub-parent)
///   * `team_role_assign_command_test.dart`
///   * `team_role_deactivate_command_test.dart`
///   * `team_role_reactivate_command_test.dart`
library;

import 'package:args/command_runner.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/team_command.dart';

void main() {
  group('TeamCommand parent (C09)', () {
    test('extends args.Command<int>', () {
      expect(TeamCommand(), isA<Command<int>>());
    });

    test('name is "team"', () {
      expect(TeamCommand().name, equals('team'));
    });

    test('description is non-empty', () {
      expect(TeamCommand().description, isNotEmpty);
    });

    test('registers the 7 entries required by the ticket: '
        'list / register / get / deactivate / reactivate / reset-password / '
        'role (sub-parent)', () {
      final cmd = TeamCommand();
      final names = cmd.subcommands.keys.toSet();

      expect(names, contains('list'));
      expect(names, contains('register'));
      expect(names, contains('get'));
      expect(names, contains('deactivate'));
      expect(names, contains('reactivate'));
      expect(names, contains('reset-password'));
      expect(names, contains('role'));
    });

    test('the "role" entry is itself a parent command (sub-parent)', () {
      // Sub-parent shape: `team role assign|deactivate|reactivate` →
      // `role` owns 3 leaves. We assert non-emptiness here; the exact 3-leaf
      // set is pinned in `team_role_command_test.dart`.
      final cmd = TeamCommand();
      final role = cmd.subcommands['role'];

      expect(role, isNotNull);
      expect(
        role!.subcommands,
        isNotEmpty,
        reason: '"role" must be a parent owning role-management leaves',
      );
    });

    test(
      'parent without subcommand returns non-zero exit (EX_USAGE)',
      () async {
        // `acdg team` with no verb should print usage and exit non-zero.
        // Mirrors PatientCommand / FamilyCommand / LookupCommand:
        // 64 exit code (EX_USAGE per sysexits(3)).
        final cmd = TeamCommand();

        final exitCode = await cmd.run();

        expect(exitCode, isNot(equals(0)));
      },
    );
  });
}
