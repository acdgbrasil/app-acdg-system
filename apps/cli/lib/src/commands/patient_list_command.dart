/// `acdg patient list` — paginated patient summary listing (C03).
///
/// GETs `/patients` with optional `search`, `status`, `cursor`, `limit`
/// query parameters. Format the page payload via the injected
/// [OutputFormatter]; surface `meta.nextCursor` (when present) on stderr
/// so the stdout stream stays clean for piping.
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../session/bff_client.dart';
import '_command_helpers.dart';

/// `acdg patient list`.
final class PatientListCommand extends Command<int> {
  PatientListCommand({
    required this.bffClient,
    required this.formatter,
    this.stdout,
    this.stderr,
  }) {
    argParser
      ..addOption('search', help: 'Search by name / CPF / patientId')
      ..addOption('status', help: 'Filter by lifecycle status')
      ..addOption('cursor', help: 'Pagination cursor (opaque)')
      ..addOption('limit', help: 'Max items per page');
  }

  final BffClient bffClient;
  final OutputFormatter formatter;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'list';

  @override
  String get description =>
      'List patients (paginated; supports search, status, cursor).';

  @override
  Future<int> run() async {
    final query = <String, String>{};
    final search = argResults?['search'] as String?;
    final status = argResults?['status'] as String?;
    final cursor = argResults?['cursor'] as String?;
    final limit = argResults?['limit'] as String?;
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (cursor != null && cursor.isNotEmpty) query['cursor'] = cursor;
    if (limit != null && limit.isNotEmpty) query['limit'] = limit;

    final path = query.isEmpty
        ? '/patients'
        : '/patients?${Uri(queryParameters: query).query}';

    final result = await bffClient.get<Object?>(path);
    switch (result) {
      case Success(:final value):
        final map = value is Map<String, Object?> ? value : null;
        final data = map?['data'];
        _writeOut(formatter.format(data));
        // Surface pagination cursor on stderr when present (W0 §4.2).
        final meta = map?['meta'];
        if (meta is Map<String, Object?>) {
          final nextCursor = meta['nextCursor'];
          if (nextCursor is String && nextCursor.isNotEmpty) {
            _writeErr('Next page cursor: $nextCursor');
          }
        }
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
