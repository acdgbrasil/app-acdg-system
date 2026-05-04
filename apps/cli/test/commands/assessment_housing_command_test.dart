/// W0 RED — `AssessmentHousingCommand` orchestration contract (C05).
/// `acdg assessment housing <patient-id>`.
///
/// W1 must create
/// `apps/cli/lib/src/commands/assessment_housing_command.dart`:
///
/// ```dart
/// class AssessmentHousingCommand extends Command<int> {
///   AssessmentHousingCommand({
///     required this.bffClient,
///     required this.formatter,
///     required this.fileReader,
///     this.stdout,
///     this.stderr,
///   }) {
///     argParser
///       ..addOption('from-yaml', help: 'Path to a YAML payload override.')
///       // 11 required strings + ints
///       ..addOption('type')
///       ..addOption('wall-material')
///       ..addOption('number-of-rooms')          // int (parsed)
///       ..addOption('number-of-bedrooms')       // int
///       ..addOption('number-of-bathrooms')      // int
///       ..addOption('water-supply')
///       ..addOption('electricity-access')
///       ..addOption('sewage-disposal')
///       ..addOption('waste-collection')
///       ..addOption('accessibility-level')
///       // 5 required bools (passed as `true|false` strings via --opt=)
///       ..addOption('has-piped-water')
///       ..addOption('is-in-geographic-risk-area')
///       ..addOption('has-difficult-access')
///       ..addOption('is-in-social-conflict-area')
///       ..addOption('has-diagnostic-observations');
///   }
///   @override String get name => 'housing';
///   @override Future<int> run();
/// }
/// ```
///
/// Wire mapping (verified against
/// `apps/social_care_bff/web/lib/src/intents/update_housing_condition_intent.dart:51`
/// — calls `UpdateHousingConditionRequest.fromJson(body)` so the body shape
/// == `UpdateHousingConditionRequest.toJson()` per
/// `apps/social_care_bff/contracts/lib/src/contract/dto/requests/assessment/update_housing_condition_request.dart`):
///
/// ```json
/// {
///   "type":                       <String, required>,
///   "wallMaterial":               <String, required>,
///   "numberOfRooms":              <int,    required>,
///   "numberOfBedrooms":           <int,    required>,
///   "numberOfBathrooms":          <int,    required>,
///   "waterSupply":                <String, required>,
///   "hasPipedWater":              <bool,   required>,
///   "electricityAccess":          <String, required>,
///   "sewageDisposal":             <String, required>,
///   "wasteCollection":            <String, required>,
///   "accessibilityLevel":         <String, required>,
///   "isInGeographicRiskArea":     <bool,   required>,
///   "hasDifficultAccess":         <bool,   required>,
///   "isInSocialConflictArea":     <bool,   required>,
///   "hasDiagnosticObservations":  <bool,   required>
/// }
/// ```
///
/// All 15 fields are required in the DTO; this means the command MUST fail
/// fast with a usage error when ANY scalar flag is missing AND --from-yaml
/// is not provided.
library;

import 'package:test/test.dart';

import 'package:cli/src/commands/assessment_housing_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/session/bff_client.dart';

import '_assessment_test_helpers.dart';

const String _kPatientId = kAssessmentPatientId;

const List<String> _kMinimalArgs = [
  '--type=alvenaria',
  '--wall-material=brick',
  '--number-of-rooms=4',
  '--number-of-bedrooms=2',
  '--number-of-bathrooms=1',
  '--water-supply=public',
  '--has-piped-water=true',
  '--electricity-access=metered',
  '--sewage-disposal=public',
  '--waste-collection=public',
  '--accessibility-level=full',
  '--is-in-geographic-risk-area=false',
  '--has-difficult-access=false',
  '--is-in-social-conflict-area=false',
  '--has-diagnostic-observations=false',
];

void main() {
  runAssessmentCommandContract(
    verbName: 'housing',
    pathSuffix: 'housing',
    build:
        ({
          required BffClient bffClient,
          required Future<String> Function(String path) fileReader,
          StringSink? stdout,
          StringSink? stderr,
        }) => AssessmentHousingCommand(
          bffClient: bffClient,
          formatter: const JsonFormatter(),
          fileReader: fileReader,
          stdout: stdout,
          stderr: stderr,
        ),
    minimalArgs: () => _kMinimalArgs,
    yamlBody: '''
type: alvenaria
wallMaterial: brick
numberOfRooms: 4
numberOfBedrooms: 2
numberOfBathrooms: 1
waterSupply: public
hasPipedWater: true
electricityAccess: metered
sewageDisposal: public
wasteCollection: public
accessibilityLevel: full
isInGeographicRiskArea: false
hasDifficultAccess: false
isInSocialConflictArea: false
hasDiagnosticObservations: false
''',
  );

  group('AssessmentHousingCommand — body shape', () {
    test('PUT body matches UpdateHousingConditionRequest.toJson() shape '
        '(15 camelCase keys; ints parsed as ints, bools as bools)', () async {
      final adapter = CapturingAdapter('', status: 204);
      final cmd = AssessmentHousingCommand(
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
      expect(body['type'], equals('alvenaria'));
      expect(body['wallMaterial'], equals('brick'));
      // ints — DTO declares `int`, so the CLI MUST parse the flag value
      // (Strings out of `args`) into Dart `int`s before serializing.
      expect(body['numberOfRooms'], equals(4));
      expect(body['numberOfBedrooms'], equals(2));
      expect(body['numberOfBathrooms'], equals(1));
      expect(body['waterSupply'], equals('public'));
      expect(body['hasPipedWater'], equals(true));
      expect(body['electricityAccess'], equals('metered'));
      expect(body['sewageDisposal'], equals('public'));
      expect(body['wasteCollection'], equals('public'));
      expect(body['accessibilityLevel'], equals('full'));
      expect(body['isInGeographicRiskArea'], equals(false));
      expect(body['hasDifficultAccess'], equals(false));
      expect(body['isInSocialConflictArea'], equals(false));
      expect(body['hasDiagnosticObservations'], equals(false));
    });

    test('missing --type → usage error, no BFF call', () async {
      final adapter = CapturingAdapter('', status: 204);
      final cmd = AssessmentHousingCommand(
        bffClient: buildBff(adapter),
        formatter: const JsonFormatter(),
        fileReader: failingReader,
        stderr: StringBuffer(),
      );

      final args = _kMinimalArgs
          .where((a) => !a.startsWith('--type='))
          .toList();
      final exit = await runWithArgs(cmd, [_kPatientId, ...args]);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test('non-integer --number-of-rooms → usage error, no BFF call', () async {
      final adapter = CapturingAdapter('', status: 204);
      final cmd = AssessmentHousingCommand(
        bffClient: buildBff(adapter),
        formatter: const JsonFormatter(),
        fileReader: failingReader,
        stderr: StringBuffer(),
      );

      final args = _kMinimalArgs
          .map(
            (a) => a.startsWith('--number-of-rooms=')
                ? '--number-of-rooms=NaN'
                : a,
          )
          .toList();
      final exit = await runWithArgs(cmd, [_kPatientId, ...args]);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });
  });
}
