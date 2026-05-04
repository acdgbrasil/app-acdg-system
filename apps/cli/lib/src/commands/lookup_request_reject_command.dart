/// `acdg lookup request reject <request-id> [--reason]` — reject a pending
/// lookup governance request (C08).
///
/// Path-only PUT `/lookup-requests/<id>/reject` — `RejectLookupRequestIntent`
/// is path-only with no body parser; the contract method
/// (`rejectLookupRequest(String requestId)`) carries no payload either.
///
/// **`--reason` is OPTIONAL CLI sugar.** The DTO has no `reason` field, but
/// users requested the affordance during ticket discussion. We forward the
/// value verbatim as a body field when present (the BFF intent has no body
/// parser and silently ignores extra keys; future telemetry can pick it up
/// without a schema break). When absent, no body is sent.
///
/// 204 No Content → exit 0. 4xx/5xx → non-zero exit + stderr.
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../session/bff_client.dart';
import '_command_helpers.dart';

/// `acdg lookup request reject`.
final class LookupRequestRejectCommand extends Command<int> {
  LookupRequestRejectCommand({
    required this.bffClient,
    required this.formatter,
    this.stdout,
    this.stderr,
  }) {
    argParser.addOption(
      'reason',
      help:
          'Optional rejection reason (free-text). NOTE: not in the DTO; '
          'forwarded as an extra body key — currently ignored by the BFF.',
    );
  }

  final BffClient bffClient;
  final OutputFormatter formatter;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'reject';

  @override
  String get description => 'Reject a pending lookup governance request.';

  @override
  String get invocation =>
      'acdg lookup request reject <request-id> [--reason=...]';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      usageException('Missing required positional argument: <request-id>');
    }
    final requestId = rest.first;

    final reason = argResults?['reason'] as String?;
    final body = (reason != null && reason.isNotEmpty)
        ? <String, Object?>{'reason': reason}
        : null;

    final result = await bffClient.put<Object?>(
      '/lookup-requests/$requestId/reject',
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
