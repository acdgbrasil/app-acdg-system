/// W0 RED — `AssessmentSocialHealthSummaryCommand` orchestration contract
/// (C05). `acdg assessment social-health-summary <patient-id>`.
///
/// W1 must create
/// `apps/cli/lib/src/commands/assessment_social_health_summary_command.dart`:
///
/// ```dart
/// class AssessmentSocialHealthSummaryCommand extends Command<int> {
///   AssessmentSocialHealthSummaryCommand({
///     required this.bffClient,
///     required this.formatter,
///     required this.fileReader,
///     this.stdout,
///     this.stderr,
///   }) {
///     argParser
///       ..addOption('from-yaml', help: 'Path to a YAML payload override.')
///       ..addOption('requires-constant-care', help: 'true|false (required)')
///       ..addOption('has-mobility-impairment', help: 'true|false (required)')
///       ..addOption('has-relevant-drug-therapy', help: 'true|false (required)')
///       ..addMultiOption('functional-dependency',
///           help: 'Functional dependency code (repeatable, optional)');
///   }
///   @override String get name => 'social-health-summary';
///   @override Future<int> run();
/// }
/// ```
///
/// Wire mapping (verified against
/// `apps/social_care_bff/web/lib/src/intents/update_social_health_summary_intent.dart:43`
/// — the intent calls `UpdateSocialHealthSummaryRequest.fromJson(body)` so
/// the body shape == `UpdateSocialHealthSummaryRequest.toJson()` per
/// `apps/social_care_bff/contracts/lib/src/contract/dto/requests/assessment/update_social_health_summary_request.dart`):
///
/// ```json
/// {
///   "requiresConstantCare":   <bool, required>,
///   "hasMobilityImpairment":  <bool, required>,
///   "hasRelevantDrugTherapy": <bool, required>,
///   "functionalDependencies": <[String], default []>
/// }
/// ```
library;

import 'package:test/test.dart';

import 'package:cli/src/commands/assessment_social_health_summary_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/session/bff_client.dart';

import '_assessment_test_helpers.dart';

const String _kPatientId = kAssessmentPatientId;

void main() {
  // Cross-cutting contract every assessment verb shares.
  runAssessmentCommandContract(
    verbName: 'social-health-summary',
    pathSuffix: 'social-health-summary',
    build:
        ({
          required BffClient bffClient,
          required Future<String> Function(String path) fileReader,
          StringSink? stdout,
          StringSink? stderr,
        }) => AssessmentSocialHealthSummaryCommand(
          bffClient: bffClient,
          formatter: const JsonFormatter(),
          fileReader: fileReader,
          stdout: stdout,
          stderr: stderr,
        ),
    minimalArgs: () => const [
      '--requires-constant-care=true',
      '--has-mobility-impairment=false',
      '--has-relevant-drug-therapy=true',
    ],
    yamlBody: '''
requiresConstantCare: true
hasMobilityImpairment: false
hasRelevantDrugTherapy: true
functionalDependencies:
  - bathing
  - dressing
''',
  );

  // Ficha-specific body-shape assertions.
  group('AssessmentSocialHealthSummaryCommand — body shape', () {
    test('PUT body matches UpdateSocialHealthSummaryRequest.toJson() shape '
        '(camelCase keys, list default empty, bool scalars)', () async {
      final adapter = CapturingAdapter('', status: 204);
      final cmd = AssessmentSocialHealthSummaryCommand(
        bffClient: buildBff(adapter),
        formatter: const JsonFormatter(),
        fileReader: failingReader,
        stdout: StringBuffer(),
      );

      final exit = await runWithArgs(cmd, const [
        _kPatientId,
        '--requires-constant-care=true',
        '--has-mobility-impairment=false',
        '--has-relevant-drug-therapy=true',
        '--functional-dependency=bathing',
        '--functional-dependency=dressing',
      ]);

      expect(exit, equals(0));
      final body = decodeBody(adapter.lastOptions!.data);
      expect(body['requiresConstantCare'], equals(true));
      expect(body['hasMobilityImpairment'], equals(false));
      expect(body['hasRelevantDrugTherapy'], equals(true));
      expect(
        body['functionalDependencies'],
        equals(<String>['bathing', 'dressing']),
      );
    });

    test('when --functional-dependency omitted, body sends empty list '
        '(DTO default `const []`)', () async {
      final adapter = CapturingAdapter('', status: 204);
      final cmd = AssessmentSocialHealthSummaryCommand(
        bffClient: buildBff(adapter),
        formatter: const JsonFormatter(),
        fileReader: failingReader,
      );

      final exit = await runWithArgs(cmd, const [
        _kPatientId,
        '--requires-constant-care=true',
        '--has-mobility-impairment=false',
        '--has-relevant-drug-therapy=true',
      ]);

      expect(exit, equals(0));
      final body = decodeBody(adapter.lastOptions!.data);
      expect(body['functionalDependencies'], equals(<String>[]));
    });

    test(
      'missing --requires-constant-care → usage error, no BFF call',
      () async {
        final adapter = CapturingAdapter('', status: 204);
        final cmd = AssessmentSocialHealthSummaryCommand(
          bffClient: buildBff(adapter),
          formatter: const JsonFormatter(),
          fileReader: failingReader,
          stderr: StringBuffer(),
        );

        final exit = await runWithArgs(cmd, const [
          _kPatientId,
          '--has-mobility-impairment=false',
          '--has-relevant-drug-therapy=true',
        ]);

        expect(exit, isNot(equals(0)));
        expect(adapter.lastOptions, isNull);
      },
    );
  });
}
