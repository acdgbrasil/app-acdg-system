/// `acdg patient get <patient-id>` — single patient detail fetch (C03).
///
/// GETs `/patients/<id>` and renders the `data` payload via the injected
/// [OutputFormatter]. Missing positional `<patient-id>` → usage error.
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../session/bff_client.dart';
import '_command_helpers.dart';

/// `acdg patient get`.
final class PatientGetCommand extends Command<int> {
  PatientGetCommand({
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
  String get name => 'get';

  @override
  String get description => 'Fetch a single patient by id (full detail).';

  @override
  String get invocation => 'acdg patient get <patient-id>';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      usageException('Missing required positional argument: <patient-id>');
    }
    final patientId = rest.first;

    final result = await bffClient.get<Object?>('/patients/$patientId');
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
