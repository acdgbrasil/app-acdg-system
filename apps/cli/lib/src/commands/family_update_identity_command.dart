/// `acdg family update-identity <patient-id> --type-id=<uuid> [--description]`
/// (C04).
///
/// PUTs `/patients/<id>/social-identity` with the
/// [UpdateSocialIdentityRequest] body shape:
/// `{"typeId": "<uuid>", "description"?: "..."}`.
///
/// `description` is omitted from the body when the flag is absent
/// (DTO is `String? description`, BFF intent collapses empty/missing to
/// `null` — sending the literal `"description": null` would be a wire-format
/// surprise, so we follow the dropNulls pattern from `_command_helpers.dart`).
///
/// **Divergence from C04 ticket prose:** the ticket said `--gender --pronoun`,
/// but the canonical DTO is `{typeId, description?}`. Following the C03
/// DTO-as-canon decision, the CLI exposes `--type-id` + `--description`. The
/// `--type-id` flag is REQUIRED (W0 §4.8 — the BFF intent rejects empty
/// `typeId`).
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../errors/cli_error.dart';
import '../session/bff_client.dart';
import '_command_helpers.dart';

/// `acdg family update-identity`.
final class FamilyUpdateIdentityCommand extends Command<int> {
  FamilyUpdateIdentityCommand({
    required this.bffClient,
    required this.formatter,
    this.stdout,
    this.stderr,
  }) {
    argParser
      ..addOption(
        'type-id',
        help: 'Social identity type id (UUID v4, required)',
      )
      ..addOption(
        'description',
        help: 'Optional free-form description (e.g. self-identification text)',
      );
  }

  final BffClient bffClient;
  final OutputFormatter formatter;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'update-identity';

  @override
  String get description =>
      'Update a patient\'s social identity (type id + optional description).';

  @override
  String get invocation =>
      'acdg family update-identity <patient-id> --type-id=<uuid> [--description=...]';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      usageException('Missing required positional argument: <patient-id>');
    }
    final patientId = rest.first;

    final typeId = argResults?['type-id'] as String?;
    if (typeId == null || typeId.isEmpty) {
      usageException('Missing required option: --type-id');
    }

    final body = dropNulls(<String, Object?>{
      'typeId': typeId,
      'description': argResults?['description'] as String?,
    });

    final result = await bffClient.put<Object?>(
      '/patients/$patientId/social-identity',
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

  void _writeErr(String line) {
    final err = stderr ?? stdout;
    if (err != null) err.writeln(line);
  }
}
