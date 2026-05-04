/// `acdg assessment` — assessment forms parent command (C05).
///
/// Holds the seven Contract A Assessment fichas:
///   `housing`, `socioeconomic`, `work-income`, `education`, `health`,
///   `community-support`, `social-health-summary`.
///
/// Mirrors `PatientCommand` (C03) / `FamilyCommand` (C04): when constructed
/// without collaborators (e.g. by `args` introspection in tests), it falls
/// back to schema-only placeholder subcommands so `--help` still advertises
/// the canonical seven names.
library;

import 'package:args/command_runner.dart';

import 'assessment_community_support_command.dart';
import 'assessment_education_command.dart';
import 'assessment_health_command.dart';
import 'assessment_housing_command.dart';
import 'assessment_social_health_summary_command.dart';
import 'assessment_socioeconomic_command.dart';
import 'assessment_work_income_command.dart';

/// Parent for `acdg assessment housing|socioeconomic|work-income|education|
/// health|community-support|social-health-summary`.
final class AssessmentCommand extends Command<int> {
  AssessmentCommand({
    AssessmentHousingCommand? housing,
    AssessmentSocioeconomicCommand? socioeconomic,
    AssessmentWorkIncomeCommand? workIncome,
    AssessmentEducationCommand? education,
    AssessmentHealthCommand? health,
    AssessmentCommunitySupportCommand? communitySupport,
    AssessmentSocialHealthSummaryCommand? socialHealthSummary,
  }) {
    if (housing != null) addSubcommand(housing);
    if (socioeconomic != null) addSubcommand(socioeconomic);
    if (workIncome != null) addSubcommand(workIncome);
    if (education != null) addSubcommand(education);
    if (health != null) addSubcommand(health);
    if (communitySupport != null) addSubcommand(communitySupport);
    if (socialHealthSummary != null) addSubcommand(socialHealthSummary);

    // Without wired collaborators (tests / `--help` introspection) register
    // schema-only placeholders so the seven names appear under `subcommands`.
    if (subcommands.isEmpty) {
      addSubcommand(_PlaceholderCommand('housing'));
      addSubcommand(_PlaceholderCommand('socioeconomic'));
      addSubcommand(_PlaceholderCommand('work-income'));
      addSubcommand(_PlaceholderCommand('education'));
      addSubcommand(_PlaceholderCommand('health'));
      addSubcommand(_PlaceholderCommand('community-support'));
      addSubcommand(_PlaceholderCommand('social-health-summary'));
    }
  }

  @override
  String get name => 'assessment';

  @override
  String get description =>
      'Update assessment forms (housing, socioeconomic, work-income, '
      'education, health, community-support, social-health-summary).';

  @override
  Future<int> run() async {
    // `acdg assessment` with no subcommand → EX_USAGE.
    // Avoid `printUsage()` here: it reaches `runner.usage` which is null
    // when the parent is invoked directly from a test (without a runner
    // attached). The CommandRunner path renders the usage banner before
    // calling `run`, so production invocations still see helpful output.
    return 64;
  }
}

/// Schema-only placeholder used when [AssessmentCommand] is constructed
/// with no collaborators. Real subcommands are injected by `cli_runner.dart`.
final class _PlaceholderCommand extends Command<int> {
  _PlaceholderCommand(this.name);

  @override
  final String name;

  @override
  String get description => 'assessment $name';

  @override
  Future<int> run() async => 64;
}
