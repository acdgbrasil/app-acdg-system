/// W0 RED — `ProtectionCommand` parent contract under C07.
///
/// **Replaces the C01 stub contract.** C01 declared `ProtectionCommand` as a
/// leaf command that printed "Not implemented yet — pending C07". C07 makes
/// it a parent command holding 3 subcommands: `violation`, `referral`,
/// `placement-history` (ticket §Escopo + verified against `ProtectionContract`
/// sub-contract).
///
/// W1 must update `apps/cli/lib/src/commands/protection_command.dart` so that:
///
/// ```dart
/// class ProtectionCommand extends Command<int> {
///   ProtectionCommand({
///     ProtectionViolationCommand? violation,
///     ProtectionReferralCommand? referral,
///     ProtectionPlacementHistoryCommand? placementHistory,
///   }) {
///     // wire injected subcommands; fall back to schema-only placeholders
///     // so `--help` still advertises the canonical 3 names when ctor is
///     // called with no collaborators (mirrors PatientCommand C03 +
///     // FamilyCommand C04 + AssessmentCommand C05 + CareCommand C06).
///   }
///   @override String get name => 'protection';
///   @override String get description => '...non-empty...';
/// }
/// ```
///
/// Subcommand-level orchestration tests live in:
///   * `protection_violation_command_test.dart`
///   * `protection_referral_command_test.dart`
///   * `protection_placement_history_command_test.dart`
library;

import 'package:args/command_runner.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/protection_command.dart';

void main() {
  group('ProtectionCommand parent (C07)', () {
    test('extends args.Command<int>', () {
      expect(ProtectionCommand(), isA<Command<int>>());
    });

    test('name is "protection"', () {
      expect(ProtectionCommand().name, equals('protection'));
    });

    test('description is non-empty', () {
      expect(ProtectionCommand().description, isNotEmpty);
    });

    test('registers the 3 subcommands required by the ticket: '
        'violation / referral / placement-history', () {
      final cmd = ProtectionCommand();
      final names = cmd.subcommands.keys.toSet();

      expect(names, contains('violation'));
      expect(names, contains('referral'));
      expect(names, contains('placement-history'));
    });

    test(
      'parent without subcommand returns non-zero exit (EX_USAGE)',
      () async {
        // `acdg protection` with no verb should print usage and exit non-zero.
        // Mirrors PatientCommand / FamilyCommand / AssessmentCommand /
        // CareCommand (exit 64 EX_USAGE per sysexits(3)).
        final cmd = ProtectionCommand();

        final exitCode = await cmd.run();

        expect(exitCode, isNot(equals(0)));
      },
    );
  });
}
