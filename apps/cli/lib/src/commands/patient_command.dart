/// `acdg patient` — patient registry parent command (C03).
///
/// Holds the eight Contract A Registry verbs:
///   `list`, `get`, `audit`, `register`, `admit`, `discharge`, `readmit`,
///   `withdraw`.
///
/// Mirrors `AuthCommand`: when constructed without collaborators (e.g. by
/// `args` introspection in tests), it falls back to schema-only placeholder
/// subcommands so `--help` still advertises the canonical eight names.
library;

import 'package:args/command_runner.dart';

import 'patient_admit_command.dart';
import 'patient_audit_command.dart';
import 'patient_discharge_command.dart';
import 'patient_get_command.dart';
import 'patient_list_command.dart';
import 'patient_readmit_command.dart';
import 'patient_register_command.dart';
import 'patient_withdraw_command.dart';

/// Parent for `acdg patient list|get|audit|register|admit|discharge|
/// readmit|withdraw`.
final class PatientCommand extends Command<int> {
  PatientCommand({
    PatientListCommand? list,
    PatientGetCommand? get,
    PatientAuditCommand? audit,
    PatientRegisterCommand? register,
    PatientAdmitCommand? admit,
    PatientDischargeCommand? discharge,
    PatientReadmitCommand? readmit,
    PatientWithdrawCommand? withdraw,
  }) {
    if (list != null) addSubcommand(list);
    if (get != null) addSubcommand(get);
    if (audit != null) addSubcommand(audit);
    if (register != null) addSubcommand(register);
    if (admit != null) addSubcommand(admit);
    if (discharge != null) addSubcommand(discharge);
    if (readmit != null) addSubcommand(readmit);
    if (withdraw != null) addSubcommand(withdraw);

    // Without wired collaborators (tests / `--help` introspection) register
    // schema-only placeholders so the eight names appear under `subcommands`.
    if (subcommands.isEmpty) {
      addSubcommand(_PlaceholderCommand('list'));
      addSubcommand(_PlaceholderCommand('get'));
      addSubcommand(_PlaceholderCommand('audit'));
      addSubcommand(_PlaceholderCommand('register'));
      addSubcommand(_PlaceholderCommand('admit'));
      addSubcommand(_PlaceholderCommand('discharge'));
      addSubcommand(_PlaceholderCommand('readmit'));
      addSubcommand(_PlaceholderCommand('withdraw'));
    }
  }

  @override
  String get name => 'patient';

  @override
  String get description =>
      'Patient registry operations (list, get, audit, register, lifecycle).';

  @override
  Future<int> run() async {
    // `acdg patient` with no subcommand → EX_USAGE.
    // Avoid `printUsage()` here: it reaches `runner.usage` which is null
    // when the parent is invoked directly from a test (without a runner
    // attached). The CommandRunner path renders the usage banner before
    // calling `run`, so production invocations still see helpful output.
    return 64;
  }
}

/// Schema-only placeholder used when [PatientCommand] is constructed with
/// no collaborators. Real subcommands are injected by `cli_runner.dart`.
final class _PlaceholderCommand extends Command<int> {
  _PlaceholderCommand(this.name);

  @override
  final String name;

  @override
  String get description => 'patient $name';

  @override
  Future<int> run() async => 64;
}
