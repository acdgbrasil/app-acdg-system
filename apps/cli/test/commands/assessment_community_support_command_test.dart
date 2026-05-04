/// W0 RED — `AssessmentCommunitySupportCommand` orchestration contract
/// (C05). `acdg assessment community-support <patient-id>`.
///
/// W1 must create
/// `apps/cli/lib/src/commands/assessment_community_support_command.dart`:
///
/// ```dart
/// class AssessmentCommunitySupportCommand extends Command<int> {
///   AssessmentCommunitySupportCommand({
///     required this.bffClient,
///     required this.formatter,
///     required this.fileReader,
///     this.stdout,
///     this.stderr,
///   }) {
///     argParser
///       ..addOption('from-yaml', help: 'Path to a YAML payload override.')
///       ..addOption('has-relative-support')           // bool, required
///       ..addOption('has-neighbor-support')           // bool, required
///       ..addOption('family-conflicts')               // String, required
///       ..addOption('patient-participates-in-groups') // bool, required
///       ..addOption('family-participates-in-groups')  // bool, required
///       ..addOption('patient-has-access-to-leisure')  // bool, required
///       ..addOption('faces-discrimination');          // bool, required
///   }
///   @override String get name => 'community-support';
///   @override Future<int> run();
/// }
/// ```
///
/// Wire mapping (verified against
/// `apps/social_care_bff/web/lib/src/intents/update_community_support_network_intent.dart:43`
/// — the intent calls `UpdateCommunitySupportNetworkRequest.fromJson(body)`
/// so the body shape == `UpdateCommunitySupportNetworkRequest.toJson()` per
/// `apps/social_care_bff/contracts/lib/src/contract/dto/requests/assessment/update_community_support_network_request.dart`):
///
/// ```json
/// {
///   "hasRelativeSupport":          <bool, required>,
///   "hasNeighborSupport":          <bool, required>,
///   "familyConflicts":             <String, required>,
///   "patientParticipatesInGroups": <bool, required>,
///   "familyParticipatesInGroups":  <bool, required>,
///   "patientHasAccessToLeisure":   <bool, required>,
///   "facesDiscrimination":         <bool, required>
/// }
/// ```
library;

import 'package:test/test.dart';

import 'package:cli/src/commands/assessment_community_support_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/session/bff_client.dart';

import '_assessment_test_helpers.dart';

const String _kPatientId = kAssessmentPatientId;

const List<String> _kMinimalArgs = [
  '--has-relative-support=true',
  '--has-neighbor-support=false',
  '--family-conflicts=none',
  '--patient-participates-in-groups=true',
  '--family-participates-in-groups=false',
  '--patient-has-access-to-leisure=true',
  '--faces-discrimination=false',
];

void main() {
  runAssessmentCommandContract(
    verbName: 'community-support',
    pathSuffix: 'community-support',
    build:
        ({
          required BffClient bffClient,
          required Future<String> Function(String path) fileReader,
          StringSink? stdout,
          StringSink? stderr,
        }) => AssessmentCommunitySupportCommand(
          bffClient: bffClient,
          formatter: const JsonFormatter(),
          fileReader: fileReader,
          stdout: stdout,
          stderr: stderr,
        ),
    minimalArgs: () => _kMinimalArgs,
    yamlBody: '''
hasRelativeSupport: true
hasNeighborSupport: false
familyConflicts: "none"
patientParticipatesInGroups: true
familyParticipatesInGroups: false
patientHasAccessToLeisure: true
facesDiscrimination: false
''',
  );

  group('AssessmentCommunitySupportCommand — body shape', () {
    test(
      'PUT body matches UpdateCommunitySupportNetworkRequest.toJson() shape '
      '(7 camelCase keys; bools as bools, familyConflicts as String)',
      () async {
        final adapter = CapturingAdapter('', status: 204);
        final cmd = AssessmentCommunitySupportCommand(
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
        expect(body['hasRelativeSupport'], equals(true));
        expect(body['hasNeighborSupport'], equals(false));
        expect(body['familyConflicts'], equals('none'));
        expect(body['patientParticipatesInGroups'], equals(true));
        expect(body['familyParticipatesInGroups'], equals(false));
        expect(body['patientHasAccessToLeisure'], equals(true));
        expect(body['facesDiscrimination'], equals(false));
      },
    );

    test('missing --family-conflicts → usage error, no BFF call', () async {
      final adapter = CapturingAdapter('', status: 204);
      final cmd = AssessmentCommunitySupportCommand(
        bffClient: buildBff(adapter),
        formatter: const JsonFormatter(),
        fileReader: failingReader,
        stderr: StringBuffer(),
      );

      final args = _kMinimalArgs
          .where((a) => !a.startsWith('--family-conflicts='))
          .toList();
      final exit = await runWithArgs(cmd, [_kPatientId, ...args]);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });
  });
}
