import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/get_patient_intent.dart';
import '../observability/observability_context.dart';

/// Fetches a single patient aggregate via [RegistryContract.fetchPatient].
///
/// The [PeopleContract] dependency is threaded through for future
/// scatter-gather enrichment (family member names by personId) — the
/// current implementation returns the raw registry response. When
/// enrichment arrives it MUST mask PII in breadcrumbs via [pii_mask].
///
/// Observability: `registry.patient.get.received`, `.completed`, `.failed`.
final class GetPatientUseCase {
  const GetPatientUseCase({
    required RegistryContract registry,
    required PeopleContract people,
  }) : _registry = registry,
       // ignore: unused_field
       _people = people;

  final RegistryContract _registry;
  // Retained for future aggregate enrichment. See Wave 0 REPORT.
  // ignore: unused_field
  final PeopleContract _people;

  Future<Result<StandardResponse<PatientResponse>>> execute(
    GetPatientIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'registry.patient.get.received',
      data: {'patientId': intent.patientId},
    );

    final result = await _registry.fetchPatient(intent.patientId);

    return switch (result) {
      Success() => () {
        obs.breadcrumb('registry.patient.get.completed');
        return result;
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'registry.patient.get.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return result;
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
