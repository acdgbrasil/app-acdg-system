/// `acdg protection placement-history <patient-id>` — replace the patient's
/// placement-history aggregate (C07).
///
/// PUTs `/patients/{id}/placement-history` with the
/// [UpdatePlacementHistoryRequest] body shape — a tree of nested DTOs with
/// `List<RegistryDraftDto>` and 2 optional sub-DTOs:
///
/// ```json
/// {
///   "registries": [
///     {
///       "memberId": "<uuid>",
///       "startDate": "<iso8601>",
///       "reason": "<text>",
///       "endDate": "<iso8601-or-omitted>"
///     }
///   ],
///   "collectiveSituations": {
///     "homeLossReport": "<str-or-omitted>",
///     "thirdPartyGuardReport": "<str-or-omitted>"
///   },
///   "separationChecklist": {
///     "adultInPrison": <bool>,
///     "adolescentInInternment": <bool>
///   }
/// }
/// ```
///
/// **YAML-only verb.** Per ticket §Detalhes ("exigir `--from-yaml` por
/// padrão") + W0 §3.3, the nested-DTO shape does not flatten to a flag-
/// friendly surface, so the only way to drive this command is
/// `--from-yaml=<path>`. There is no field-flag fallback. The flag spelling
/// is `--from-yaml` (NOT the ticket prose `--history-yaml`) for symmetry
/// with C03 patient register + C05 assessment fichas.
///
/// Filesystem and YAML parse errors are translated by [readYamlBody] into
/// [InvalidArgError] so the orchestration here remains `try`-free.
///
/// Returns exit 0 on 200 (envelope `{data:null,meta:...}`) OR 204 No Content;
/// the BFF handler may use either depending on the topology.
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../session/bff_client.dart';
import '_command_helpers.dart';
import '_yaml_helpers.dart';

/// `acdg protection placement-history`.
final class ProtectionPlacementHistoryCommand extends Command<int> {
  ProtectionPlacementHistoryCommand({
    required this.bffClient,
    required this.formatter,
    required this.fileReader,
    this.stdout,
    this.stderr,
  }) {
    // YAML-ONLY per ticket §Detalhes: "exigir `--from-yaml` por padrão".
    // The DTO is a tree (List<RegistryDraftDto> with nested
    // memberId/startDate/reason tuples + 2 optional sub-DTOs) that does
    // not flatten to flag-friendly scalars. No field-flag fallback —
    // the only way to drive this verb is `--from-yaml=<path>`.
    argParser.addOption(
      'from-yaml',
      help:
          'Path to a YAML payload (REQUIRED). The file must match '
          'UpdatePlacementHistoryRequest schema.',
    );
  }

  final BffClient bffClient;
  final OutputFormatter formatter;
  final Future<String> Function(String path) fileReader;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'placement-history';

  @override
  String get description =>
      'Replace the patient placement-history aggregate (YAML-only).';

  @override
  String get invocation =>
      'acdg protection placement-history <patient-id> --from-yaml=<path>';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      usageException('Missing required positional argument: <patient-id>');
    }
    final patientId = rest.first;

    final fromYaml = argResults?['from-yaml'] as String?;
    if (fromYaml == null || fromYaml.isEmpty) {
      // No field-flag fallback: per ticket "exigir --from-yaml por padrão".
      usageException(
        'Missing required option: --from-yaml=<path> '
        '(this verb has no field-flag fallback).',
      );
    }

    final yamlResult = await readYamlBody(
      path: fromYaml,
      fileReader: fileReader,
    );
    final Map<String, Object?> body;
    switch (yamlResult) {
      case Success(:final value):
        body = value;
      case Failure(:final error):
        _writeErr(stderrMessageFor(error));
        return exitCodeFor(error);
    }

    final result = await bffClient.put<Object?>(
      '/patients/$patientId/placement-history',
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
