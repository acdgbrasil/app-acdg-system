/// `acdg protection referral <patient-id>` — register a referral to another
/// service / institution (C07).
///
/// POSTs `/patients/{id}/referrals` with the [CreateReferralRequest] body
/// shape (3 required strings + 2 optional `String?`):
///
/// ```json
/// {
///   "referredPersonId": "<uuid>",
///   "destinationService": "<str>",
///   "reason": "<str>",
///   "professionalId": "<uuid-or-omitted>",
///   "date": "<iso8601-or-omitted>"
/// }
/// ```
///
/// On success, decodes the BFF envelope `{data:{id:"<uuid>"}, meta:{...}}`
/// (per `protection_handler.dart` + `StandardResponse<IdData>`) and surfaces
/// the new referral id on stdout via the shared [decodeStandardIdResponse]
/// helper, NOT a flat `body['id']`.
///
/// `--date` is validated as ISO8601 BEFORE the HTTP call (via
/// `DateTime.tryParse`); invalid → usage error (exit 64), no BFF call.
/// When absent the field is omitted from the body (DTO `?` field convention
/// via `dropNulls`).
///
/// PII safety — `reason` (free-text case-history narrative) is documented
/// PII-safe by the BFF intent (never echoed in error responses); the CLI
/// forwards it verbatim and never re-prints user input on failure paths.
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../errors/cli_error.dart';
import '../session/bff_client.dart';
import '_command_helpers.dart';

/// `acdg protection referral`.
final class ProtectionReferralCommand extends Command<int> {
  ProtectionReferralCommand({
    required this.bffClient,
    required this.formatter,
    this.stdout,
    this.stderr,
  }) {
    argParser
      // Required per CreateReferralIntent lines 53-71:
      //   missing.add('referredPersonId') / missing.add('destinationService') /
      //   missing.add('reason').
      ..addOption(
        'referred-person-id',
        help: 'Referred person id (UUID) — REQUIRED. PII-adjacent.',
      )
      ..addOption(
        'destination-service',
        help:
            'Destination service / institution name — REQUIRED. PII-safe — '
            'never echoed by the BFF intent in errors.',
      )
      ..addOption(
        'reason',
        help:
            'Reason for the referral — REQUIRED. Free-text case-history '
            'narrative. PII-safe — never echoed.',
      )
      // Optionals — CreateReferralRequest carries them as `String?`.
      ..addOption('professional-id', help: 'Professional id (UUID). Optional.')
      ..addOption(
        'date',
        help: 'Referral date (ISO8601). Optional; validated client-side.',
      );
  }

  final BffClient bffClient;
  final OutputFormatter formatter;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'referral';

  @override
  String get description =>
      'Register a referral to another service or institution.';

  @override
  String get invocation =>
      'acdg protection referral <patient-id> --referred-person-id=UUID '
      '--destination-service=... --reason=... '
      '[--professional-id=UUID] [--date=ISO8601]';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      usageException('Missing required positional argument: <patient-id>');
    }
    final patientId = rest.first;

    final referredPersonId = argResults?['referred-person-id'] as String?;
    if (referredPersonId == null || referredPersonId.isEmpty) {
      usageException('Missing required option: --referred-person-id');
    }

    final destinationService = argResults?['destination-service'] as String?;
    if (destinationService == null || destinationService.isEmpty) {
      usageException('Missing required option: --destination-service');
    }

    final reason = argResults?['reason'] as String?;
    if (reason == null || reason.isEmpty) {
      usageException('Missing required option: --reason');
    }

    final date = argResults?['date'] as String?;
    if (date != null && date.isNotEmpty) {
      // Validate ISO8601 client-side BEFORE the HTTP call so the user gets
      // a clear local error instead of an opaque BFF 400/422.
      if (DateTime.tryParse(date) == null) {
        usageException(
          '--date must be a valid ISO8601 timestamp (got "$date").',
        );
      }
    }

    final body = dropNulls(<String, Object?>{
      'referredPersonId': referredPersonId,
      'destinationService': destinationService,
      'reason': reason,
      'professionalId': argResults?['professional-id'] as String?,
      'date': date,
    });

    final result = await bffClient.post<String?>(
      '/patients/$patientId/referrals',
      body: body,
      decode: decodeStandardIdResponse,
    );
    switch (result) {
      case Success(:final value):
        if (value != null && value.isNotEmpty) {
          _writeOut('Created referral $value');
        } else {
          // Defensive: if the envelope lacked an id, fall back to a generic
          // success line so callers still see exit 0 with non-empty stdout.
          _writeOut('Referral created');
        }
        return 0;
      case Failure(:final error):
        final e = error as CliError;
        _writeErr(e.stderrMessage);
        return e.exitCode;
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
