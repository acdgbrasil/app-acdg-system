/// `acdg lookup request create <table-name> --code --label [--justificativa]`
/// — submit a new lookup item for governance approval (C08).
///
/// POSTs `/lookup-requests` with the [CreateLookupRequestRequest] body shape:
///
/// ```json
/// {
///   "tableName": "<positional>",
///   "codigo": "<--code>",
///   "descricao": "<--label>",
///   "justificativa": "<optional, omitted when absent>"
/// }
/// ```
///
/// On success, decodes the BFF envelope `{data:{id:"<uuid>"}, meta:{...}}`
/// via the shared [decodeStandardIdResponse] helper and surfaces the new
/// request id on stdout.
///
/// **DTO-as-canon (deviation from CLI flag spelling).** Ticket prose uses
/// `--code=X --label=Y --justificativa=Z`. The DTO is
/// `{tableName, codigo, descricao, justificativa?}`. CLI flags stay
/// human-friendly (`--code`, `--label`); the wire follows the DTO.
/// `justificativa` keeps its Portuguese spelling because the DTO does — that
/// way users can grep BFF errors back to the same name. PII-dense field; the
/// BFF intent never echoes it in error responses (cf.
/// `create_lookup_request_intent.dart`).
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../session/bff_client.dart';
import '_command_helpers.dart';

/// `acdg lookup request create`.
final class LookupRequestCreateCommand extends Command<int> {
  LookupRequestCreateCommand({
    required this.bffClient,
    required this.formatter,
    this.stdout,
    this.stderr,
  }) {
    argParser
      ..addOption('code', help: 'Proposed item code (required, DTO `codigo`)')
      ..addOption(
        'label',
        help: 'Proposed item description (required, DTO `descricao`)',
      )
      ..addOption(
        'justificativa',
        help:
            'Free-text rationale (optional). PII-dense — the BFF intent '
            'never echoes it in error responses.',
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
      'Submit a new lookup item proposal for governance approval.';

  @override
  String get invocation =>
      'acdg lookup request create <table-name> --code=... --label=... '
      '[--justificativa=...]';

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

    final body = dropNulls(<String, Object?>{
      'tableName': tableName,
      'codigo': code,
      'descricao': label,
      'justificativa': argResults?['justificativa'] as String?,
    });

    final result = await bffClient.post<String?>(
      '/lookup-requests',
      body: body,
      decode: decodeStandardIdResponse,
    );
    switch (result) {
      case Success(:final value):
        if (value != null && value.isNotEmpty) {
          _writeOut('Created lookup request $value');
        } else {
          _writeOut('Lookup request created');
        }
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
