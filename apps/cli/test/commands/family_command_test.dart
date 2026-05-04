/// W0 RED — `FamilyCommand` parent contract under C04.
///
/// **Replaces the C01 stub contract.** C01 declared `FamilyCommand` as a leaf
/// command that printed "Not implemented yet — pending C04". C04 makes it a
/// parent command holding 4 subcommands: `add`, `remove`, `assign-caregiver`,
/// `update-identity` (ticket §Escopo).
///
/// W1 must update `apps/cli/lib/src/commands/family_command.dart` so that:
///
/// ```dart
/// class FamilyCommand extends Command<int> {
///   FamilyCommand({
///     FamilyAddCommand? add,
///     FamilyRemoveCommand? remove,
///     FamilyAssignCaregiverCommand? assignCaregiver,
///     FamilyUpdateIdentityCommand? updateIdentity,
///   }) {
///     // wire injected subcommands; fall back to schema-only placeholders
///     // so `--help` still advertises the canonical 4 names when ctor is
///     // called with no collaborators (mirrors PatientCommand C03 contract).
///   }
///   @override String get name => 'family';
///   @override String get description => '...non-empty...';
/// }
/// ```
///
/// Subcommand-level orchestration tests live in:
///   * `family_add_command_test.dart`
///   * `family_remove_command_test.dart`
///   * `family_assign_caregiver_command_test.dart`
///   * `family_update_identity_command_test.dart`
library;

import 'package:args/command_runner.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/family_command.dart';

void main() {
  group('FamilyCommand parent (C04)', () {
    test('extends args.Command<int>', () {
      expect(FamilyCommand(), isA<Command<int>>());
    });

    test('name is "family"', () {
      expect(FamilyCommand().name, equals('family'));
    });

    test('description is non-empty', () {
      expect(FamilyCommand().description, isNotEmpty);
    });

    test('registers the 4 subcommands required by the ticket: '
        'add/remove/assign-caregiver/update-identity', () {
      final cmd = FamilyCommand();
      final names = cmd.subcommands.keys.toSet();

      expect(names, contains('add'));
      expect(names, contains('remove'));
      expect(names, contains('assign-caregiver'));
      expect(names, contains('update-identity'));
    });

    test(
      'parent without subcommand returns non-zero exit (EX_USAGE)',
      () async {
        // `acdg family` with no verb should print usage and exit non-zero.
        // Mirrors PatientCommand's 64 exit code (EX_USAGE per sysexits(3)).
        final cmd = FamilyCommand();

        final exitCode = await cmd.run();

        expect(exitCode, isNot(equals(0)));
      },
    );
  });
}
