/// W0 RED — `AssessmentHealthCommand` orchestration contract (C05).
/// `acdg assessment health <patient-id>`.
///
/// W1 must create
/// `apps/cli/lib/src/commands/assessment_health_command.dart`:
///
/// ```dart
/// class AssessmentHealthCommand extends Command<int> {
///   AssessmentHealthCommand({
///     required this.bffClient,
///     required this.formatter,
///     required this.fileReader,
///     this.stdout,
///     this.stderr,
///   }) {
///     argParser
///       ..addOption('from-yaml', help: 'Path to a YAML payload override.')
///       ..addOption('food-insecurity')          // bool, required
///       ..addMultiOption('constant-care-need',  // [String], optional
///           help: 'Repeatable: constant-care-need code.');
///       // deficiencies[] and gestatingMembers[] are nested DTO lists;
///       // only --from-yaml populates them.
///   }
///   @override String get name => 'health';
///   @override Future<int> run();
/// }
/// ```
///
/// Wire mapping (verified against
/// `apps/social_care_bff/web/lib/src/intents/update_health_status_intent.dart:47`
/// — calls `UpdateHealthStatusRequest.fromJson(body)` so the body shape ==
/// `UpdateHealthStatusRequest.toJson()` per
/// `apps/social_care_bff/contracts/lib/src/contract/dto/requests/assessment/update_health_status_request.dart`):
///
/// ```json
/// {
///   "deficiencies":      <[DeficiencyDraftDto], default []>,
///   "gestatingMembers":  <[PregnantDraftDto],   default []>,
///   "constantCareNeeds": <[String],             default []>,
///   "foodInsecurity":   <bool, required>
/// }
/// ```
///
/// `DeficiencyDraftDto`: `{memberId, deficiencyTypeId, needsConstantCare,
///   responsibleCaregiverName?}`. PII note (intent line 14-18): the BFF's
/// parse-error message NEVER echoes caregiver names — the CLI must propagate
/// the structural error message verbatim.
/// `PregnantDraftDto`: `{memberId, monthsGestation, startedPrenatalCare}`.
library;

import 'package:test/test.dart';

import 'package:cli/src/commands/assessment_health_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/session/bff_client.dart';

import '_assessment_test_helpers.dart';

const String _kPatientId = kAssessmentPatientId;

const List<String> _kMinimalArgs = ['--food-insecurity=false'];

void main() {
  runAssessmentCommandContract(
    verbName: 'health',
    pathSuffix: 'health',
    build:
        ({
          required BffClient bffClient,
          required Future<String> Function(String path) fileReader,
          StringSink? stdout,
          StringSink? stderr,
        }) => AssessmentHealthCommand(
          bffClient: bffClient,
          formatter: const JsonFormatter(),
          fileReader: fileReader,
          stdout: stdout,
          stderr: stderr,
        ),
    minimalArgs: () => _kMinimalArgs,
    yamlBody: '''
deficiencies: []
gestatingMembers: []
constantCareNeeds: []
foodInsecurity: false
''',
  );

  group('AssessmentHealthCommand — body shape', () {
    test(
      'PUT body matches UpdateHealthStatusRequest.toJson() shape '
      '(camelCase; foodInsecurity required bool; lists default empty)',
      () async {
        final adapter = CapturingAdapter('', status: 204);
        final cmd = AssessmentHealthCommand(
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
        expect(body['foodInsecurity'], equals(false));
        expect(body['deficiencies'], equals(<Object?>[]));
        expect(body['gestatingMembers'], equals(<Object?>[]));
        expect(body['constantCareNeeds'], equals(<String>[]));
      },
    );

    test(
      '--constant-care-need flags accumulate into constantCareNeeds list',
      () async {
        final adapter = CapturingAdapter('', status: 204);
        final cmd = AssessmentHealthCommand(
          bffClient: buildBff(adapter),
          formatter: const JsonFormatter(),
          fileReader: failingReader,
        );

        final exit = await runWithArgs(cmd, const [
          _kPatientId,
          '--food-insecurity=false',
          '--constant-care-need=mobility',
          '--constant-care-need=feeding',
        ]);

        expect(exit, equals(0));
        final body = decodeBody(adapter.lastOptions!.data);
        expect(
          body['constantCareNeeds'],
          equals(<String>['mobility', 'feeding']),
        );
      },
    );

    test(
      '--from-yaml supports nested deficiencies + gestatingMembers',
      () async {
        const yaml = '''
deficiencies:
  - memberId: "11111111-1111-4111-8111-111111111111"
    deficiencyTypeId: "22222222-2222-4222-8222-222222222222"
    needsConstantCare: true
    responsibleCaregiverName: "Maria Silva"
gestatingMembers:
  - memberId: "33333333-3333-4333-8333-333333333333"
    monthsGestation: 4
    startedPrenatalCare: true
constantCareNeeds:
  - mobility
foodInsecurity: true
''';
        Future<String> reader(String _) async => yaml;
        final adapter = CapturingAdapter('', status: 204);
        final cmd = AssessmentHealthCommand(
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
        expect(body['foodInsecurity'], equals(true));
        final deficiencies = body['deficiencies']! as List<Object?>;
        expect(deficiencies, hasLength(1));
        final d0 = deficiencies.first! as Map<String, Object?>;
        expect(d0['needsConstantCare'], equals(true));
        // PII surface check: the caregiver name MAY be sent on the wire (it's
        // legitimate input) but the CLI's stderr in error paths must never
        // surface it. That assertion belongs to the 422 cross-cutting case;
        // here we only confirm the happy-path roundtrip.
        expect(d0['responsibleCaregiverName'], equals('Maria Silva'));
        final gestating = body['gestatingMembers']! as List<Object?>;
        expect(gestating, hasLength(1));
        final g0 = gestating.first! as Map<String, Object?>;
        expect(g0['monthsGestation'], equals(4));
      },
    );

    test('missing --food-insecurity → usage error, no BFF call', () async {
      final adapter = CapturingAdapter('', status: 204);
      final cmd = AssessmentHealthCommand(
        bffClient: buildBff(adapter),
        formatter: const JsonFormatter(),
        fileReader: failingReader,
        stderr: StringBuffer(),
      );

      final exit = await runWithArgs(cmd, const [_kPatientId]);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });
  });
}
