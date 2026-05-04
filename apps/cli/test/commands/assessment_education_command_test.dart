/// W0 RED — `AssessmentEducationCommand` orchestration contract (C05).
/// `acdg assessment education <patient-id>`.
///
/// W1 must create
/// `apps/cli/lib/src/commands/assessment_education_command.dart`:
///
/// ```dart
/// class AssessmentEducationCommand extends Command<int> {
///   AssessmentEducationCommand({
///     required this.bffClient,
///     required this.formatter,
///     required this.fileReader,
///     this.stdout,
///     this.stderr,
///   }) {
///     argParser
///       ..addOption('from-yaml', help: 'Path to a YAML payload override.')
///       // Single-profile flag-based shortcut. All four required together.
///       ..addOption('member-id')
///       ..addOption('can-read-write')        // bool
///       ..addOption('attends-school')        // bool
///       ..addOption('education-level-id');
///   }
///   @override String get name => 'education';
///   @override Future<int> run();
/// }
/// ```
///
/// Wire mapping (verified against
/// `apps/social_care_bff/web/lib/src/intents/update_educational_status_intent.dart:43`
/// — calls `UpdateEducationalStatusRequest.fromJson(body)` so the body shape
/// == `UpdateEducationalStatusRequest.toJson()` per
/// `apps/social_care_bff/contracts/lib/src/contract/dto/requests/assessment/update_educational_status_request.dart`):
///
/// ```json
/// {
///   "memberProfiles":     <[ProfileDraftDto],    default []>,
///   "programOccurrences": <[OccurrenceDraftDto], default []>
/// }
/// ```
///
/// `ProfileDraftDto`: `{memberId, canReadWrite, attendsSchool, educationLevelId}`.
/// `OccurrenceDraftDto`: `{memberId, date, effectId, isSuspensionRequested}`.
///
/// **DTO has zero required top-level scalars** — both lists default to
/// empty. So flag-based mode here means: "either provide ALL FOUR profile
/// flags to add one entry, or use --from-yaml". Calling the command with
/// only the positional and no flags / no yaml is a usage error (the user
/// almost certainly meant `--from-yaml=...`).
library;

import 'package:test/test.dart';

import 'package:cli/src/commands/assessment_education_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/session/bff_client.dart';

import '_assessment_test_helpers.dart';

const String _kPatientId = kAssessmentPatientId;
const String _kMemberId = '55555555-5555-4555-8555-555555555555';
const String _kEduLevelId = '66666666-6666-4666-8666-666666666666';

const List<String> _kMinimalArgs = [
  '--member-id=$_kMemberId',
  '--can-read-write=true',
  '--attends-school=true',
  '--education-level-id=$_kEduLevelId',
];

void main() {
  runAssessmentCommandContract(
    verbName: 'education',
    pathSuffix: 'education',
    build:
        ({
          required BffClient bffClient,
          required Future<String> Function(String path) fileReader,
          StringSink? stdout,
          StringSink? stderr,
        }) => AssessmentEducationCommand(
          bffClient: bffClient,
          formatter: const JsonFormatter(),
          fileReader: fileReader,
          stdout: stdout,
          stderr: stderr,
        ),
    minimalArgs: () => _kMinimalArgs,
    yamlBody:
        '''
memberProfiles:
  - memberId: "$_kMemberId"
    canReadWrite: true
    attendsSchool: true
    educationLevelId: "$_kEduLevelId"
programOccurrences: []
''',
  );

  group('AssessmentEducationCommand — body shape', () {
    test('flag-based: PUT body assembles a single ProfileDraft entry; '
        'programOccurrences defaults to empty list', () async {
      final adapter = CapturingAdapter('', status: 204);
      final cmd = AssessmentEducationCommand(
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
      final profiles = body['memberProfiles']! as List<Object?>;
      expect(profiles, hasLength(1));
      final p0 = profiles.first! as Map<String, Object?>;
      expect(p0['memberId'], equals(_kMemberId));
      expect(p0['canReadWrite'], equals(true));
      expect(p0['attendsSchool'], equals(true));
      expect(p0['educationLevelId'], equals(_kEduLevelId));
      expect(body['programOccurrences'], equals(<Object?>[]));
    });

    test(
      '--from-yaml supports both memberProfiles + programOccurrences lists',
      () async {
        const yaml = '''
memberProfiles:
  - memberId: "55555555-5555-4555-8555-555555555555"
    canReadWrite: false
    attendsSchool: true
    educationLevelId: "66666666-6666-4666-8666-666666666666"
programOccurrences:
  - memberId: "55555555-5555-4555-8555-555555555555"
    date: "2026-04-30"
    effectId: "77777777-7777-4777-8777-777777777777"
    isSuspensionRequested: false
''';
        Future<String> reader(String _) async => yaml;
        final adapter = CapturingAdapter('', status: 204);
        final cmd = AssessmentEducationCommand(
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
        final profiles = body['memberProfiles']! as List<Object?>;
        expect(profiles, hasLength(1));
        final p0 = profiles.first! as Map<String, Object?>;
        expect(p0['canReadWrite'], equals(false));
        final occ = body['programOccurrences']! as List<Object?>;
        expect(occ, hasLength(1));
        final o0 = occ.first! as Map<String, Object?>;
        expect(o0['date'], equals('2026-04-30'));
        expect(o0['isSuspensionRequested'], equals(false));
      },
    );

    test('no flags AND no --from-yaml → usage error, no BFF call '
        '(empty payload almost certainly a user mistake)', () async {
      final adapter = CapturingAdapter('', status: 204);
      final cmd = AssessmentEducationCommand(
        bffClient: buildBff(adapter),
        formatter: const JsonFormatter(),
        fileReader: failingReader,
        stderr: StringBuffer(),
      );

      final exit = await runWithArgs(cmd, const [_kPatientId]);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test(
      'partial flag set (only --member-id) → usage error, no BFF call',
      () async {
        final adapter = CapturingAdapter('', status: 204);
        final cmd = AssessmentEducationCommand(
          bffClient: buildBff(adapter),
          formatter: const JsonFormatter(),
          fileReader: failingReader,
          stderr: StringBuffer(),
        );

        final exit = await runWithArgs(cmd, const [
          _kPatientId,
          '--member-id=$_kMemberId',
        ]);

        expect(exit, isNot(equals(0)));
        expect(adapter.lastOptions, isNull);
      },
    );
  });
}
