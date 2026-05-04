/// `acdg care appointment <patient-id>` — register a care appointment (C06).
///
/// POSTs `/patients/{id}/appointments` with the
/// [RegisterAppointmentRequest] body shape (1 required + 4 optional `String?`):
///
/// ```json
/// {
///   "professionalId": "<uuid>",
///   "date": "<iso8601-or-omitted>",
///   "type": "<str-or-omitted>",
///   "summary": "<str-or-omitted>",
///   "actionPlan": "<str-or-omitted>"
/// }
/// ```
///
/// On success, decodes the BFF envelope `{data:{id:"<uuid>"}, meta:{...}}`
/// (per `care_handler.dart:127-131` + `StandardResponse<IdData>`) and
/// surfaces the new appointment id on stdout. The decode path traverses
/// `data.id`, NOT a flat `body['id']`.
///
/// `--date` is validated as ISO8601 BEFORE the HTTP call (via
/// `DateTime.tryParse`); invalid → usage error (exit 64), no BFF call.
/// When `--date` is absent the field is omitted from the body
/// (DTO `?` field convention via `dropNulls`).
///
/// PII safety — `summary`, `actionPlan` are documented PII-safe by the
/// BFF intent (never echoed in error responses); the CLI forwards them
/// verbatim and never re-prints user input on failure paths.
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../session/bff_client.dart';
import '_command_helpers.dart';

/// `acdg care appointment`.
final class CareAppointmentCommand extends Command<int> {
  CareAppointmentCommand({
    required this.bffClient,
    required this.formatter,
    this.stdout,
    this.stderr,
  }) {
    argParser
      // The ONLY required field per RegisterAppointmentIntent line 57:
      //   `if (body case {'professionalId': final String pid} ...)`.
      ..addOption('professional-id', help: 'Professional id (UUID) — REQUIRED.')
      // Optionals — RegisterAppointmentRequest carries them as `String?`
      // and the BFF intent reads each via `_asString(body['<key>'])`.
      ..addOption(
        'date',
        help: 'Appointment date (ISO8601). Optional; validated client-side.',
      )
      ..addOption('type', help: 'Appointment type code. Optional.')
      ..addOption(
        'summary',
        help:
            'Short summary. Optional. PII-safe — never echoed in '
            'errors by the BFF intent.',
      )
      ..addOption('action-plan', help: 'Action plan. Optional. PII-safe.');
  }

  final BffClient bffClient;
  final OutputFormatter formatter;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'appointment';

  @override
  String get description => 'Register a care appointment for a patient.';

  @override
  String get invocation =>
      'acdg care appointment <patient-id> --professional-id=UUID '
      '[--date=ISO8601] [--type=...] [--summary=...] [--action-plan=...]';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      usageException('Missing required positional argument: <patient-id>');
    }
    final patientId = rest.first;

    final professionalId = argResults?['professional-id'] as String?;
    if (professionalId == null || professionalId.isEmpty) {
      usageException('Missing required option: --professional-id');
    }

    final date = argResults?['date'] as String?;
    if (date != null && date.isNotEmpty) {
      // Validate ISO8601 client-side BEFORE the HTTP call so the user gets
      // a clear local error instead of an opaque BFF 400/422.
      final parsed = DateTime.tryParse(date);
      if (parsed == null) {
        usageException(
          '--date must be a valid ISO8601 timestamp (got "$date").',
        );
      }
    }

    final body = dropNulls(<String, Object?>{
      'professionalId': professionalId,
      'date': date,
      'type': argResults?['type'] as String?,
      'summary': argResults?['summary'] as String?,
      'actionPlan': argResults?['action-plan'] as String?,
    });

    final result = await bffClient.post<String?>(
      '/patients/$patientId/appointments',
      body: body,
      decode: _decodeAppointmentId,
    );
    switch (result) {
      case Success(:final value):
        if (value != null && value.isNotEmpty) {
          _writeOut('Created appointment $value');
        } else {
          // Defensive: if the envelope lacked an id, fall back to a generic
          // success line so callers still see exit 0 with non-empty stdout.
          _writeOut('Appointment created');
        }
        return 0;
      case Failure(:final error):
        _writeErr(stderrMessageFor(error));
        return exitCodeFor(error);
    }
  }

  /// Reads `data.id` from the `StandardResponse<IdData>` envelope. Returns
  /// `null` when the envelope shape is unexpected (the success path then
  /// degrades to a generic "Appointment created" line).
  static String? _decodeAppointmentId(Object? data) {
    if (data is! Map<String, Object?>) return null;
    final inner = data['data'];
    if (inner is! Map<String, Object?>) return null;
    final id = inner['id'];
    return id is String ? id : null;
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
