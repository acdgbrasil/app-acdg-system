/// `acdg assessment housing <patient-id>` — update the housing-condition
/// ficha (C05).
///
/// PUTs `/patients/{id}/assessment/housing` with the
/// [UpdateHousingConditionRequest] body shape (15 required fields, all
/// scalars):
///   * 6 strings (`type`, `wallMaterial`, `waterSupply`, `electricityAccess`,
///     `sewageDisposal`, `wasteCollection`, `accessibilityLevel`),
///   * 3 ints (`numberOfRooms`, `numberOfBedrooms`, `numberOfBathrooms`),
///   * 5 bools (`hasPipedWater`, `isInGeographicRiskArea`,
///     `hasDifficultAccess`, `isInSocialConflictArea`,
///     `hasDiagnosticObservations`).
///
/// Two input modes (mutually exclusive):
///   * `--from-yaml=<path>` — full payload from a YAML file.
///   * Field flags — every required scalar passed via `--<kebab>=value`. Bool
///     flags accept `true|false` (manual parse; uniform with C03/C04 family).
library;

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../session/bff_client.dart';
import '_command_helpers.dart';
import '_yaml_helpers.dart';

/// `acdg assessment housing`.
final class AssessmentHousingCommand extends Command<int> {
  AssessmentHousingCommand({
    required this.bffClient,
    required this.formatter,
    required this.fileReader,
    this.stdout,
    this.stderr,
  }) {
    argParser
      ..addOption('from-yaml', help: 'Path to a YAML payload override.')
      // 11 required strings + ints.
      ..addOption('type', help: 'Housing type code (required).')
      ..addOption('wall-material', help: 'Wall material code (required).')
      ..addOption('number-of-rooms', help: 'Total rooms (int, required).')
      ..addOption('number-of-bedrooms', help: 'Bedrooms (int, required).')
      ..addOption('number-of-bathrooms', help: 'Bathrooms (int, required).')
      ..addOption('water-supply', help: 'Water-supply code (required).')
      ..addOption(
        'electricity-access',
        help: 'Electricity-access code (required).',
      )
      ..addOption('sewage-disposal', help: 'Sewage-disposal code (required).')
      ..addOption('waste-collection', help: 'Waste-collection code (required).')
      ..addOption(
        'accessibility-level',
        help: 'Accessibility level code (required).',
      )
      // 5 required bools (passed as `true|false` strings via --opt=).
      ..addOption('has-piped-water', help: 'true|false (required).')
      ..addOption('is-in-geographic-risk-area', help: 'true|false (required).')
      ..addOption('has-difficult-access', help: 'true|false (required).')
      ..addOption('is-in-social-conflict-area', help: 'true|false (required).')
      ..addOption(
        'has-diagnostic-observations',
        help: 'true|false (required).',
      );
  }

  final BffClient bffClient;
  final OutputFormatter formatter;
  final Future<String> Function(String path) fileReader;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'housing';

  @override
  String get description =>
      'Update the housing-condition ficha (15 required fields).';

  @override
  String get invocation =>
      'acdg assessment housing <patient-id> [--from-yaml=<path> | --type=... '
      '--wall-material=... --number-of-rooms=N --number-of-bedrooms=N '
      '--number-of-bathrooms=N --water-supply=... --has-piped-water=true|false '
      '--electricity-access=... --sewage-disposal=... --waste-collection=... '
      '--accessibility-level=... --is-in-geographic-risk-area=true|false '
      '--has-difficult-access=true|false --is-in-social-conflict-area=true|false '
      '--has-diagnostic-observations=true|false]';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      usageException('Missing required positional argument: <patient-id>');
    }
    final patientId = rest.first;

    final fromYaml = argResults?['from-yaml'] as String?;
    final flagFields = const <String>[
      'type',
      'wall-material',
      'number-of-rooms',
      'number-of-bedrooms',
      'number-of-bathrooms',
      'water-supply',
      'has-piped-water',
      'electricity-access',
      'sewage-disposal',
      'waste-collection',
      'accessibility-level',
      'is-in-geographic-risk-area',
      'has-difficult-access',
      'is-in-social-conflict-area',
      'has-diagnostic-observations',
    ];
    final hasAnyFlag = flagFields.any(
      (f) => (argResults?[f] as String?)?.isNotEmpty ?? false,
    );

    if (fromYaml != null && fromYaml.isNotEmpty && hasAnyFlag) {
      usageException(
        '--from-yaml is mutually exclusive with field flags '
        '(--type, --wall-material, ...).',
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
      '/patients/$patientId/assessment/housing',
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
    final type = _requireString(r, 'type');
    final wallMaterial = _requireString(r, 'wall-material');
    final numberOfRooms = _requireInt(r, 'number-of-rooms');
    final numberOfBedrooms = _requireInt(r, 'number-of-bedrooms');
    final numberOfBathrooms = _requireInt(r, 'number-of-bathrooms');
    final waterSupply = _requireString(r, 'water-supply');
    final hasPipedWater = _requireBool(r, 'has-piped-water');
    final electricityAccess = _requireString(r, 'electricity-access');
    final sewageDisposal = _requireString(r, 'sewage-disposal');
    final wasteCollection = _requireString(r, 'waste-collection');
    final accessibilityLevel = _requireString(r, 'accessibility-level');
    final isInGeographicRiskArea = _requireBool(
      r,
      'is-in-geographic-risk-area',
    );
    final hasDifficultAccess = _requireBool(r, 'has-difficult-access');
    final isInSocialConflictArea = _requireBool(
      r,
      'is-in-social-conflict-area',
    );
    final hasDiagnosticObservations = _requireBool(
      r,
      'has-diagnostic-observations',
    );

    return <String, Object?>{
      'type': type,
      'wallMaterial': wallMaterial,
      'numberOfRooms': numberOfRooms,
      'numberOfBedrooms': numberOfBedrooms,
      'numberOfBathrooms': numberOfBathrooms,
      'waterSupply': waterSupply,
      'hasPipedWater': hasPipedWater,
      'electricityAccess': electricityAccess,
      'sewageDisposal': sewageDisposal,
      'wasteCollection': wasteCollection,
      'accessibilityLevel': accessibilityLevel,
      'isInGeographicRiskArea': isInGeographicRiskArea,
      'hasDifficultAccess': hasDifficultAccess,
      'isInSocialConflictArea': isInSocialConflictArea,
      'hasDiagnosticObservations': hasDiagnosticObservations,
    };
  }

  String _requireString(ArgResults r, String name) {
    final value = r[name] as String?;
    if (value == null || value.isEmpty) {
      usageException('Missing required option: --$name');
    }
    return value;
  }

  int _requireInt(ArgResults r, String name) {
    final raw = _requireString(r, name);
    final parsed = int.tryParse(raw);
    if (parsed == null) {
      usageException('--$name must be an integer (got "$raw").');
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
