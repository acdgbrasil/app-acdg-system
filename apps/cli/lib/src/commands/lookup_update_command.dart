/// `acdg lookup update <table-name> <item-id> [--code] [--label]` — partial
/// update of a lookup item (C08).
///
/// PUTs `/lookups/<tableName>/<itemId>` with the partial
/// [UpdateLookupItemRequest] body shape:
///
/// ```json
/// {"codigo"?: "...", "descricao"?: "..."}
/// ```
///
/// Both flags are OPTIONAL — the BFF DTO is partial and the intent
/// (`update_lookup_item_intent.dart`) is "P2-tolerant": missing/null fields
/// collapse to `null`, never produce a parse error. We use the shared
/// `dropNulls` helper so absent flags are OMITTED from the JSON envelope
/// (DTO `?` field convention).
///
/// **`active` is intentionally NOT exposed here.** Ticket prose mentions
/// `--active=true|false`, but the DTO `UpdateLookupItemRequest` carries
/// `{codigo?, descricao?}` only. The dedicated `lookup toggle` verb
/// (PATCH `/lookups/<table>/<id>/toggle`) owns the active flag flip.
/// Pinning that here avoids smuggling an `active` key onto the update wire.
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../session/bff_client.dart';
import '_command_helpers.dart';

/// `acdg lookup update`.
final class LookupUpdateCommand extends Command<int> {
  LookupUpdateCommand({
    required this.bffClient,
    required this.formatter,
    this.stdout,
    this.stderr,
  }) {
    argParser
      ..addOption(
        'code',
        help: 'New code (optional, partial update — DTO `codigo`)',
      )
      ..addOption(
        'label',
        help: 'New description (optional, partial update — DTO `descricao`)',
      );
  }

  final BffClient bffClient;
  final OutputFormatter formatter;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'update';

  @override
  String get description =>
      'Partially update a lookup item (code and/or label).';

  @override
  String get invocation =>
      'acdg lookup update <table-name> <item-id> [--code=...] [--label=...]';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      usageException('Missing required positional argument: <table-name>');
    }
    if (rest.length < 2) {
      usageException('Missing required positional argument: <item-id>');
    }
    final tableName = rest[0];
    final itemId = rest[1];

    final body = dropNulls(<String, Object?>{
      'codigo': argResults?['code'] as String?,
      'descricao': argResults?['label'] as String?,
    });

    final result = await bffClient.put<Object?>(
      '/lookups/$tableName/$itemId',
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
