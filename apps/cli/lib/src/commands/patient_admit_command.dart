/// `acdg patient admit <patient-id> --reason --admitted-at [--notes]` (C03).
///
/// POSTs `/patients/<id>/admit` with the [AdmitPatientRequest] shape:
/// `{"reason": ..., "admittedAt": ..., "notes": ...}`.
///
/// `--admitted-at` is validated client-side as an ISO8601 timestamp so the
/// CLI fails fast without a HTTP round-trip when the input is malformed.
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../session/bff_client.dart';
import '_patient_helpers.dart';

/// `acdg patient admit`.
final class PatientAdmitCommand extends Command<int> {
  PatientAdmitCommand({
    required this.bffClient,
    required this.formatter,
    this.stdout,
    this.stderr,
  }) {
    argParser
      ..addOption('reason', help: 'Reason for admit (required)')
      ..addOption(
        'admitted-at',
        help: 'ISO8601 admit timestamp, e.g. 2026-04-30T10:00:00Z (required)',
      )
      ..addOption('notes', help: 'Optional notes');
  }

  final BffClient bffClient;
  final OutputFormatter formatter;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'admit';

  @override
  String get description => 'Admit a patient from the waitlist.';

  @override
  String get invocation =>
      'acdg patient admit <patient-id> --reason=X --admitted-at=ISO8601 [--notes=...]';

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

    final admittedAt = argResults?['admitted-at'] as String?;
    if (admittedAt == null || admittedAt.isEmpty) {
      usageException('Missing required option: --admitted-at');
    }

    if (!_isValidIso8601(admittedAt)) {
      usageException(
        '--admitted-at must be a valid ISO8601 timestamp (e.g. 2026-04-30T10:00:00Z); got: "$admittedAt"',
      );
    }

    final body = dropNulls(<String, Object?>{
      'reason': reason,
      'admittedAt': admittedAt,
      'notes': argResults?['notes'] as String?,
    });

    final result = await bffClient.post<Object?>(
      '/patients/$patientId/admit',
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

  bool _isValidIso8601(String input) {
    // Adapter boundary — DateTime.parse throws FormatException on bad input.
    try {
      DateTime.parse(input);
      return true;
    } on FormatException {
      return false;
    }
  }

  void _writeErr(String line) {
    final err = stderr ?? stdout;
    if (err != null) err.writeln(line);
  }
}
