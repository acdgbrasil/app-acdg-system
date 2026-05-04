/// W0 RED — `AssessmentWorkIncomeCommand` orchestration contract (C05).
/// `acdg assessment work-income <patient-id>`.
///
/// W1 must create
/// `apps/cli/lib/src/commands/assessment_work_income_command.dart`:
///
/// ```dart
/// class AssessmentWorkIncomeCommand extends Command<int> {
///   AssessmentWorkIncomeCommand({
///     required this.bffClient,
///     required this.formatter,
///     required this.fileReader,
///     this.stdout,
///     this.stderr,
///   }) {
///     argParser
///       ..addOption('from-yaml', help: 'Path to a YAML payload override.')
///       ..addOption('has-retired-members'); // bool, required
///       // individualIncomes[] and socialBenefits[] are nested DTO lists;
///       // only --from-yaml populates them (no flag-based form expressive
///       // enough for nested structures).
///   }
///   @override String get name => 'work-income';
///   @override Future<int> run();
/// }
/// ```
///
/// Wire mapping (verified against
/// `apps/social_care_bff/web/lib/src/intents/update_work_and_income_intent.dart:43`
/// — calls `UpdateWorkAndIncomeRequest.fromJson(body)` so the body shape ==
/// `UpdateWorkAndIncomeRequest.toJson()` per
/// `apps/social_care_bff/contracts/lib/src/contract/dto/requests/assessment/update_work_and_income_request.dart`):
///
/// ```json
/// {
///   "individualIncomes":  <[IncomeDraftDto], default []>,
///   "socialBenefits":     <[SocialBenefitDraftDto], default []>,
///   "hasRetiredMembers":  <bool, required>
/// }
/// ```
///
/// `IncomeDraftDto`: `{memberId, occupationId, hasWorkCard, monthlyAmount}`.
/// `SocialBenefitDraftDto`: shared with `socioeconomic` —
/// `{benefitName, amount, beneficiaryId, benefitTypeId?, birthCertificateNumber?, deceasedCpf?}`.
library;

import 'package:test/test.dart';

import 'package:cli/src/commands/assessment_work_income_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/session/bff_client.dart';

import '_assessment_test_helpers.dart';

const String _kPatientId = kAssessmentPatientId;

const List<String> _kMinimalArgs = ['--has-retired-members=false'];

void main() {
  runAssessmentCommandContract(
    verbName: 'work-income',
    pathSuffix: 'work-income',
    build:
        ({
          required BffClient bffClient,
          required Future<String> Function(String path) fileReader,
          StringSink? stdout,
          StringSink? stderr,
        }) => AssessmentWorkIncomeCommand(
          bffClient: bffClient,
          formatter: const JsonFormatter(),
          fileReader: fileReader,
          stdout: stdout,
          stderr: stderr,
        ),
    minimalArgs: () => _kMinimalArgs,
    yamlBody: '''
individualIncomes: []
socialBenefits: []
hasRetiredMembers: false
''',
  );

  group('AssessmentWorkIncomeCommand — body shape', () {
    test(
      'PUT body matches UpdateWorkAndIncomeRequest.toJson() shape '
      '(camelCase; lists default empty; hasRetiredMembers as bool)',
      () async {
        final adapter = CapturingAdapter('', status: 204);
        final cmd = AssessmentWorkIncomeCommand(
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
        expect(body['hasRetiredMembers'], equals(false));
        expect(body['individualIncomes'], equals(<Object?>[]));
        expect(body['socialBenefits'], equals(<Object?>[]));
      },
    );

    test(
      '--from-yaml supports nested individualIncomes + socialBenefits lists',
      () async {
        const yaml = '''
individualIncomes:
  - memberId: "22222222-2222-4222-8222-222222222222"
    occupationId: "33333333-3333-4333-8333-333333333333"
    hasWorkCard: true
    monthlyAmount: 1800.0
socialBenefits:
  - benefitName: "BPC"
    amount: 1320.0
    beneficiaryId: "44444444-4444-4444-8444-444444444444"
hasRetiredMembers: true
''';
        Future<String> reader(String _) async => yaml;
        final adapter = CapturingAdapter('', status: 204);
        final cmd = AssessmentWorkIncomeCommand(
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
        expect(body['hasRetiredMembers'], equals(true));
        final incomes = body['individualIncomes']! as List<Object?>;
        expect(incomes, hasLength(1));
        final i0 = incomes.first! as Map<String, Object?>;
        expect(i0['hasWorkCard'], equals(true));
        expect((i0['monthlyAmount']! as num).toDouble(), equals(1800.0));
        final benefits = body['socialBenefits']! as List<Object?>;
        expect(benefits, hasLength(1));
        final b0 = benefits.first! as Map<String, Object?>;
        expect(b0['benefitName'], equals('BPC'));
      },
    );

    test('missing --has-retired-members → usage error, no BFF call', () async {
      final adapter = CapturingAdapter('', status: 204);
      final cmd = AssessmentWorkIncomeCommand(
        bffClient: buildBff(adapter),
        formatter: const JsonFormatter(),
        fileReader: failingReader,
        stderr: StringBuffer(),
      );

      // No flags at all → only the positional present.
      final exit = await runWithArgs(cmd, const [_kPatientId]);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });
  });
}
