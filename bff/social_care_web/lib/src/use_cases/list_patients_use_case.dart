import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/list_patients_intent.dart';
import '../observability/observability_context.dart';

/// Lists patients by forwarding filters to [RegistryContract.fetchPatients].
///
/// The [PeopleContract] dependency is kept for future scatter-gather
/// enrichment (e.g. resolving a `personId -> fullName` cache batch) but the
/// current happy-path simply returns whatever the Registry supplies. When
/// enrichment arrives it MUST respect the PII canon — no raw names in
/// breadcrumbs.
///
/// Observability: emits `registry.patient.list.received`, a `.completed`
/// with a `count` datum, and `.failed` with `errorCode` on upstream
/// failure.
final class ListPatientsUseCase {
  const ListPatientsUseCase({
    required RegistryContract registry,
    required PeopleContract people,
  }) : _registry = registry,
       // ignore: unused_field, prefer_final_fields, // kept for future enrichment
       _people = people;

  final RegistryContract _registry;
  // Retained for future scatter-gather; current happy-path does not touch
  // People Context. See Wave 0 REPORT for rationale.
  // ignore: unused_field
  final PeopleContract _people;

  Future<Result<PaginatedList<PatientSummaryResponse>>> execute(
    ListPatientsIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'registry.patient.list.received',
      data: {
        if (intent.search != null) 'hasSearch': true,
        if (intent.status != null) 'status': intent.status,
        if (intent.cursor != null) 'hasCursor': true,
        if (intent.limit != null) 'limit': intent.limit,
      },
    );

    final result = await _registry.fetchPatients(
      search: intent.search,
      status: intent.status,
      cursor: intent.cursor,
      limit: intent.limit,
    );

    return switch (result) {
      Success(:final value) => () {
        obs.breadcrumb(
          'registry.patient.list.completed',
          data: {'count': value.data.length},
        );
        return result;
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'registry.patient.list.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return result;
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
