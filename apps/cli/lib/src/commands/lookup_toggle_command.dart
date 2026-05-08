/// `acdg lookup toggle <table-name> <item-id> --active=true|false` — flip the
/// active flag of a lookup item (C08).
///
/// **First PATCH endpoint surfaced by the CLI.** PATCHes
/// `/lookups/<tableName>/<itemId>/toggle` with the [ToggleLookupItemRequest]
/// body shape:
///
/// ```json
/// {"active": true|false}
/// ```
///
/// **`--active` is REQUIRED.** Ticket prose hints at server-side flip but the
/// BFF intent (`toggle_lookup_item_intent.dart`) demands an explicit boolean
/// — DTO-as-canon: the CLI MUST pass an explicit `--active=true|false`. The
/// flag is parsed via [bool.parse] (case-insensitive); any value other than
/// `true`/`false` triggers a usage error BEFORE the HTTP call. The body
/// carries a JSON `bool` (not the string `"true"`), pinning the wire type
/// asserted by the BFF intent.
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../errors/cli_error.dart';
import '../session/bff_client.dart';

/// `acdg lookup toggle`.
final class LookupToggleCommand extends Command<int> {
  LookupToggleCommand({
    required this.bffClient,
    required this.formatter,
    this.stdout,
    this.stderr,
  }) {
    argParser.addOption(
      'active',
      help:
          'New active flag (true/false). REQUIRED — the BFF intent demands '
          'an explicit JSON bool on the wire.',
    );
  }

  final BffClient bffClient;
  final OutputFormatter formatter;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'toggle';

  @override
  String get description =>
      'Toggle the active flag of a lookup item (PATCH; admin only).';

  @override
  String get invocation =>
      'acdg lookup toggle <table-name> <item-id> --active=true|false';

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

    final activeRaw = argResults?['active'] as String?;
    if (activeRaw == null || activeRaw.isEmpty) {
      usageException(
        'Missing required option: --active=true|false (DTO requires bool).',
      );
    }
    final bool active;
    try {
      active = bool.parse(activeRaw, caseSensitive: false);
    } on FormatException {
      usageException('--active must be "true" or "false" (got "$activeRaw").');
    }

    final result = await bffClient.patch<Object?>(
      '/lookups/$tableName/$itemId/toggle',
      body: <String, Object?>{'active': active},
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
