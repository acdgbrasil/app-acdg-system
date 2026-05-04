/// `acdg patient withdraw <patient-id> --reason [--notes]` (C03).
///
/// POSTs `/patients/<id>/withdraw` with the [WithdrawPatientRequest] shape:
/// `{"reason": ..., "notes"?: ...}`.
///
/// Note: ticket prose marked `--reason` as optional, but the DTO declares
/// `reason` as REQUIRED — the CLI mirrors the DTO and fails fast in the
/// CLI rather than letting the BFF return 400 (W0 REPORT §4.1).
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../session/bff_client.dart';
import '_patient_helpers.dart';

/// `acdg patient withdraw`.
final class PatientWithdrawCommand extends Command<int> {
  PatientWithdrawCommand({
    required this.bffClient,
    required this.formatter,
    this.stdout,
    this.stderr,
  }) {
    argParser
      ..addOption('reason', help: 'Reason for withdraw (required)')
      ..addOption('notes', help: 'Optional notes');
  }

  final BffClient bffClient;
  final OutputFormatter formatter;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'withdraw';

  @override
  String get description => 'Withdraw a patient from the waitlist.';

  @override
  String get invocation =>
      'acdg patient withdraw <patient-id> --reason=X [--notes=...]';

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
      '/patients/$patientId/withdraw',
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
