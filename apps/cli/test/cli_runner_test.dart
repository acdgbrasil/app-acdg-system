/// W0.5 RED — `CliRunner` contract.
///
/// These tests fail to compile until W1 creates `apps/cli/lib/src/cli_runner.dart`
/// exposing a `CliRunner` class that wires an `args.CommandRunner<int>` with
/// the 9 sub-commands (auth, patient, family, assessment, care, protection,
/// lookup, team, health) and the global flags `--bff`, `--output`, `--quiet`.
///
/// Contract for W1:
/// * `CliRunner({required StringSink stdout, required StringSink stderr})`
/// * `CommandRunner<int> get runner`
/// * `Future<int> run(List<String> args)` — delegates to `runner.run`.
library;

import 'package:args/command_runner.dart';
import 'package:test/test.dart';

import 'package:cli/src/cli_runner.dart';

import 'commands/_command_test_helpers.dart';

void main() {
  group('CliRunner', () {
    test('1. --help lists all 9 sub-commands', () async {
      final (:runner, :stdout, :stderr) = buildTestRunner();

      await runner.run(['--help']);

      final output = stdout.toString();
      // The 9 sub-commands per Phase 5 ticket spec (auth=C02 … team=C09 + health).
      const expectedCommands = <String>[
        'auth',
        'patient',
        'family',
        'assessment',
        'care',
        'protection',
        'lookup',
        'team',
        'health',
      ];
      for (final cmd in expectedCommands) {
        expect(
          output,
          contains(cmd),
          reason: '--help should advertise sub-command "$cmd"',
        );
      }
    });

    test('2. --help lists global flags --bff, --output, --quiet', () async {
      final (:runner, :stdout, :stderr) = buildTestRunner();

      await runner.run(['--help']);

      final output = stdout.toString();
      expect(output, contains('--bff'));
      expect(output, contains('--output'));
      expect(output, contains('--quiet'));
    });

    test(
      '3. unknown command → non-zero exit + error written to stderr',
      () async {
        final (:runner, :stdout, :stderr) = buildTestRunner();

        // CommandRunner throws UsageException on unknown commands; the CliRunner
        // wrapper must catch + map to a non-zero exit code AND surface a helpful
        // message on stderr (similar to `gh`/`git`/`docker`).
        final cli = CliRunner(stdout: stdout, stderr: stderr);
        final exitCode = await cli.run(['definitely-not-a-real-command']);

        expect(exitCode, isNot(equals(0)));
        expect(
          stderr.toString(),
          isNotEmpty,
          reason: 'unknown command should produce stderr output',
        );
      },
    );

    test('4. CliRunner accepts injectable stdout/stderr sinks', () async {
      final out = StringBuffer();
      final err = StringBuffer();
      final cli = CliRunner(stdout: out, stderr: err);

      expect(cli.runner, isA<CommandRunner<int>>());
      // Must not throw on construction with custom sinks.
      expect(cli, isNotNull);
    });

    test('5. runner executable name is "acdg" (binary D3)', () async {
      final (:runner, :stdout, :stderr) = buildTestRunner();
      // Per ticket D3, compiled binary is "acdg" — runner.executableName must
      // match so generated `--help` text reads `Usage: acdg <command> ...`.
      expect(runner.executableName, equals('acdg'));
    });
  });
}
