/// Top-level entry point for the `acdg` CLI binary.
///
/// Wires `args.CommandRunner<int>` with:
///   * the 9 sub-commands (auth, patient, family, assessment, care,
///     protection, lookup, team, health),
///   * the global flags `--bff`, `--output`, `--quiet`,
///   * a stdout/stderr indirection so tests (and future structured-logging
///     callers) can capture I/O without poking real `Stdout`.
///
/// `CliRunner` composes a [_CapturingCommandRunner] subclass so the
/// `args` package's reflective `printUsage` / `usageException` paths land in
/// the injected sinks instead of the host process's `Stdout`. Foreign
/// callers see only the public [runner] getter typed as `CommandRunner<int>`
/// — the subclass hop is an implementation detail.
library;

import 'package:args/command_runner.dart';

import 'commands/assessment_command.dart';
import 'commands/auth_command.dart';
import 'commands/care_command.dart';
import 'commands/family_command.dart';
import 'commands/health_command.dart';
import 'commands/lookup_command.dart';
import 'commands/patient_command.dart';
import 'commands/protection_command.dart';
import 'commands/team_command.dart';

const String _executableName = 'acdg';
const String _description =
    'ACDG CLI — Operate the social care system from the command line.';
const String _defaultBffUrl = 'http://localhost:3000';

const List<String> _outputFormats = ['json', 'table', 'yaml', 'auto'];

/// Hosts the `acdg` [CommandRunner] alongside injectable I/O sinks.
///
/// Composition over inheritance: callers receive `cli.runner` typed as
/// `CommandRunner<int>` and never need to know the concrete subclass.
final class CliRunner {
  CliRunner({required StringSink stdout, required StringSink stderr})
    : _stderr = stderr {
    _runner = _CapturingCommandRunner(
      executableName: _executableName,
      description: _description,
      stdout: stdout,
    );
    _runner.argParser
      ..addOption('bff', defaultsTo: _defaultBffUrl, help: 'BFF base URL')
      ..addOption(
        'output',
        allowed: _outputFormats,
        defaultsTo: 'auto',
        help: 'json | table | yaml (default: auto — tty=table, pipe=json)',
      )
      ..addFlag(
        'quiet',
        defaultsTo: false,
        negatable: false,
        help: 'suppress info logs',
      );

    _runner
      ..addCommand(AuthCommand(stdout: stdout))
      ..addCommand(PatientCommand(stdout: stdout))
      ..addCommand(FamilyCommand(stdout: stdout))
      ..addCommand(AssessmentCommand(stdout: stdout))
      ..addCommand(CareCommand(stdout: stdout))
      ..addCommand(ProtectionCommand(stdout: stdout))
      ..addCommand(LookupCommand(stdout: stdout))
      ..addCommand(TeamCommand(stdout: stdout))
      ..addCommand(HealthCommand(stdout: stdout));
  }

  final StringSink _stderr;
  late final _CapturingCommandRunner _runner;

  /// The `args` runner — exposed typed as the parent class so foreign code
  /// cannot see the capture subclass.
  CommandRunner<int> get runner => _runner;

  /// Runs the CLI with [args], converting [UsageException] (unknown
  /// command, missing argument) into a non-zero exit code + stderr message.
  ///
  /// Other [Object]s thrown by command [Command.run] propagate unchanged
  /// (programmer faults should crash with a stack trace, per ADR-019).
  Future<int> run(List<String> args) async {
    try {
      final exitCode = await _runner.run(args);
      return exitCode ?? 0;
    } on UsageException catch (e) {
      _stderr
        ..writeln(e.message)
        ..writeln()
        ..writeln(e.usage);
      return 64; // EX_USAGE per sysexits(3).
    }
  }
}

/// `CommandRunner<int>` subclass that redirects `printUsage` to a caller-
/// supplied [StringSink] so `--help` output lands in our captured buffer
/// rather than the host process's stdout.
final class _CapturingCommandRunner extends CommandRunner<int> {
  _CapturingCommandRunner({
    required String executableName,
    required String description,
    required StringSink stdout,
  }) : _stdout = stdout,
       super(executableName, description);

  final StringSink _stdout;

  @override
  void printUsage() => _stdout.writeln(usage);
}
