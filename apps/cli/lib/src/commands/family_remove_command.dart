/// `acdg family remove <patient-id> --member-id=<uuid>` (C04).
///
/// DELETEs `/patients/<id>/family-members/<memberId>` with no body.
/// Successful 204 → exit 0 with a short "removed" stdout confirmation.
/// 404 surfaces "not found" on stderr.
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../session/bff_client.dart';
import '_command_helpers.dart';

/// `acdg family remove`.
final class FamilyRemoveCommand extends Command<int> {
  FamilyRemoveCommand({
    required this.bffClient,
    required this.formatter,
    this.stdout,
    this.stderr,
  }) {
    argParser.addOption(
      'member-id',
      help: 'Family member id (UUID v4, required)',
    );
  }

  final BffClient bffClient;
  final OutputFormatter formatter;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'remove';

  @override
  String get description => 'Remove a family member from a patient roster.';

  @override
  String get invocation => 'acdg family remove <patient-id> --member-id=<uuid>';

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

    final result = await bffClient.delete<Object?>(
      '/patients/$patientId/family-members/$memberId',
    );
    switch (result) {
      case Success():
        _writeOut('Family member $memberId removed from patient $patientId.');
        return 0;
      case Failure(:final error):
        _writeErr(stderrMessageFor(error));
        return exitCodeFor(error);
    }
  }

  void _writeOut(String line) {
    final out = stdout;
    if (out != null) out.writeln(line);
  }

  void _writeErr(String line) {
    final err = stderr ?? stdout;
    if (err != null) err.writeln(line);
  }
}
