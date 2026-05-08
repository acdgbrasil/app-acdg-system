/// `acdg lookup create <table-name> --code --label` — admin-only lookup item
/// creation (C08).
///
/// POSTs `/lookups/<tableName>` with the [CreateLookupItemRequest] body shape:
///
/// ```json
/// {
///   "codigo": "<code>",
///   "descricao": "<label>"
/// }
/// ```
///
/// On success, decodes the BFF envelope `{data:{id:"<uuid>"}, meta:{...}}`
/// (per `lookup_handler.dart:_respondWithId` + `StandardResponse<IdData>`)
/// via the shared [decodeStandardIdResponse] helper and surfaces the new
/// item id on stdout.
///
/// **DTO-as-canon (deviation from CLI flag spelling).** Ticket prose uses
/// `--code=X --label=Y`. The DTO is `{codigo, descricao}` — the CLI translates
/// to DTO field names on the wire. Mirrors C03 W2 M1: DTO names dominate the
/// WIRE; CLI flags can be human-friendly.
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../errors/cli_error.dart';
import '../session/bff_client.dart';
import '_command_helpers.dart';

/// `acdg lookup create`.
final class LookupCreateCommand extends Command<int> {
  LookupCreateCommand({
    required this.bffClient,
    required this.formatter,
    this.stdout,
    this.stderr,
  }) {
    argParser
      ..addOption('code', help: 'Lookup item code (required, DTO `codigo`)')
      ..addOption(
        'label',
        help: 'Lookup item description (required, DTO `descricao`)',
      );
  }

  final BffClient bffClient;
  final OutputFormatter formatter;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'create';

  @override
  String get description =>
      'Create a new lookup item in <table-name> (admin only).';

  @override
  String get invocation =>
      'acdg lookup create <table-name> --code=... --label=...';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      usageException('Missing required positional argument: <table-name>');
    }
    final tableName = rest.first;

    final code = argResults?['code'] as String?;
    if (code == null || code.isEmpty) {
      usageException('Missing required option: --code');
    }
    final label = argResults?['label'] as String?;
    if (label == null || label.isEmpty) {
      usageException('Missing required option: --label');
    }

    final body = <String, Object?>{'codigo': code, 'descricao': label};

    final result = await bffClient.post<String?>(
      '/lookups/$tableName',
      body: body,
      decode: decodeStandardIdResponse,
    );
    switch (result) {
      case Success(:final value):
        if (value != null && value.isNotEmpty) {
          _writeOut('Created lookup item $value');
        } else {
          // Defensive: if the envelope lacked an id, fall back to a generic
          // success line so callers still see exit 0 with non-empty stdout.
          _writeOut('Lookup item created');
        }
        return 0;
      case Failure(:final error):
        final e = error as CliError;
        _writeErr(e.stderrMessage);
        return e.exitCode;
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
