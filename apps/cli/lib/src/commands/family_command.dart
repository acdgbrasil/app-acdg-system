/// `acdg family` — family member operations parent command (C04).
///
/// Holds the four Contract A Registry-Family verbs:
///   `add`, `remove`, `assign-caregiver`, `update-identity`.
///
/// Mirrors `PatientCommand` (C03): when constructed without collaborators
/// (e.g. by `args` introspection in tests), it falls back to schema-only
/// placeholder subcommands so `--help` still advertises the canonical four
/// names.
library;

import 'package:args/command_runner.dart';

import 'family_add_command.dart';
import 'family_assign_caregiver_command.dart';
import 'family_remove_command.dart';
import 'family_update_identity_command.dart';

/// Parent for `acdg family add|remove|assign-caregiver|update-identity`.
final class FamilyCommand extends Command<int> {
  FamilyCommand({
    FamilyAddCommand? add,
    FamilyRemoveCommand? remove,
    FamilyAssignCaregiverCommand? assignCaregiver,
    FamilyUpdateIdentityCommand? updateIdentity,
  }) {
    if (add != null) addSubcommand(add);
    if (remove != null) addSubcommand(remove);
    if (assignCaregiver != null) addSubcommand(assignCaregiver);
    if (updateIdentity != null) addSubcommand(updateIdentity);

    // Without wired collaborators (tests / `--help` introspection) register
    // schema-only placeholders so the four names appear under `subcommands`.
    if (subcommands.isEmpty) {
      addSubcommand(_PlaceholderCommand('add'));
      addSubcommand(_PlaceholderCommand('remove'));
      addSubcommand(_PlaceholderCommand('assign-caregiver'));
      addSubcommand(_PlaceholderCommand('update-identity'));
    }
  }

  @override
  String get name => 'family';

  @override
  String get description =>
      'Family member operations (add, remove, assign caregiver, update identity).';

  @override
  Future<int> run() async {
    // `acdg family` with no subcommand → EX_USAGE.
    // Avoid `printUsage()` here: it reaches `runner.usage` which is null
    // when the parent is invoked directly from a test (without a runner
    // attached). The CommandRunner path renders the usage banner before
    // calling `run`, so production invocations still see helpful output.
    return 64;
  }
}

/// Schema-only placeholder used when [FamilyCommand] is constructed with no
/// collaborators. Real subcommands are injected by `cli_runner.dart`.
final class _PlaceholderCommand extends Command<int> {
  _PlaceholderCommand(this.name);

  @override
  final String name;

  @override
  String get description => 'family $name';

  @override
  Future<int> run() async => 64;
}
