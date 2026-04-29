import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/discharge_patient_intent.dart';
import '../observability/observability_context.dart';

/// Discharges a patient by delegating to [RegistryContract.dischargePatient].
///
/// Emits the canonical triad `registry.patient.discharge.{received,
/// completed, failed}` and propagates the upstream [Result] verbatim,
/// wrapping the success case into an empty [StandardResponse] so the handler
/// can serialize a consistent envelope regardless of void-ness.
final class DischargePatientUseCase {
  const DischargePatientUseCase({required RegistryContract registry})
    : _registry = registry;

  final RegistryContract _registry;

  Future<Result<StandardResponse<void>>> execute(
    DischargePatientIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'registry.patient.discharge.received',
      data: {'patientId': intent.patientId},
    );

    final result = await _registry.dischargePatient(
      intent.patientId,
      intent.request,
    );

    return switch (result) {
      Success() => () {
        obs.breadcrumb('registry.patient.discharge.completed');
        return Success<StandardResponse<void>>(
          StandardResponse<void>(
            data: null,
            meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
          ),
        );
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'registry.patient.discharge.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure<StandardResponse<void>>(error);
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
