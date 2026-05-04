/// `acdg assessment work-income <patient-id>` — update the work & income
/// ficha (C05).
///
/// PUTs `/patients/{id}/assessment/work-income` with the
/// [UpdateWorkAndIncomeRequest] body shape:
///   * `hasRetiredMembers` — required bool flag,
///   * `individualIncomes`, `socialBenefits` — nested lists; default empty.
///     Only `--from-yaml` populates non-empty values (no flag-based form
///     expressive enough for the nested DTOs).
library;

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../session/bff_client.dart';
import '_command_helpers.dart';
import '_yaml_helpers.dart';

/// `acdg assessment work-income`.
final class AssessmentWorkIncomeCommand extends Command<int> {
  AssessmentWorkIncomeCommand({
    required this.bffClient,
    required this.formatter,
    required this.fileReader,
    this.stdout,
    this.stderr,
  }) {
    argParser
      ..addOption('from-yaml', help: 'Path to a YAML payload override.')
      ..addOption(
        'has-retired-members',
        help: 'true|false — at least one retired family member (required).',
      );
  }

  final BffClient bffClient;
  final OutputFormatter formatter;
  final Future<String> Function(String path) fileReader;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'work-income';

  @override
  String get description =>
      'Update the work-and-income ficha (--has-retired-members required; '
      'individualIncomes[]/socialBenefits[] only via --from-yaml).';

  @override
  String get invocation =>
      'acdg assessment work-income <patient-id> [--from-yaml=<path> | '
      '--has-retired-members=true|false]';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      usageException('Missing required positional argument: <patient-id>');
    }
    final patientId = rest.first;

    final fromYaml = argResults?['from-yaml'] as String?;
    final hasRetiredMembersRaw = argResults?['has-retired-members'] as String?;
    final hasAnyFlag =
        hasRetiredMembersRaw != null && hasRetiredMembersRaw.isNotEmpty;

    if (fromYaml != null && fromYaml.isNotEmpty && hasAnyFlag) {
      usageException(
        '--from-yaml is mutually exclusive with field flags '
        '(--has-retired-members).',
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
      body = _buildBodyFromFlags();
    }

    final result = await bffClient.put<Object?>(
      '/patients/$patientId/assessment/work-income',
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

  Map<String, Object?> _buildBodyFromFlags() {
    final r = argResults!;
    final hasRetiredMembers = _requireBool(r, 'has-retired-members');
    return <String, Object?>{
      'individualIncomes': <Object?>[],
      'socialBenefits': <Object?>[],
      'hasRetiredMembers': hasRetiredMembers,
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
