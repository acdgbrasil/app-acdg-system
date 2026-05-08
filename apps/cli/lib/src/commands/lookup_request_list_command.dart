/// `acdg lookup request list` — list all governance requests (C08).
///
/// GETs `/lookup-requests` (no parameters) and renders the `data` payload (a
/// list of `LookupRequestResponse` objects) via the injected
/// [OutputFormatter]. Mirrors the `GetLookupRequestsIntent` empty value
/// object — no positionals, no flags.
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../errors/cli_error.dart';
import '../session/bff_client.dart';

/// `acdg lookup request list`.
final class LookupRequestListCommand extends Command<int> {
  LookupRequestListCommand({
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
  String get name => 'list';

  @override
  String get description => 'List all pending lookup governance requests.';

  @override
  String get invocation => 'acdg lookup request list';

  @override
  Future<int> run() async {
    final result = await bffClient.get<Object?>('/lookup-requests');
    switch (result) {
      case Success(:final value):
        final data = value is Map<String, Object?> ? value['data'] : value;
        _writeOut(formatter.format(data));
        return 0;
      case Failure(:final error):
        final e = error as CliError;
        _writeErr(e.stderrMessage);
        return e.exitCode;
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
