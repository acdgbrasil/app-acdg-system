/// `acdg family add` — add a family member to a patient (C04).
///
/// Usage: `acdg family add PATIENT_ID --relationship=X --birth-date=YYYY-MM-DD
///   --pr-relationship-id=UUID [--member-cpf=...] [--full-name=...]
///   [--member-person-id=...] [--is-residing] [--is-caregiver]
///   [--has-disability] [--required-document=...]`
///
/// POSTs `/patients/{id}/family-members` with a flat envelope that combines
/// the [AddFamilyMemberRequest] DTO (Registry side) with the People-Context
/// inputs read directly off the body by the BFF intent.
///
/// Wire format (per `add_family_member_intent.dart`):
/// ```json
/// {
///   "memberPersonId": "...",   // optional — defaults to ""
///   "relationship": "...",      // REQUIRED
///   "birthDate": "YYYY-MM-DD",  // REQUIRED
///   "prRelationshipId": "...",  // REQUIRED
///   "isResiding": false,
///   "isCaregiver": false,
///   "hasDisability": false,
///   "requiredDocuments": [],
///   "cpf": "...",               // optional — top-level (NOT under request)
///   "fullName": "..."           // optional — top-level (NOT under request)
/// }
/// ```
///
/// 5xx is a saga-edge case (e.g. People-Context outage): the CLI does NOT
/// attempt rollback (BFF responsibility); it surfaces a retry hint on stderr.
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../errors/cli_error.dart';
import '../formatters/output_formatter.dart';
import '../session/bff_client.dart';
import '_command_helpers.dart';

/// `acdg family add`.
final class FamilyAddCommand extends Command<int> {
  FamilyAddCommand({
    required this.bffClient,
    required this.formatter,
    this.stdout,
    this.stderr,
  }) {
    argParser
      // Registry-side mandatory fields (per AddFamilyMemberRequest DTO).
      ..addOption(
        'relationship',
        help: 'Relationship code (required, e.g. "MOTHER")',
      )
      ..addOption('birth-date', help: 'Member birth date YYYY-MM-DD (required)')
      ..addOption(
        'pr-relationship-id',
        help: 'PR relationship lookup id (required, UUID v4)',
      )
      // People-Context inputs (top-level on the wire envelope).
      ..addOption(
        'member-cpf',
        help: 'Member CPF (forwarded to People Context)',
      )
      ..addOption('full-name', help: 'Full name (forwarded to People Context)')
      // Registry-side optionals.
      ..addOption(
        'member-person-id',
        help: 'Existing person id; mutually exclusive with --member-cpf',
      )
      ..addFlag('is-residing', defaultsTo: false)
      ..addFlag('is-caregiver', defaultsTo: false)
      ..addFlag('has-disability', defaultsTo: false)
      ..addMultiOption(
        'required-document',
        help: 'Required document codes (repeatable)',
      );
  }

  final BffClient bffClient;
  final OutputFormatter formatter;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'add';

  @override
  String get description =>
      'Add a family member to a patient (saga: registers in People Context + Registry).';

  @override
  String get invocation =>
      'acdg family add <patient-id> --relationship=X --birth-date=YYYY-MM-DD '
      '--pr-relationship-id=UUID [--member-cpf=...] [--full-name=...] '
      '[--member-person-id=...] [--is-residing] [--is-caregiver] '
      '[--has-disability] [--required-document=...]';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      usageException('Missing required positional argument: <patient-id>');
    }
    final patientId = rest.first;

    final relationship = argResults?['relationship'] as String?;
    if (relationship == null || relationship.isEmpty) {
      usageException('Missing required option: --relationship');
    }

    final birthDate = argResults?['birth-date'] as String?;
    if (birthDate == null || birthDate.isEmpty) {
      usageException('Missing required option: --birth-date');
    }

    final prRelationshipId = argResults?['pr-relationship-id'] as String?;
    if (prRelationshipId == null || prRelationshipId.isEmpty) {
      usageException('Missing required option: --pr-relationship-id');
    }

    final memberPersonId = (argResults?['member-person-id'] as String?) ?? '';
    final cpf = argResults?['member-cpf'] as String?;
    final fullName = argResults?['full-name'] as String?;
    final requiredDocuments =
        (argResults?['required-document'] as List<String>?) ?? const <String>[];

    final body = dropNulls(<String, Object?>{
      // Registry-side fields (DTO-faithful camelCase).
      'memberPersonId': memberPersonId,
      'relationship': relationship,
      'birthDate': birthDate,
      'prRelationshipId': prRelationshipId,
      'isResiding': argResults?['is-residing'] as bool? ?? false,
      'isCaregiver': argResults?['is-caregiver'] as bool? ?? false,
      'hasDisability': argResults?['has-disability'] as bool? ?? false,
      'requiredDocuments': requiredDocuments,
      // People-Context envelope fields (top-level, NOT inside `request`).
      'cpf': cpf,
      'fullName': fullName,
    });

    final result = await bffClient.post<Object?>(
      '/patients/$patientId/family-members',
      body: body,
    );
    switch (result) {
      case Success():
        return 0;
      case Failure(:final error):
        _writeErr(stderrMessageFor(error));
        if (error is ServerError && error.statusCode >= 500) {
          _writeErr(
            'Family member registration failed (HTTP ${error.statusCode}). '
            'The patient record may have been partially modified; please '
            "check via 'acdg patient get $patientId' or retry.",
          );
        }
        return exitCodeFor(error);
    }
  }

  void _writeErr(String line) {
    final err = stderr ?? stdout;
    if (err != null) err.writeln(line);
  }
}
