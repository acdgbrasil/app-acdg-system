/// `acdg family assign-caregiver <patient-id> --member-id=<uuid>` (C04).
///
/// PUTs `/patients/<id>/primary-caregiver` with the
/// [AssignPrimaryCaregiverRequest] body shape:
/// `{"memberPersonId": "<uuid>"}`.
///
/// CLI flag is `--member-id` (UI-friendly, symmetric with `family remove`);
/// it maps to the wire-format key `memberPersonId` per W0 §4.7.
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../errors/cli_error.dart';
import '../session/bff_client.dart';

/// `acdg family assign-caregiver`.
final class FamilyAssignCaregiverCommand extends Command<int> {
  FamilyAssignCaregiverCommand({
    required this.bffClient,
    required this.formatter,
    this.stdout,
    this.stderr,
  }) {
    argParser.addOption(
      'member-id',
      help: 'Family member id to mark as primary caregiver (UUID v4, required)',
    );
  }

  final BffClient bffClient;
  final OutputFormatter formatter;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'assign-caregiver';

  @override
  String get description =>
      'Mark an existing family member as the primary caregiver for a patient.';

  @override
  String get invocation =>
      'acdg family assign-caregiver <patient-id> --member-id=<uuid>';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      usageException('Missing required positional argument: <patient-id>');
    }
    final patientId = rest.first;

    final memberId = argResults?['member-id'] as String?;
    if (memberId == null || memberId.isEmpty) {
      usageException('Missing required option: --member-id');
    }

    final result = await bffClient.put<Object?>(
      '/patients/$patientId/primary-caregiver',
      body: <String, Object?>{'memberPersonId': memberId},
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
