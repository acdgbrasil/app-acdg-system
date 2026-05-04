/// `acdg assessment socioeconomic <patient-id>` — update the socio-economic
/// situation ficha (C05).
///
/// PUTs `/patients/{id}/assessment/socioeconomic` with the
/// [UpdateSocioEconomicSituationRequest] body shape:
///   * 5 required scalars (`totalFamilyIncome` double, `incomePerCapita`
///     double, `receivesSocialBenefit` bool, `mainSourceOfIncome` String,
///     `hasUnemployed` bool),
///   * `socialBenefits` — list of nested `SocialBenefitDraftDto`, defaults to
///     empty. Only `--from-yaml` populates non-empty values (no flag-based
///     form expressive enough for the nested DTO).
library;

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../session/bff_client.dart';
import '_command_helpers.dart';
import '_yaml_helpers.dart';

/// `acdg assessment socioeconomic`.
final class AssessmentSocioeconomicCommand extends Command<int> {
  AssessmentSocioeconomicCommand({
    required this.bffClient,
    required this.formatter,
    required this.fileReader,
    this.stdout,
    this.stderr,
  }) {
    argParser
      ..addOption('from-yaml', help: 'Path to a YAML payload override.')
      ..addOption(
        'total-family-income',
        help: 'Monthly family income in BRL (double, required).',
      )
      ..addOption(
        'income-per-capita',
        help: 'Per-capita monthly income in BRL (double, required).',
      )
      ..addOption(
        'receives-social-benefit',
        help:
            'true|false — does the family receive any social benefit '
            '(required).',
      )
      ..addOption(
        'main-source-of-income',
        help: 'Main source of income code (required).',
      )
      ..addOption(
        'has-unemployed',
        help: 'true|false — at least one unemployed adult (required).',
      );
  }

  final BffClient bffClient;
  final OutputFormatter formatter;
  final Future<String> Function(String path) fileReader;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'socioeconomic';

  @override
  String get description =>
      'Update the socio-economic situation ficha (5 required scalars + '
      'optional socialBenefits[] via --from-yaml).';

  @override
  String get invocation =>
      'acdg assessment socioeconomic <patient-id> [--from-yaml=<path> | '
      '--total-family-income=N --income-per-capita=N '
      '--receives-social-benefit=true|false --main-source-of-income=... '
      '--has-unemployed=true|false]';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      usageException('Missing required positional argument: <patient-id>');
    }
    final patientId = rest.first;

    final fromYaml = argResults?['from-yaml'] as String?;
    const flagFields = <String>[
      'total-family-income',
      'income-per-capita',
      'receives-social-benefit',
      'main-source-of-income',
      'has-unemployed',
    ];
    final hasAnyFlag = flagFields.any(
      (f) => (argResults?[f] as String?)?.isNotEmpty ?? false,
    );

    if (fromYaml != null && fromYaml.isNotEmpty && hasAnyFlag) {
      usageException(
        '--from-yaml is mutually exclusive with field flags '
        '(--total-family-income, --income-per-capita, ...).',
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
      '/patients/$patientId/assessment/socioeconomic',
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
    final totalFamilyIncome = _requireDouble(r, 'total-family-income');
    final incomePerCapita = _requireDouble(r, 'income-per-capita');
    final receivesSocialBenefit = _requireBool(r, 'receives-social-benefit');
    final mainSourceOfIncome = _requireString(r, 'main-source-of-income');
    final hasUnemployed = _requireBool(r, 'has-unemployed');
    return <String, Object?>{
      'totalFamilyIncome': totalFamilyIncome,
      'incomePerCapita': incomePerCapita,
      'receivesSocialBenefit': receivesSocialBenefit,
      'socialBenefits': <Object?>[],
      'mainSourceOfIncome': mainSourceOfIncome,
      'hasUnemployed': hasUnemployed,
    };
  }

  String _requireString(ArgResults r, String name) {
    final value = r[name] as String?;
    if (value == null || value.isEmpty) {
      usageException('Missing required option: --$name');
    }
    return value;
  }

  double _requireDouble(ArgResults r, String name) {
    final raw = _requireString(r, name);
    final parsed = double.tryParse(raw);
    if (parsed == null) {
      usageException('--$name must be a number (got "$raw").');
    }
    return parsed;
  }

  bool _requireBool(ArgResults r, String name) {
    final raw = _requireString(r, name);
    final lower = raw.toLowerCase();
    if (lower == 'true') return true;
    if (lower == 'false') return false;
    usageException('--$name must be true|false (got "$raw").');
  }

  void _writeErr(String line) {
    final err = stderr ?? stdout;
    if (err != null) err.writeln(line);
  }
}
