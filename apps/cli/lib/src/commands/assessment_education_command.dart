/// `acdg assessment education <patient-id>` — update the educational-status
/// ficha (C05).
///
/// PUTs `/patients/{id}/assessment/education` with the
/// [UpdateEducationalStatusRequest] body shape: two nested lists,
/// `memberProfiles` and `programOccurrences`, both default-empty.
///
/// Two input modes (mutually exclusive):
///   * `--from-yaml=<path>` — full payload (only way to populate
///     `programOccurrences` or multiple `memberProfiles`).
///   * **All four** profile flags `--member-id --can-read-write
///     --attends-school --education-level-id` — assemble a single-element
///     `memberProfiles[]` (most common CLI use case). Partial flag set or
///     no flags at all is rejected as a usage error: an empty payload is
///     almost certainly a user mistake.
library;

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../errors/cli_error.dart';
import '../session/bff_client.dart';
import '_yaml_helpers.dart';

/// `acdg assessment education`.
final class AssessmentEducationCommand extends Command<int> {
  AssessmentEducationCommand({
    required this.bffClient,
    required this.formatter,
    required this.fileReader,
    this.stdout,
    this.stderr,
  }) {
    argParser
      ..addOption('from-yaml', help: 'Path to a YAML payload override.')
      // Single-profile flag-based shortcut. All four are required together.
      ..addOption(
        'member-id',
        help: 'Family member id (UUID v4, required with the profile flags).',
      )
      ..addOption(
        'can-read-write',
        help:
            'true|false — member is literate '
            '(required with the profile flags).',
      )
      ..addOption(
        'attends-school',
        help:
            'true|false — member currently attends school '
            '(required with the profile flags).',
      )
      ..addOption(
        'education-level-id',
        help: 'Education-level lookup id (required with the profile flags).',
      );
  }

  final BffClient bffClient;
  final OutputFormatter formatter;
  final Future<String> Function(String path) fileReader;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'education';

  @override
  String get description =>
      'Update the educational-status ficha (single-profile shortcut via '
      'flags; multiple profiles or programOccurrences[] only via --from-yaml).';

  @override
  String get invocation =>
      'acdg assessment education <patient-id> [--from-yaml=<path> | '
      '--member-id=<uuid> --can-read-write=true|false '
      '--attends-school=true|false --education-level-id=<uuid>]';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      usageException('Missing required positional argument: <patient-id>');
    }
    final patientId = rest.first;

    final fromYaml = argResults?['from-yaml'] as String?;
    const profileFlags = <String>[
      'member-id',
      'can-read-write',
      'attends-school',
      'education-level-id',
    ];
    final flagPresence = profileFlags
        .map((f) => (argResults?[f] as String?)?.isNotEmpty ?? false)
        .toList();
    final flagsSet = flagPresence.where((p) => p).length;
    final hasAnyFlag = flagsSet > 0;

    if (fromYaml != null && fromYaml.isNotEmpty && hasAnyFlag) {
      usageException(
        '--from-yaml is mutually exclusive with field flags '
        '(--member-id, --can-read-write, --attends-school, '
        '--education-level-id).',
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
      // Reject "no flags AND no --from-yaml": an empty payload is almost
      // certainly a user mistake.
      if (!hasAnyFlag) {
        usageException(
          'Either --from-yaml=<path> OR all four profile flags '
          '(--member-id, --can-read-write, --attends-school, '
          '--education-level-id) are required.',
        );
      }
      // All-or-nothing for the profile flag set.
      if (flagsSet != profileFlags.length) {
        usageException(
          'The profile flags (--member-id, --can-read-write, --attends-school, '
          '--education-level-id) must all be provided together.',
        );
      }
      body = _buildBodyFromFlags();
    }

    final result = await bffClient.put<Object?>(
      '/patients/$patientId/assessment/education',
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
    final memberId = (r['member-id'] as String?)!;
    final canReadWrite = _parseBool(r, 'can-read-write');
    final attendsSchool = _parseBool(r, 'attends-school');
    final educationLevelId = (r['education-level-id'] as String?)!;
    return <String, Object?>{
      'memberProfiles': <Object?>[
        <String, Object?>{
          'memberId': memberId,
          'canReadWrite': canReadWrite,
          'attendsSchool': attendsSchool,
          'educationLevelId': educationLevelId,
        },
      ],
      'programOccurrences': <Object?>[],
    };
  }

  bool _parseBool(ArgResults r, String name) {
    final raw = (r[name] as String?)!;
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
