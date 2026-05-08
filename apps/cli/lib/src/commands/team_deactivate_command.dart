/// `acdg team deactivate <member-id>` — deactivate a team member (C09).
///
/// Path-only PUT `/team/<member-id>/deactivate` —
/// `DeactivateWorkerIntent.parseFromPath` has no body parser. UUID v4
/// validation is enforced server-side; the CLI forwards the path verbatim
/// and surfaces the BFF error `INVALID_DEACTIVATE_WORKER_PARAMS` on the
/// wire when a non-UUID id is passed.
///
/// 200/204 → exit 0. 4xx/5xx → non-zero exit + stderr.
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../errors/cli_error.dart';
import '../session/bff_client.dart';

/// `acdg team deactivate`.
final class TeamDeactivateCommand extends Command<int> {
  TeamDeactivateCommand({
    required this.bffClient,
    required this.formatter,
    this.stdout,
    this.stderr,
  });

  final BffClient bffClient;
  final OutputFormatter formatter;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'deactivate';

  @override
  String get description => 'Deactivate a team member.';

  @override
  String get invocation => 'acdg team deactivate <member-id>';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      usageException('Missing required positional argument: <member-id>');
    }
    final memberId = rest.first;

    final result = await bffClient.put<Object?>('/team/$memberId/deactivate');
    switch (result) {
      case Success():
        return 0;
      case Failure(:final error):
        final e = error as CliError;
        _writeErr(e.stderrMessage);
        return e.exitCode;
    }
  }

  void _writeErr(String line) {
    final err = stderr ?? stdout;
    if (err != null) err.writeln(line);
  }
}
