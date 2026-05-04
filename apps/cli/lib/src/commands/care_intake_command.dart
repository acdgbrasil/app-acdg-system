/// `acdg care intake <patient-id>` — update the patient intake info (C06).
///
/// PUTs `/patients/{id}/intake` with the [RegisterIntakeInfoRequest] body
/// shape (2 required + 2 optional `String?` here; `linkedSocialPrograms`
/// is intentionally not forwarded by the CLI):
///
/// ```json
/// {
///   "ingressTypeId": "<uuid-or-lookup-id>",
///   "serviceReason": "<text>",
///   "originName": "<str-or-omitted>",
///   "originContact": "<str-or-omitted>"
/// }
/// ```
///
/// `linkedSocialPrograms` is omitted by the CLI in C06 — the BFF intent
/// (`update_intake_info_intent.dart:94-99`) degrades a missing list to
/// `const []`, so client need not send it. A repeatable
/// `--linked-program` flag is deferred (see W2 follow-ups).
///
/// Behavior (per `UpdateIntakeInfoIntent` + `RegisterIntakeInfoRequest`):
///   * Required positional `<patient-id>`.
///   * Required `--ingress-type-id` and `--service-reason` — both per the
///     BFF intent (`update_intake_info_intent.dart:55-69`).
///   * 200 with `{data:null,meta:{...}}` envelope OR 204 No Content → exit 0.
///   * 401 → exit 2 + auth-related stderr.
///   * 422/4xx → exit 1 + stderr surfaces status code.
///   * 5xx → exit 1 + stderr surfaces status code.
///   * Network failure → exit 3.
///
/// PII safety — `serviceReason`, `originName`, `originContact` are
/// documented PII-safe by the BFF intent (never echoed in error
/// responses); the CLI forwards them verbatim and never re-prints user
/// input on failure paths.
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../session/bff_client.dart';
import '_command_helpers.dart';

/// `acdg care intake`.
final class CareIntakeCommand extends Command<int> {
  CareIntakeCommand({
    required this.bffClient,
    required this.formatter,
    this.stdout,
    this.stderr,
  }) {
    argParser
      // Required per UpdateIntakeInfoIntent lines 67-69:
      //   missing.add('ingressTypeId') / missing.add('serviceReason').
      ..addOption('ingress-type-id', help: 'Ingress type lookup id — REQUIRED.')
      ..addOption(
        'service-reason',
        help:
            'Service reason — REQUIRED. PII-safe: never echoed by the '
            'BFF intent in error responses.',
      )
      // Optionals — RegisterIntakeInfoRequest carries them as `String?`.
      ..addOption('origin-name', help: 'Origin name. Optional. PII-safe.')
      ..addOption(
        'origin-contact',
        help: 'Origin contact. Optional. PII-safe.',
      );
  }

  final BffClient bffClient;
  final OutputFormatter formatter;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'intake';

  @override
  String get description =>
      'Update the intake info (ingress type + service reason) for a patient.';

  @override
  String get invocation =>
      'acdg care intake <patient-id> --ingress-type-id=UUID '
      '--service-reason=TEXT [--origin-name=...] [--origin-contact=...]';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      usageException('Missing required positional argument: <patient-id>');
    }
    final patientId = rest.first;

    final ingressTypeId = argResults?['ingress-type-id'] as String?;
    if (ingressTypeId == null || ingressTypeId.isEmpty) {
      usageException('Missing required option: --ingress-type-id');
    }

    final serviceReason = argResults?['service-reason'] as String?;
    if (serviceReason == null || serviceReason.isEmpty) {
      usageException('Missing required option: --service-reason');
    }

    final body = dropNulls(<String, Object?>{
      'ingressTypeId': ingressTypeId,
      'serviceReason': serviceReason,
      'originName': argResults?['origin-name'] as String?,
      'originContact': argResults?['origin-contact'] as String?,
    });

    final result = await bffClient.put<Object?>(
      '/patients/$patientId/intake',
      body: body,
    );
    switch (result) {
      case Success():
        return 0;
      case Failure(:final error):
        _writeErr(stderrMessageFor(error));
        return exitCodeFor(error);
    }
  }

  void _writeErr(String line) {
    final err = stderr ?? stdout;
    if (err != null) err.writeln(line);
  }
}
