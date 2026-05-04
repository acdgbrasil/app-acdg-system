/// W0 RED — `AssessmentSocioeconomicCommand` orchestration contract (C05).
/// `acdg assessment socioeconomic <patient-id>`.
///
/// W1 must create
/// `apps/cli/lib/src/commands/assessment_socioeconomic_command.dart`:
///
/// ```dart
/// class AssessmentSocioeconomicCommand extends Command<int> {
///   AssessmentSocioeconomicCommand({
///     required this.bffClient,
///     required this.formatter,
///     required this.fileReader,
///     this.stdout,
///     this.stderr,
///   }) {
///     argParser
///       ..addOption('from-yaml', help: 'Path to a YAML payload override.')
///       ..addOption('total-family-income')      // double, required
///       ..addOption('income-per-capita')        // double, required
///       ..addOption('receives-social-benefit')  // bool,   required
///       ..addOption('main-source-of-income')    // String, required
///       ..addOption('has-unemployed');          // bool,   required
///       // Note: socialBenefits[] is a structured list; only --from-yaml
///       // populates it (no flag-based form expressive enough for nested
///       // SocialBenefitDraftDto).
///   }
///   @override String get name => 'socioeconomic';
///   @override Future<int> run();
/// }
/// ```
///
/// Wire mapping (verified against
/// `apps/social_care_bff/web/lib/src/intents/update_socio_economic_situation_intent.dart:43`
/// — calls `UpdateSocioEconomicSituationRequest.fromJson(body)` so the body
/// shape == `UpdateSocioEconomicSituationRequest.toJson()` per
/// `apps/social_care_bff/contracts/lib/src/contract/dto/requests/assessment/update_socio_economic_situation_request.dart`):
///
/// ```json
/// {
///   "totalFamilyIncome":     <double, required>,
///   "incomePerCapita":       <double, required>,
///   "receivesSocialBenefit": <bool,   required>,
///   "socialBenefits":        <[SocialBenefitDraftDto], default []>,
///   "mainSourceOfIncome":    <String, required>,
///   "hasUnemployed":         <bool,   required>
/// }
/// ```
///
/// `SocialBenefitDraftDto` shape (nested):
/// `{benefitName, amount, beneficiaryId, benefitTypeId?, birthCertificateNumber?, deceasedCpf?}`.
library;

import 'package:test/test.dart';

import 'package:cli/src/commands/assessment_socioeconomic_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/session/bff_client.dart';

import '_assessment_test_helpers.dart';

const String _kPatientId = kAssessmentPatientId;

const List<String> _kMinimalArgs = [
  '--total-family-income=2500.00',
  '--income-per-capita=625.00',
  '--receives-social-benefit=false',
  '--main-source-of-income=formal_employment',
  '--has-unemployed=false',
];

void main() {
  runAssessmentCommandContract(
    verbName: 'socioeconomic',
    pathSuffix: 'socioeconomic',
    build:
        ({
          required BffClient bffClient,
          required Future<String> Function(String path) fileReader,
          StringSink? stdout,
          StringSink? stderr,
        }) => AssessmentSocioeconomicCommand(
          bffClient: bffClient,
          formatter: const JsonFormatter(),
          fileReader: fileReader,
          stdout: stdout,
          stderr: stderr,
        ),
    minimalArgs: () => _kMinimalArgs,
    yamlBody: '''
totalFamilyIncome: 2500.0
incomePerCapita: 625.0
receivesSocialBenefit: false
socialBenefits: []
mainSourceOfIncome: formal_employment
hasUnemployed: false
''',
  );

  group('AssessmentSocioeconomicCommand — body shape', () {
    test('PUT body matches UpdateSocioEconomicSituationRequest.toJson() shape '
        '(camelCase, doubles parsed as num, list default empty)', () async {
      final adapter = CapturingAdapter('', status: 204);
      final cmd = AssessmentSocioeconomicCommand(
        bffClient: buildBff(adapter),
        formatter: const JsonFormatter(),
        fileReader: failingReader,
        stdout: StringBuffer(),
      );

      final exit = await runWithArgs(cmd, const [
        _kPatientId,
        ..._kMinimalArgs,
      ]);

      expect(exit, equals(0));
      final body = decodeBody(adapter.lastOptions!.data);
      // Doubles MUST go on the wire as JSON numbers, not strings.
      expect(body['totalFamilyIncome'], isA<num>());
      expect((body['totalFamilyIncome']! as num).toDouble(), equals(2500.0));
      expect((body['incomePerCapita']! as num).toDouble(), equals(625.0));
      expect(body['receivesSocialBenefit'], equals(false));
      expect(body['mainSourceOfIncome'], equals('formal_employment'));
      expect(body['hasUnemployed'], equals(false));
      // Default empty list when no benefits flag set.
      expect(body['socialBenefits'], equals(<Object?>[]));
    });

    test('--from-yaml supports nested socialBenefits list', () async {
      const yaml = '''
totalFamilyIncome: 1500.0
incomePerCapita: 375.0
receivesSocialBenefit: true
socialBenefits:
  - benefitName: "Bolsa Família"
    amount: 600.0
    beneficiaryId: "11111111-1111-4111-8111-111111111111"
mainSourceOfIncome: social_benefit
hasUnemployed: true
''';
      Future<String> reader(String _) async => yaml;
      final adapter = CapturingAdapter('', status: 204);
      final cmd = AssessmentSocioeconomicCommand(
        bffClient: buildBff(adapter),
        formatter: const JsonFormatter(),
        fileReader: reader,
      );

      final exit = await runWithArgs(cmd, const [
        _kPatientId,
        '--from-yaml=/tmp/payload.yaml',
      ]);

      expect(exit, equals(0));
      final body = decodeBody(adapter.lastOptions!.data);
      expect(body['receivesSocialBenefit'], equals(true));
      expect(body['socialBenefits'], isA<List<Object?>>());
      final benefits = body['socialBenefits']! as List<Object?>;
      expect(benefits, hasLength(1));
      final b0 = benefits.first! as Map<String, Object?>;
      expect(b0['benefitName'], equals('Bolsa Família'));
      expect((b0['amount']! as num).toDouble(), equals(600.0));
    });

    test(
      'non-numeric --total-family-income → usage error, no BFF call',
      () async {
        final adapter = CapturingAdapter('', status: 204);
        final cmd = AssessmentSocioeconomicCommand(
          bffClient: buildBff(adapter),
          formatter: const JsonFormatter(),
          fileReader: failingReader,
          stderr: StringBuffer(),
        );

        final args = _kMinimalArgs
            .map(
              (a) => a.startsWith('--total-family-income=')
                  ? '--total-family-income=NaN'
                  : a,
            )
            .toList();
        final exit = await runWithArgs(cmd, [_kPatientId, ...args]);

        expect(exit, isNot(equals(0)));
        expect(adapter.lastOptions, isNull);
      },
    );

    test(
      'missing --main-source-of-income → usage error, no BFF call',
      () async {
        final adapter = CapturingAdapter('', status: 204);
        final cmd = AssessmentSocioeconomicCommand(
          bffClient: buildBff(adapter),
          formatter: const JsonFormatter(),
          fileReader: failingReader,
          stderr: StringBuffer(),
        );

        final args = _kMinimalArgs
            .where((a) => !a.startsWith('--main-source-of-income='))
            .toList();
        final exit = await runWithArgs(cmd, [_kPatientId, ...args]);

        expect(exit, isNot(equals(0)));
        expect(adapter.lastOptions, isNull);
      },
    );
  });
}
