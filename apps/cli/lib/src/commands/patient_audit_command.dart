/// `acdg patient audit <patient-id> [--event-type=...]` — patient audit
/// trail listing (C03).
///
/// GETs `/patients/<id>/audit-trail`. The optional `--event-type` filter
/// lands on the wire as the camelCase `eventType` query parameter
/// (matches `get_audit_trail_intent.dart` which reads `query['eventType']`).
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../session/bff_client.dart';
import '_command_helpers.dart';

/// `acdg patient audit`.
final class PatientAuditCommand extends Command<int> {
  PatientAuditCommand({
    required this.bffClient,
    required this.formatter,
    this.stdout,
    this.stderr,
  }) {
    argParser
      ..addOption(
        'event-type',
        help: 'Filter by event type (e.g. patient.admitted)',
      )
      ..addOption('limit', help: 'Max items per page')
      ..addOption('offset', help: 'Offset for pagination');
  }

  final BffClient bffClient;
  final OutputFormatter formatter;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'audit';

  @override
  String get description => 'List the audit trail for a patient.';

  @override
  String get invocation =>
      'acdg patient audit <patient-id> [--event-type=...] [--limit=...] [--offset=...]';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      usageException('Missing required positional argument: <patient-id>');
    }
    final patientId = rest.first;

    final query = <String, String>{};
    final eventType = argResults?['event-type'] as String?;
    final limit = argResults?['limit'] as String?;
    final offset = argResults?['offset'] as String?;
    if (eventType != null && eventType.isNotEmpty) {
      // Wire format is camelCase — `get_audit_trail_intent.dart` reads
      // `query['eventType']`. W0 §4.3 source claim of snake_case was wrong;
      // BFF tests confirm camelCase is canonical (W2 M1 fix).
      query['eventType'] = eventType;
    }
    if (limit != null && limit.isNotEmpty) query['limit'] = limit;
    if (offset != null && offset.isNotEmpty) query['offset'] = offset;

    final base = '/patients/$patientId/audit-trail';
    final path = query.isEmpty
        ? base
        : '$base?${Uri(queryParameters: query).query}';

    final result = await bffClient.get<Object?>(path);
    switch (result) {
      case Success(:final value):
        final data = value is Map<String, Object?> ? value['data'] : value;
        _writeOut(formatter.format(data));
        return 0;
      case Failure(:final error):
        _writeErr(stderrMessageFor(error));
        return exitCodeFor(error);
    }
  }

  void _writeOut(String text) {
    final out = stdout;
    if (out != null) out.write(text);
  }

  void _writeErr(String line) {
    final err = stderr ?? stdout;
    if (err != null) err.writeln(line);
  }
}
