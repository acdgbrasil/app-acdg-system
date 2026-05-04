/// `acdg care` — care appointments and intake parent command (C06).
///
/// Holds the two Contract A Care verbs:
///   `appointment`, `intake`.
///
/// Mirrors `PatientCommand` (C03) / `FamilyCommand` (C04) /
/// `AssessmentCommand` (C05): when constructed without collaborators (e.g.
/// by `args` introspection in tests), it falls back to schema-only
/// placeholder subcommands so `--help` still advertises the canonical two
/// names.
library;

import 'package:args/command_runner.dart';

import 'care_appointment_command.dart';
import 'care_intake_command.dart';

/// Parent for `acdg care appointment|intake`.
final class CareCommand extends Command<int> {
  CareCommand({
    CareAppointmentCommand? appointment,
    CareIntakeCommand? intake,
  }) {
    if (appointment != null) addSubcommand(appointment);
    if (intake != null) addSubcommand(intake);

    // Without wired collaborators (tests / `--help` introspection) register
    // schema-only placeholders so the two names appear under `subcommands`.
    if (subcommands.isEmpty) {
      addSubcommand(_PlaceholderCommand('appointment'));
      addSubcommand(_PlaceholderCommand('intake'));
    }
  }

  @override
  String get name => 'care';

  @override
  String get description =>
      'Care operations (register appointment, update intake info).';

  @override
  Future<int> run() async {
    // `acdg care` with no subcommand → EX_USAGE.
    // Avoid `printUsage()` here: it reaches `runner.usage` which is null
    // when the parent is invoked directly from a test (without a runner
    // attached). The CommandRunner path renders the usage banner before
    // calling `run`, so production invocations still see helpful output.
    return 64;
  }
}

/// Schema-only placeholder used when [CareCommand] is constructed with no
/// collaborators. Real subcommands are injected by `cli_runner.dart`.
final class _PlaceholderCommand extends Command<int> {
  _PlaceholderCommand(this.name);

  @override
  final String name;

  @override
  String get description => 'care $name';

  @override
  Future<int> run() async => 64;
}
