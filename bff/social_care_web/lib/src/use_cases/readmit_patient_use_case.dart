import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/readmit_patient_intent.dart';
import '../observability/observability_context.dart';

/// Readmits a previously discharged patient via
/// [RegistryContract.readmitPatient].
final class ReadmitPatientUseCase {
  const ReadmitPatientUseCase({required RegistryContract registry})
    : _registry = registry;

  final RegistryContract _registry;

  Future<Result<StandardResponse<void>>> execute(
    ReadmitPatientIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'registry.patient.readmit.received',
      data: {'patientId': intent.patientId},
    );

    final result = await _registry.readmitPatient(
      intent.patientId,
      intent.request,
    );

    return switch (result) {
      Success() => () {
        obs.breadcrumb('registry.patient.readmit.completed');
        return Success<StandardResponse<void>>(
          StandardResponse<void>(
            data: null,
            meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
          ),
        );
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'registry.patient.readmit.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure<StandardResponse<void>>(error);
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
