/// `acdg lookup request approve <request-id>` — approve a pending lookup
/// governance request (C08).
///
/// Path-only PUT `/lookup-requests/<id>/approve` — `ApproveLookupRequestIntent`
/// has no body parser. UUID v4 validation is enforced server-side; the CLI
/// forwards the path verbatim and surfaces the BFF error
/// `INVALID_APPROVE_LOOKUP_REQUEST_PARAMS` on the wire when a non-UUID id is
/// passed.
///
/// 204 No Content → exit 0. 4xx/5xx → non-zero exit + stderr.
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../session/bff_client.dart';
import '_command_helpers.dart';

/// `acdg lookup request approve`.
final class LookupRequestApproveCommand extends Command<int> {
  LookupRequestApproveCommand({
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
  String get name => 'approve';

  @override
  String get description => 'Approve a pending lookup governance request.';

  @override
  String get invocation => 'acdg lookup request approve <request-id>';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      usageException('Missing required positional argument: <request-id>');
    }
    final requestId = rest.first;

    final result = await bffClient.put<Object?>(
      '/lookup-requests/$requestId/approve',
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
