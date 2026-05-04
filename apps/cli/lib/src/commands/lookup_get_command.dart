/// `acdg lookup get <table-name>` — fetch a lookup table (C08).
///
/// GETs `/lookups/<tableName>` and renders the `data` payload (a list of
/// `LookupItemResponse` objects) via the injected [OutputFormatter].
///
/// `tableName` is a literal pass-through — NOT UUID-validated, mirroring the
/// BFF `GetLookupTableIntent` (path-only, accepts arbitrary literals like
/// `dominio_parentesco`, `dominio_genero`, etc.). Missing positional →
/// usage error (no BFF call).
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../session/bff_client.dart';
import '_command_helpers.dart';

/// `acdg lookup get`.
final class LookupGetCommand extends Command<int> {
  LookupGetCommand({
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
  String get description => 'Fetch a lookup table by name (full item list).';

  @override
  String get invocation => 'acdg lookup get <table-name>';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      usageException('Missing required positional argument: <table-name>');
    }
    final tableName = rest.first;

    final result = await bffClient.get<Object?>('/lookups/$tableName');
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
