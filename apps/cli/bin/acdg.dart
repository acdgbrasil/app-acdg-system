/// `acdg` CLI entrypoint.
///
/// Wires the host process's stdout/stderr into [CliRunner], runs the
/// requested command, and exits with the propagated code.
library;

import 'dart:io';

import 'package:cli/src/cli_runner.dart';

Future<void> main(List<String> args) async {
  final runner = CliRunner(stdout: stdout, stderr: stderr);
  final exitCode = await runner.run(args);
  await stdout.flush();
  await stderr.flush();
  exit(exitCode);
}
