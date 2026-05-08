/// `acdg assessment community-support <patient-id>` — update the community-
/// support-network ficha (C05).
///
/// PUTs `/patients/{id}/assessment/community-support` with the
/// [UpdateCommunitySupportNetworkRequest] body shape: 7 required scalars.
///
///   * 6 bools — `hasRelativeSupport`, `hasNeighborSupport`,
///     `patientParticipatesInGroups`, `familyParticipatesInGroups`,
///     `patientHasAccessToLeisure`, `facesDiscrimination`.
///   * 1 String — `familyConflicts` (NOT a bool — server-side validates the
///     code; common mistake from prose alone).
library;

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../errors/cli_error.dart';
import '../session/bff_client.dart';
import '_yaml_helpers.dart';

/// `acdg assessment community-support`.
final class AssessmentCommunitySupportCommand extends Command<int> {
  AssessmentCommunitySupportCommand({
    required this.bffClient,
    required this.formatter,
    required this.fileReader,
    this.stdout,
    this.stderr,
  }) {
    argParser
      ..addOption('from-yaml', help: 'Path to a YAML payload override.')
      ..addOption(
        'has-relative-support',
        help: 'true|false — relatives provide support (required).',
      )
      ..addOption(
        'has-neighbor-support',
        help: 'true|false — neighbors provide support (required).',
      )
      ..addOption(
        'family-conflicts',
        help: 'Family-conflicts level code (String, NOT bool — required).',
      )
      ..addOption(
        'patient-participates-in-groups',
        help: 'true|false — patient is in community groups (required).',
      )
      ..addOption(
        'family-participates-in-groups',
        help: 'true|false — family is in community groups (required).',
      )
      ..addOption(
        'patient-has-access-to-leisure',
        help: 'true|false — patient has access to leisure (required).',
      )
      ..addOption(
        'faces-discrimination',
        help: 'true|false — household faces discrimination (required).',
      );
  }

  final BffClient bffClient;
  final OutputFormatter formatter;
  final Future<String> Function(String path) fileReader;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'community-support';

  @override
  String get description =>
      'Update the community-support-network ficha (7 required scalars: 6 '
      'bools + familyConflicts as String).';

  @override
  String get invocation =>
      'acdg assessment community-support <patient-id> [--from-yaml=<path> | '
      '--has-relative-support=true|false --has-neighbor-support=true|false '
      '--family-conflicts=<code> --patient-participates-in-groups=true|false '
      '--family-participates-in-groups=true|false '
      '--patient-has-access-to-leisure=true|false '
      '--faces-discrimination=true|false]';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      usageException('Missing required positional argument: <patient-id>');
    }
    final patientId = rest.first;

    final fromYaml = argResults?['from-yaml'] as String?;
    const flagFields = <String>[
      'has-relative-support',
      'has-neighbor-support',
      'family-conflicts',
      'patient-participates-in-groups',
      'family-participates-in-groups',
      'patient-has-access-to-leisure',
      'faces-discrimination',
    ];
    final hasAnyFlag = flagFields.any(
      (f) => (argResults?[f] as String?)?.isNotEmpty ?? false,
    );

    if (fromYaml != null && fromYaml.isNotEmpty && hasAnyFlag) {
      usageException(
        '--from-yaml is mutually exclusive with field flags '
        '(--has-relative-support, --family-conflicts, ...).',
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
      body = _buildBodyFromFlags();
    }

    final result = await bffClient.put<Object?>(
      '/patients/$patientId/assessment/community-support',
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

  Map<String, Object?> _buildBodyFromFlags() {
    final r = argResults!;
    final hasRelativeSupport = _requireBool(r, 'has-relative-support');
    final hasNeighborSupport = _requireBool(r, 'has-neighbor-support');
    final familyConflicts = _requireString(r, 'family-conflicts');
    final patientParticipatesInGroups = _requireBool(
      r,
      'patient-participates-in-groups',
    );
    final familyParticipatesInGroups = _requireBool(
      r,
      'family-participates-in-groups',
    );
    final patientHasAccessToLeisure = _requireBool(
      r,
      'patient-has-access-to-leisure',
    );
    final facesDiscrimination = _requireBool(r, 'faces-discrimination');

    return <String, Object?>{
      'hasRelativeSupport': hasRelativeSupport,
      'hasNeighborSupport': hasNeighborSupport,
      'familyConflicts': familyConflicts,
      'patientParticipatesInGroups': patientParticipatesInGroups,
      'familyParticipatesInGroups': familyParticipatesInGroups,
      'patientHasAccessToLeisure': patientHasAccessToLeisure,
      'facesDiscrimination': facesDiscrimination,
    };
  }

  String _requireString(ArgResults r, String name) {
    final value = r[name] as String?;
    if (value == null || value.isEmpty) {
      usageException('Missing required option: --$name');
    }
    return value;
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
