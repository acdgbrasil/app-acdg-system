/// W0 RED — `AssessmentCommand` parent contract under C05.
///
/// **Replaces the C01 stub contract.** C01 declared `AssessmentCommand` as a
/// leaf command that printed "Not implemented yet — pending C05". C05 makes
/// it a parent command holding 7 subcommands matching the seven assessment
/// "fichas" of Contract A:
///
///   * `housing`               (PUT `/patients/<id>/assessment/housing`)
///   * `socioeconomic`         (PUT `/patients/<id>/assessment/socioeconomic`)
///   * `work-income`           (PUT `/patients/<id>/assessment/work-income`)
///   * `education`             (PUT `/patients/<id>/assessment/education`)
///   * `health`                (PUT `/patients/<id>/assessment/health`)
///   * `community-support`     (PUT `/patients/<id>/assessment/community-support`)
///   * `social-health-summary` (PUT `/patients/<id>/assessment/social-health-summary`)
///
/// W1 must update `apps/cli/lib/src/commands/assessment_command.dart` so:
///
/// ```dart
/// class AssessmentCommand extends Command<int> {
///   AssessmentCommand({
///     AssessmentHousingCommand? housing,
///     AssessmentSocioeconomicCommand? socioeconomic,
///     AssessmentWorkIncomeCommand? workIncome,
///     AssessmentEducationCommand? education,
///     AssessmentHealthCommand? health,
///     AssessmentCommunitySupportCommand? communitySupport,
///     AssessmentSocialHealthSummaryCommand? socialHealthSummary,
///   }) {
///     // wire injected subcommands; fall back to schema-only placeholders so
///     // `--help` still advertises the canonical seven names when the ctor
///     // is called with no collaborators (mirrors PatientCommand C03 +
///     // FamilyCommand C04 contracts).
///   }
///   @override String get name => 'assessment';
///   @override String get description => '...non-empty...';
/// }
/// ```
///
/// Subcommand-level orchestration tests live in the seven sibling files,
/// `assessment_<verb>_command_test.dart`.
library;

import 'package:args/command_runner.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/assessment_command.dart';

void main() {
  group('AssessmentCommand parent (C05)', () {
    test('extends args.Command<int>', () {
      expect(AssessmentCommand(), isA<Command<int>>());
    });

    test('name is "assessment"', () {
      expect(AssessmentCommand().name, equals('assessment'));
    });

    test('description is non-empty', () {
      expect(AssessmentCommand().description, isNotEmpty);
    });

    test('registers the 7 ficha subcommands required by the ticket: '
        'housing, socioeconomic, work-income, education, health, '
        'community-support, social-health-summary', () {
      final cmd = AssessmentCommand();
      final names = cmd.subcommands.keys.toSet();

      expect(names, contains('housing'));
      expect(names, contains('socioeconomic'));
      expect(names, contains('work-income'));
      expect(names, contains('education'));
      expect(names, contains('health'));
      expect(names, contains('community-support'));
      expect(names, contains('social-health-summary'));
    });

    test(
      'parent without subcommand returns non-zero exit (EX_USAGE)',
      () async {
        // `acdg assessment` with no verb should print usage and exit
        // non-zero. Mirrors PatientCommand/FamilyCommand 64 exit code
        // (EX_USAGE per sysexits(3)).
        final cmd = AssessmentCommand();

        final exitCode = await cmd.run();

        expect(exitCode, isNot(equals(0)));
      },
    );
  });
}
