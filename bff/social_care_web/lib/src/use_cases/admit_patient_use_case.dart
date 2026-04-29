import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/admit_patient_intent.dart';
import '../observability/observability_context.dart';

/// Admits a patient by delegating to [RegistryContract.admitPatient].
///
/// Emits the canonical triad of breadcrumbs:
/// - `registry.patient.admit.received` on dispatch (carries `patientId`)
/// - `registry.patient.admit.completed` on success
/// - `registry.patient.admit.failed` on error (carries `errorCode`)
///
/// The admit request body (`reason`, `admittedAt`, `notes`) is NOT forwarded
/// to the registry in the current contract — the backend treats admission
/// as a state toggle. The parsed metadata is preserved on the intent for
/// audit/observability and future contract evolution.
final class AdmitPatientUseCase {
  const AdmitPatientUseCase({required RegistryContract registry})
    : _registry = registry;

  final RegistryContract _registry;

  Future<Result<StandardResponse<void>>> execute(
    AdmitPatientIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'registry.patient.admit.received',
      data: {'patientId': intent.patientId},
    );

    final result = await _registry.admitPatient(intent.patientId);

    return switch (result) {
      Success() => () {
        obs.breadcrumb('registry.patient.admit.completed');
        return Success<StandardResponse<void>>(
          StandardResponse<void>(
            data: null,
            meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
          ),
        );
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'registry.patient.admit.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure<StandardResponse<void>>(error);
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
