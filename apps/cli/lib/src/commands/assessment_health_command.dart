/// `acdg assessment health <patient-id>` — update the health-status ficha
/// (C05).
///
/// PUTs `/patients/{id}/assessment/health` with the
/// [UpdateHealthStatusRequest] body shape:
///   * `foodInsecurity` — required bool flag,
///   * `constantCareNeeds` — repeatable `--constant-care-need` strings,
///   * `deficiencies`, `gestatingMembers` — nested DTO lists; only
///     `--from-yaml` populates non-empty values.
///
/// PII note: `DeficiencyDraftDto.responsibleCaregiverName` is free-form text.
/// The BFF intent guarantees its parse-error messages NEVER echo caregiver
/// names; the CLI mirrors the same discipline by surfacing only the BFF's
/// structural error (`stderrMessageFor`) — no raw flag values are inserted
/// into stderr beyond the BFF response.
library;

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../session/bff_client.dart';
import '_command_helpers.dart';
import '_yaml_helpers.dart';

/// `acdg assessment health`.
final class AssessmentHealthCommand extends Command<int> {
  AssessmentHealthCommand({
    required this.bffClient,
    required this.formatter,
    required this.fileReader,
    this.stdout,
    this.stderr,
  }) {
    argParser
      ..addOption('from-yaml', help: 'Path to a YAML payload override.')
      ..addOption(
        'food-insecurity',
        help: 'true|false — household reports food insecurity (required).',
      )
      ..addMultiOption(
        'constant-care-need',
        help: 'Repeatable: constant-care-need code.',
      );
  }

  final BffClient bffClient;
  final OutputFormatter formatter;
  final Future<String> Function(String path) fileReader;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'health';

  @override
  String get description =>
      'Update the health-status ficha (--food-insecurity required; '
      'deficiencies[]/gestatingMembers[] only via --from-yaml).';

  @override
  String get invocation =>
      'acdg assessment health <patient-id> [--from-yaml=<path> | '
      '--food-insecurity=true|false [--constant-care-need=<code> ...]]';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      usageException('Missing required positional argument: <patient-id>');
    }
    final patientId = rest.first;

    final fromYaml = argResults?['from-yaml'] as String?;
    final foodInsecurityRaw = argResults?['food-insecurity'] as String?;
    final constantCareNeeds =
        (argResults?['constant-care-need'] as List<String>?) ??
        const <String>[];
    final hasAnyFlag =
        (foodInsecurityRaw != null && foodInsecurityRaw.isNotEmpty) ||
        constantCareNeeds.isNotEmpty;

    if (fromYaml != null && fromYaml.isNotEmpty && hasAnyFlag) {
      usageException(
        '--from-yaml is mutually exclusive with field flags '
        '(--food-insecurity, --constant-care-need).',
      );
    }

    final Map<String, Object?> body;
    if (fromYaml != null && fromYaml.isNotEmpty) {
      final parsed = await readYamlBody(path: fromYaml, fileReader: fileReader);
      switch (parsed) {
        case Success(:final value):
          body = value;
        case Failure(:final error):
          _writeErr(stderrMessageFor(error));
          return exitCodeFor(error);
      }
    } else {
      body = _buildBodyFromFlags(constantCareNeeds);
    }

    final result = await bffClient.put<Object?>(
      '/patients/$patientId/assessment/health',
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

  Map<String, Object?> _buildBodyFromFlags(List<String> constantCareNeeds) {
    final r = argResults!;
    final foodInsecurity = _requireBool(r, 'food-insecurity');
    return <String, Object?>{
      'deficiencies': <Object?>[],
      'gestatingMembers': <Object?>[],
      'constantCareNeeds': List<String>.unmodifiable(constantCareNeeds),
      'foodInsecurity': foodInsecurity,
    };
  }

  bool _requireBool(ArgResults r, String name) {
    final value = r[name] as String?;
    if (value == null || value.isEmpty) {
      usageException('Missing required option: --$name');
    }
    final lower = value.toLowerCase();
    if (lower == 'true') return true;
    if (lower == 'false') return false;
    usageException('--$name must be true|false (got "$value").');
  }

  void _writeErr(String line) {
    final err = stderr ?? stdout;
    if (err != null) err.writeln(line);
  }
}
