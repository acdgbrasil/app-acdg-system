/// `acdg protection` — violation reports, referrals, and placement-history
/// parent command (C07).
///
/// Holds the three Contract A Protection verbs:
///   `violation`, `referral`, `placement-history`.
///
/// Mirrors `PatientCommand` (C03) / `FamilyCommand` (C04) /
/// `AssessmentCommand` (C05) / `CareCommand` (C06): when constructed without
/// collaborators (e.g. by `args` introspection in tests), it falls back to
/// schema-only placeholder subcommands so `--help` still advertises the
/// canonical three names.
library;

import 'package:args/command_runner.dart';

import 'protection_placement_history_command.dart';
import 'protection_referral_command.dart';
import 'protection_violation_command.dart';

/// Parent for `acdg protection violation|referral|placement-history`.
final class ProtectionCommand extends Command<int> {
  ProtectionCommand({
    ProtectionViolationCommand? violation,
    ProtectionReferralCommand? referral,
    ProtectionPlacementHistoryCommand? placementHistory,
  }) {
    if (violation != null) addSubcommand(violation);
    if (referral != null) addSubcommand(referral);
    if (placementHistory != null) addSubcommand(placementHistory);

    // Without wired collaborators (tests / `--help` introspection) register
    // schema-only placeholders so the three names appear under `subcommands`.
    if (subcommands.isEmpty) {
      addSubcommand(_PlaceholderCommand('violation'));
      addSubcommand(_PlaceholderCommand('referral'));
      addSubcommand(_PlaceholderCommand('placement-history'));
    }
  }

  @override
  String get name => 'protection';

  @override
  String get description =>
      'Protection operations (report violation, register referral, '
      'replace placement history).';

  @override
  Future<int> run() async {
    // `acdg protection` with no subcommand → EX_USAGE.
    // Avoid `printUsage()` here: it reaches `runner.usage` which is null
    // when the parent is invoked directly from a test (without a runner
    // attached). The CommandRunner path renders the usage banner before
    // calling `run`, so production invocations still see helpful output.
    return 64;
  }
}

/// Schema-only placeholder used when [ProtectionCommand] is constructed with
/// no collaborators. Real subcommands are injected by `cli_runner.dart`.
final class _PlaceholderCommand extends Command<int> {
  _PlaceholderCommand(this.name);

  @override
  final String name;

  @override
  String get description => 'protection $name';

  @override
  Future<int> run() async => 64;
}
