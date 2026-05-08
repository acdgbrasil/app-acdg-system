/// `acdg assessment social-health-summary <patient-id>` — update the
/// social-health summary ficha (C05).
///
/// PUTs `/patients/{id}/assessment/social-health-summary` with the
/// [UpdateSocialHealthSummaryRequest] body shape:
///   * 3 required bools — `requiresConstantCare`, `hasMobilityImpairment`,
///     `hasRelevantDrugTherapy`,
///   * `functionalDependencies` — repeatable `--functional-dependency`
///     strings; defaults to empty list.
library;

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../errors/cli_error.dart';
import '../session/bff_client.dart';
import '_yaml_helpers.dart';

/// `acdg assessment social-health-summary`.
final class AssessmentSocialHealthSummaryCommand extends Command<int> {
  AssessmentSocialHealthSummaryCommand({
    required this.bffClient,
    required this.formatter,
    required this.fileReader,
    this.stdout,
    this.stderr,
  }) {
    argParser
      ..addOption('from-yaml', help: 'Path to a YAML payload override.')
      ..addOption(
        'requires-constant-care',
        help: 'true|false — patient requires constant care (required).',
      )
      ..addOption(
        'has-mobility-impairment',
        help: 'true|false — patient has mobility impairment (required).',
      )
      ..addOption(
        'has-relevant-drug-therapy',
        help: 'true|false — patient is on relevant drug therapy (required).',
      )
      ..addMultiOption(
        'functional-dependency',
        help: 'Functional dependency code (repeatable, optional).',
      );
  }

  final BffClient bffClient;
  final OutputFormatter formatter;
  final Future<String> Function(String path) fileReader;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'social-health-summary';

  @override
  String get description =>
      'Update the social-health summary ficha (3 required bools + optional '
      'functional-dependency multi-option).';

  @override
  String get invocation =>
      'acdg assessment social-health-summary <patient-id> [--from-yaml=<path> '
      '| --requires-constant-care=true|false '
      '--has-mobility-impairment=true|false '
      '--has-relevant-drug-therapy=true|false '
      '[--functional-dependency=<code> ...]]';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      usageException('Missing required positional argument: <patient-id>');
    }
    final patientId = rest.first;

    final fromYaml = argResults?['from-yaml'] as String?;
    const scalarFlags = <String>[
      'requires-constant-care',
      'has-mobility-impairment',
      'has-relevant-drug-therapy',
    ];
    final functionalDependencies =
        (argResults?['functional-dependency'] as List<String>?) ??
        const <String>[];
    final hasAnyScalar = scalarFlags.any(
      (f) => (argResults?[f] as String?)?.isNotEmpty ?? false,
    );
    final hasAnyFlag = hasAnyScalar || functionalDependencies.isNotEmpty;

    if (fromYaml != null && fromYaml.isNotEmpty && hasAnyFlag) {
      usageException(
        '--from-yaml is mutually exclusive with field flags '
        '(--requires-constant-care, --functional-dependency, ...).',
      );
    }

    final Map<String, Object?> body;
    if (fromYaml != null && fromYaml.isNotEmpty) {
      final parsed = await readYamlBody(path: fromYaml, fileReader: fileReader);
      switch (parsed) {
        case Success(:final value):
          body = value;
        case Failure(:final error):
          final e = error as CliError;
          _writeErr(e.stderrMessage);
          return e.exitCode;
      }
    } else {
      body = _buildBodyFromFlags(functionalDependencies);
    }

    final result = await bffClient.put<Object?>(
      '/patients/$patientId/assessment/social-health-summary',
      body: body,
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

  Map<String, Object?> _buildBodyFromFlags(
    List<String> functionalDependencies,
  ) {
    final r = argResults!;
    final requiresConstantCare = _requireBool(r, 'requires-constant-care');
    final hasMobilityImpairment = _requireBool(r, 'has-mobility-impairment');
    final hasRelevantDrugTherapy = _requireBool(r, 'has-relevant-drug-therapy');
    return <String, Object?>{
      'requiresConstantCare': requiresConstantCare,
      'hasMobilityImpairment': hasMobilityImpairment,
      'hasRelevantDrugTherapy': hasRelevantDrugTherapy,
      'functionalDependencies': List<String>.unmodifiable(
        functionalDependencies,
      ),
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
