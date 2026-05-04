/// `acdg protection violation <patient-id>` — report a rights-violation
/// occurrence (C07).
///
/// POSTs `/patients/{id}/violations` with the
/// [ReportRightsViolationRequest] body shape (3 required strings + 4 optional
/// `String?`):
///
/// ```json
/// {
///   "victimId": "<uuid>",
///   "violationType": "<str>",
///   "descriptionOfFact": "<str>",
///   "violationTypeId": "<str-or-omitted>",
///   "reportDate": "<iso8601-or-omitted>",
///   "incidentDate": "<iso8601-or-omitted>",
///   "actionsTaken": "<str-or-omitted>"
/// }
/// ```
///
/// On success, decodes the BFF envelope `{data:{id:"<uuid>"}, meta:{...}}`
/// (per `protection_handler.dart:172-183` + `StandardResponse<IdData>`) and
/// surfaces the new violation report id on stdout. The decode path traverses
/// `data.id` via the shared [decodeStandardIdResponse] helper, NOT a flat
/// `body['id']`.
///
/// `--report-date` and `--incident-date` are validated as ISO8601 BEFORE the
/// HTTP call (via `DateTime.tryParse`); invalid → usage error (exit 64),
/// no BFF call. When absent the field is omitted from the body
/// (DTO `?` field convention via `dropNulls`).
///
/// PII safety — `descriptionOfFact` (free-text narrative against the patient)
/// and `actionsTaken` are documented PII-dense by the BFF intent (never
/// echoed in error responses); the CLI forwards them verbatim and never
/// re-prints user input on failure paths.
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../session/bff_client.dart';
import '_command_helpers.dart';

/// `acdg protection violation`.
final class ProtectionViolationCommand extends Command<int> {
  ProtectionViolationCommand({
    required this.bffClient,
    required this.formatter,
    this.stdout,
    this.stderr,
  }) {
    argParser
      // Required per ReportRightsViolationIntent lines 65-80:
      //   missing.add('victimId') / missing.add('violationType') /
      //   missing.add('descriptionOfFact').
      ..addOption(
        'victim-id',
        help:
            'Victim person id (UUID) — REQUIRED. PII-adjacent: never echoed '
            'by the BFF intent in error responses.',
      )
      ..addOption('violation-type', help: 'Violation type — REQUIRED.')
      ..addOption(
        'description-of-fact',
        help:
            'Free-text description of the fact — REQUIRED. PII-dense '
            '(narrative against paciente). PII-safe — never echoed by the '
            'BFF intent in error responses.',
      )
      // Optionals — ReportRightsViolationRequest carries them as `String?`
      // and the BFF intent reads each via `_asString(body['<key>'])`.
      ..addOption(
        'violation-type-id',
        help: 'Violation type lookup id. Optional.',
      )
      ..addOption(
        'report-date',
        help: 'Report date (ISO8601). Optional; validated client-side.',
      )
      ..addOption(
        'incident-date',
        help: 'Incident date (ISO8601). Optional; validated client-side.',
      )
      ..addOption('actions-taken', help: 'Actions taken. Optional. PII-safe.');
  }

  final BffClient bffClient;
  final OutputFormatter formatter;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'violation';

  @override
  String get description =>
      'Report a rights-violation occurrence for a patient.';

  @override
  String get invocation =>
      'acdg protection violation <patient-id> --victim-id=UUID '
      '--violation-type=... --description-of-fact=... '
      '[--violation-type-id=...] [--report-date=ISO8601] '
      '[--incident-date=ISO8601] [--actions-taken=...]';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      usageException('Missing required positional argument: <patient-id>');
    }
    final patientId = rest.first;

    final victimId = argResults?['victim-id'] as String?;
    if (victimId == null || victimId.isEmpty) {
      usageException('Missing required option: --victim-id');
    }

    final violationType = argResults?['violation-type'] as String?;
    if (violationType == null || violationType.isEmpty) {
      usageException('Missing required option: --violation-type');
    }

    final descriptionOfFact = argResults?['description-of-fact'] as String?;
    if (descriptionOfFact == null || descriptionOfFact.isEmpty) {
      usageException('Missing required option: --description-of-fact');
    }

    final reportDate = argResults?['report-date'] as String?;
    if (reportDate != null && reportDate.isNotEmpty) {
      // Validate ISO8601 client-side BEFORE the HTTP call so the user gets
      // a clear local error instead of an opaque BFF 400/422.
      if (DateTime.tryParse(reportDate) == null) {
        usageException(
          '--report-date must be a valid ISO8601 timestamp '
          '(got "$reportDate").',
        );
      }
    }

    final incidentDate = argResults?['incident-date'] as String?;
    if (incidentDate != null && incidentDate.isNotEmpty) {
      if (DateTime.tryParse(incidentDate) == null) {
        usageException(
          '--incident-date must be a valid ISO8601 timestamp '
          '(got "$incidentDate").',
        );
      }
    }

    final body = dropNulls(<String, Object?>{
      'victimId': victimId,
      'violationType': violationType,
      'descriptionOfFact': descriptionOfFact,
      'violationTypeId': argResults?['violation-type-id'] as String?,
      'reportDate': reportDate,
      'incidentDate': incidentDate,
      'actionsTaken': argResults?['actions-taken'] as String?,
    });

    final result = await bffClient.post<String?>(
      '/patients/$patientId/violations',
      body: body,
      decode: decodeStandardIdResponse,
    );
    switch (result) {
      case Success(:final value):
        if (value != null && value.isNotEmpty) {
          _writeOut('Reported violation $value');
        } else {
          // Defensive: if the envelope lacked an id, fall back to a generic
          // success line so callers still see exit 0 with non-empty stdout.
          _writeOut('Violation reported');
        }
        return 0;
      case Failure(:final error):
        _writeErr(stderrMessageFor(error));
        return exitCodeFor(error);
    }
  }

  void _writeOut(String line) {
    final out = stdout;
    if (out != null) out.writeln(line);
  }

  void _writeErr(String line) {
    final err = stderr ?? stdout;
    if (err != null) err.writeln(line);
  }
}
