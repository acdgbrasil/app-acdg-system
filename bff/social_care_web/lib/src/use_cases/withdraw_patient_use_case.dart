import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/withdraw_patient_intent.dart';
import '../observability/observability_context.dart';

/// Withdraws a patient from the waitlist via
/// [RegistryContract.withdrawPatient].
final class WithdrawPatientUseCase {
  const WithdrawPatientUseCase({required RegistryContract registry})
    : _registry = registry;

  final RegistryContract _registry;

  Future<Result<StandardResponse<void>>> execute(
    WithdrawPatientIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'registry.patient.withdraw.received',
      data: {'patientId': intent.patientId},
    );

    final result = await _registry.withdrawPatient(
      intent.patientId,
      intent.request,
    );

    return switch (result) {
      Success() => () {
        obs.breadcrumb('registry.patient.withdraw.completed');
        return Success<StandardResponse<void>>(
          StandardResponse<void>(
            data: null,
            meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
          ),
        );
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'registry.patient.withdraw.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure<StandardResponse<void>>(error);
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
