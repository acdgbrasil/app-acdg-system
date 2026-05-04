/// `acdg patient register` — register a patient (composite endpoint B1).
///
/// The Contract A `RegisterPatientRequest` is the "fat" composite — minimum
/// required fields are `personId`, `prRelationshipId`, plus at least one
/// initial diagnosis (`initialDiagnoses[].{icdCode, date, description}`).
/// Optional sub-objects: `personalData`, `civilDocuments`, `address`,
/// `socialIdentity`.
///
/// Two input modes (mutually exclusive):
///   * `--from-yaml=path/to/payload.yaml` — full composite from a YAML file.
///   * Flag set — `--person-id --pr-relationship-id --icd-code
///     --diagnosis-date --diagnosis-description` plus optional personal /
///     civil flags.
///
/// On success, surfaces the new id (`data.id`) on stdout.
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../session/bff_client.dart';
import '_command_helpers.dart';
import '_yaml_helpers.dart';

/// `acdg patient register`.
final class PatientRegisterCommand extends Command<int> {
  PatientRegisterCommand({
    required this.bffClient,
    required this.formatter,
    required this.fileReader,
    this.stdout,
    this.stderr,
  }) {
    argParser
      ..addOption('from-yaml', help: 'Path to a YAML payload (composite B1).')
      // Top-level required-when-not-using-yaml.
      ..addOption('person-id', help: 'Existing person id (required).')
      ..addOption(
        'pr-relationship-id',
        help: 'Primary responsible relationship id (required).',
      )
      // Initial diagnosis (one allowed via flags; --from-yaml supports many).
      ..addOption(
        'icd-code',
        help: 'Initial ICD code (required, one allowed via this flag).',
      )
      ..addOption(
        'diagnosis-date',
        help: 'Initial diagnosis date (YYYY-MM-DD).',
      )
      ..addOption(
        'diagnosis-description',
        help: 'Initial diagnosis description.',
      )
      // PersonalData (optional sub-object).
      ..addOption('first-name')
      ..addOption('last-name')
      ..addOption('mother-name')
      ..addOption('nationality')
      ..addOption('sex')
      ..addOption('birth-date')
      ..addOption('social-name')
      ..addOption('phone')
      // CivilDocuments (optional sub-object).
      ..addOption('cpf')
      ..addOption('cns')
      ..addOption('nis');
  }

  final BffClient bffClient;
  final OutputFormatter formatter;
  final Future<String> Function(String path) fileReader;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'register';

  @override
  String get description =>
      'Register a new patient (composite — flags or --from-yaml).';

  @override
  Future<int> run() async {
    final fromYaml = argResults?['from-yaml'] as String?;
    final hasFlagFields = _hasAnyFlagField();

    // --from-yaml + flag set together → contradictory.
    if (fromYaml != null && fromYaml.isNotEmpty && hasFlagFields) {
      usageException(
        '--from-yaml is mutually exclusive with field flags '
        '(--person-id, --pr-relationship-id, --icd-code, ...).',
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

    final result = await bffClient.post<Map<String, Object?>>(
      '/patients',
      body: body,
      decode: (data) => data is Map<String, Object?> ? data : const {},
    );
    switch (result) {
      case Success(:final value):
        final inner = value['data'];
        final id = inner is Map<String, Object?> ? inner['id'] : null;
        if (id is String && id.isNotEmpty) {
          _writeOut(formatter.format({'id': id}));
        } else {
          _writeOut(formatter.format(value));
        }
        return 0;
      case Failure(:final error):
        _writeErr(stderrMessageFor(error));
        return exitCodeFor(error);
    }
  }

  bool _hasAnyFlagField() {
    final r = argResults;
    if (r == null) return false;
    const flags = <String>[
      'person-id',
      'pr-relationship-id',
      'icd-code',
      'diagnosis-date',
      'diagnosis-description',
      'first-name',
      'last-name',
      'mother-name',
      'nationality',
      'sex',
      'birth-date',
      'social-name',
      'phone',
      'cpf',
      'cns',
      'nis',
    ];
    for (final f in flags) {
      final v = r[f] as String?;
      if (v != null && v.isNotEmpty) return true;
    }
    return false;
  }

  Map<String, Object?> _buildBodyFromFlags() {
    final r = argResults!;
    final personId = (r['person-id'] as String?) ?? '';
    final prRelationshipId = (r['pr-relationship-id'] as String?) ?? '';
    final icdCode = (r['icd-code'] as String?) ?? '';
    final diagnosisDate = (r['diagnosis-date'] as String?) ?? '';
    final diagnosisDescription = (r['diagnosis-description'] as String?) ?? '';

    if (personId.isEmpty ||
        prRelationshipId.isEmpty ||
        icdCode.isEmpty ||
        diagnosisDate.isEmpty ||
        diagnosisDescription.isEmpty) {
      usageException(
        'Missing required flags. Provide either --from-yaml=<path> or all of: '
        '--person-id, --pr-relationship-id, --icd-code, --diagnosis-date, '
        '--diagnosis-description.',
      );
    }

    final personal = dropNulls(<String, Object?>{
      'firstName': r['first-name'] as String?,
      'lastName': r['last-name'] as String?,
      'motherName': r['mother-name'] as String?,
      'nationality': r['nationality'] as String?,
      'sex': r['sex'] as String?,
      'birthDate': r['birth-date'] as String?,
      'socialName': r['social-name'] as String?,
      'phone': r['phone'] as String?,
    });

    final civil = dropNulls(<String, Object?>{
      'cpf': r['cpf'] as String?,
      'cns': r['cns'] as String?,
      'nis': r['nis'] as String?,
    });

    final body = <String, Object?>{
      'personId': personId,
      'prRelationshipId': prRelationshipId,
      'initialDiagnoses': [
        <String, Object?>{
          'icdCode': icdCode,
          'date': diagnosisDate,
          'description': diagnosisDescription,
        },
      ],
    };
    if (personal.isNotEmpty) body['personalData'] = personal;
    if (civil.isNotEmpty) body['civilDocuments'] = civil;
    return body;
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
