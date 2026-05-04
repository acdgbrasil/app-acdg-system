/// `acdg lookup batch <a,b,c>` — fetch multiple lookup tables at once (C08).
///
/// GETs `/lookups?tables=a,b,c` and renders the `data.tables` payload via the
/// injected [OutputFormatter].
///
/// **Tolerant CSV parsing** (mirrored from
/// `apps/social_care_bff/lib/src/intents/governance/get_lookups_batch_intent.dart`):
/// `"a, b ,c"` → `[a, b, c]`. Whitespace trimmed, empty tokens dropped.
///
/// **Cap of 20 tables** (BFF `GetLookupsBatchIntent.maxTables`). The CLI fails
/// fast client-side: 21+ → usage error, NO BFF round trip.
///
/// **CSV-on-the-wire.** The query parameter spelling is exactly `tables=...`
/// (a single CSV value), matching the BFF intent which reads
/// `queryParameters['tables']` and runs the same tolerant split. Sending the
/// CSV in one query value (instead of repeated `tables=` keys) keeps the URL
/// shorter and round-trips through Dio + Hono unambiguously.
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../session/bff_client.dart';
import '_command_helpers.dart';

/// Maximum number of tables accepted by the BFF in one batch call.
const int _kBatchTableCap = 20;

/// `acdg lookup batch`.
final class LookupBatchCommand extends Command<int> {
  LookupBatchCommand({
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
  String get name => 'batch';

  @override
  String get description =>
      'Fetch up to 20 lookup tables in a single round trip.';

  @override
  String get invocation =>
      'acdg lookup batch <table1,table2,...> (cap of 20 tables)';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      usageException(
        'Missing required positional argument: <csv> (e.g. dominio_a,dominio_b)',
      );
    }
    final raw = rest.first;
    final tables = raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
    if (tables.isEmpty) {
      usageException(
        'Empty table list: <csv> must contain at least one non-blank name.',
      );
    }
    if (tables.length > _kBatchTableCap) {
      usageException(
        'Too many tables (${tables.length}): cap is $_kBatchTableCap. '
        'Split the request into smaller batches.',
      );
    }

    final result = await bffClient.get<Object?>(
      '/lookups',
      queryParameters: <String, Object?>{'tables': tables.join(',')},
    );
    switch (result) {
      case Success(:final value):
        final map = value is Map<String, Object?> ? value : null;
        final data = map?['data'];
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
