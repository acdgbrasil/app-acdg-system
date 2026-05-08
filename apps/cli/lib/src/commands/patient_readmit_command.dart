/// `acdg patient readmit <patient-id> [--notes]` (C03).
///
/// POSTs `/patients/<id>/readmit` with the [ReadmitPatientRequest] shape:
/// `{"notes"?: ...}`. When no flag is provided the body is an empty map
/// (`notes` key omitted).
///
/// Note: ticket prose mentioned `--reason`, but the DTO does NOT accept a
/// reason — the CLI follows the DTO (W0 REPORT §4.1).
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../errors/cli_error.dart';
import '../session/bff_client.dart';
import '_command_helpers.dart';

/// `acdg patient readmit`.
final class PatientReadmitCommand extends Command<int> {
  PatientReadmitCommand({
    required this.bffClient,
    required this.formatter,
    this.stdout,
    this.stderr,
  }) {
    argParser.addOption('notes', help: 'Optional notes');
  }

  final BffClient bffClient;
  final OutputFormatter formatter;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'readmit';

  @override
  String get description => 'Readmit a previously-discharged patient.';

  @override
  String get invocation => 'acdg patient readmit <patient-id> [--notes=...]';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      usageException('Missing required positional argument: <patient-id>');
    }
    final patientId = rest.first;

    final body = dropNulls(<String, Object?>{
      'notes': argResults?['notes'] as String?,
    });

    final result = await bffClient.post<Object?>(
      '/patients/$patientId/readmit',
      body: body,
    );
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
