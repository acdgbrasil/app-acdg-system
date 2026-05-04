/// `acdg patient discharge <patient-id> --reason [--notes]` (C03).
///
/// POSTs `/patients/<id>/discharge` with the [DischargePatientRequest] shape:
/// `{"reason": ..., "notes"?: ...}`. The `notes` key is omitted when the
/// flag is absent (DTO is `String? notes`, ServerError default treats absent
/// the same as null).
///
/// Note: ticket prose mentioned `--discharged-at`, but the DTO does NOT
/// accept a timestamp — the CLI follows the DTO (W0 REPORT §4.1).
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../session/bff_client.dart';
import '_command_helpers.dart';

/// `acdg patient discharge`.
final class PatientDischargeCommand extends Command<int> {
  PatientDischargeCommand({
    required this.bffClient,
    required this.formatter,
    this.stdout,
    this.stderr,
  }) {
    argParser
      ..addOption('reason', help: 'Reason for discharge (required)')
      ..addOption('notes', help: 'Optional notes');
  }

  final BffClient bffClient;
  final OutputFormatter formatter;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'discharge';

  @override
  String get description => 'Discharge a currently-admitted patient.';

  @override
  String get invocation =>
      'acdg patient discharge <patient-id> --reason=X [--notes=...]';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      usageException('Missing required positional argument: <patient-id>');
    }
    final patientId = rest.first;

    final reason = argResults?['reason'] as String?;
    if (reason == null || reason.isEmpty) {
      usageException('Missing required option: --reason');
    }

    final body = dropNulls(<String, Object?>{
      'reason': reason,
      'notes': argResults?['notes'] as String?,
    });

    final result = await bffClient.post<Object?>(
      '/patients/$patientId/discharge',
      body: body,
    );
    switch (result) {
      case Success():
        return 0;
      case Failure(:final error):
        _writeErr(stderrMessageFor(error));
        return exitCodeFor(error);
    }
  }

  void _writeErr(String line) {
    final err = stderr ?? stdout;
    if (err != null) err.writeln(line);
  }
}
