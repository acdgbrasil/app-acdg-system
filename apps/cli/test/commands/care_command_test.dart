/// W0 RED — `CareCommand` parent contract under C06.
///
/// **Replaces the C01 stub contract.** C01 declared `CareCommand` as a leaf
/// command that printed "Not implemented yet — pending C06". C06 makes it a
/// parent command holding 2 subcommands: `appointment`, `intake`
/// (ticket §Escopo + verified against `CareContract` sub-contract).
///
/// W1 must update `apps/cli/lib/src/commands/care_command.dart` so that:
///
/// ```dart
/// class CareCommand extends Command<int> {
///   CareCommand({
///     CareAppointmentCommand? appointment,
///     CareIntakeCommand? intake,
///   }) {
///     // wire injected subcommands; fall back to schema-only placeholders
///     // so `--help` still advertises the canonical 2 names when ctor is
///     // called with no collaborators (mirrors PatientCommand C03 +
///     // FamilyCommand C04 + AssessmentCommand C05 contracts).
///   }
///   @override String get name => 'care';
///   @override String get description => '...non-empty...';
/// }
/// ```
///
/// Subcommand-level orchestration tests live in:
///   * `care_appointment_command_test.dart`
///   * `care_intake_command_test.dart`
library;

import 'package:args/command_runner.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/care_command.dart';

void main() {
  group('CareCommand parent (C06)', () {
    test('extends args.Command<int>', () {
      expect(CareCommand(), isA<Command<int>>());
    });

    test('name is "care"', () {
      expect(CareCommand().name, equals('care'));
    });

    test('description is non-empty', () {
      expect(CareCommand().description, isNotEmpty);
    });

    test('registers the 2 subcommands required by the ticket: '
        'appointment / intake', () {
      final cmd = CareCommand();
      final names = cmd.subcommands.keys.toSet();

      expect(names, contains('appointment'));
      expect(names, contains('intake'));
    });

    test(
      'parent without subcommand returns non-zero exit (EX_USAGE)',
      () async {
        // `acdg care` with no verb should print usage and exit non-zero.
        // Mirrors PatientCommand / FamilyCommand / AssessmentCommand
        // (exit 64 EX_USAGE per sysexits(3)).
        final cmd = CareCommand();

        final exitCode = await cmd.run();

        expect(exitCode, isNot(equals(0)));
      },
    );
  });
}
