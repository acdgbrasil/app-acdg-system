/// Shared helpers for command-level tests.
///
/// W0.5 RED — references symbols that do not yet exist in `package:cli/...`.
/// W1 (`flutter-bff-implementer`) creates the production code so these helpers
/// compile and the suites turn GREEN.
library;

import 'package:args/command_runner.dart';

import 'package:cli/src/cli_runner.dart';

/// Build a CommandRunner wired to an in-memory `StringBuffer` pair so tests can
/// inspect stdout/stderr without hitting real `Stdout`.
///
/// Contract for W1: `CliRunner` MUST expose a constructor that accepts
/// `StringSink stdout` and `StringSink stderr`, plus an `args.CommandRunner<int>`
/// getter (or be a CommandRunner subclass).
({CommandRunner<int> runner, StringBuffer stdout, StringBuffer stderr})
buildTestRunner() {
  final out = StringBuffer();
  final err = StringBuffer();
  final cli = CliRunner(stdout: out, stderr: err);
  return (runner: cli.runner, stdout: out, stderr: err);
}
