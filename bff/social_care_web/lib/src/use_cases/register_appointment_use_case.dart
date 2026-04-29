import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/register_appointment_intent.dart';
import '../observability/observability_context.dart';

/// Registers a social care appointment by delegating to
/// [CareContract.registerAppointment].
///
/// Emits the canonical triad of breadcrumbs:
/// - `care.appointment.register.received` on dispatch (carries `patientId`)
/// - `care.appointment.register.completed` on success (carries
///   `appointmentId` — a non-PII UUID)
/// - `care.appointment.register.failed` on error (carries `errorCode`)
///
/// PII-safety: breadcrumbs NEVER echo `summary` or `actionPlan` —
/// these fields may carry case-history content and MUST stay confined
/// to the upstream call path.
final class RegisterAppointmentUseCase {
  const RegisterAppointmentUseCase({required CareContract care}) : _care = care;

  final CareContract _care;

  Future<Result<StandardIdResponse>> execute(
    RegisterAppointmentIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'care.appointment.register.received',
      data: {'patientId': intent.patientId},
    );

    final result = await _care.registerAppointment(
      intent.patientId,
      intent.request,
    );

    return switch (result) {
      Success(:final value) => () {
        obs.breadcrumb(
          'care.appointment.register.completed',
          data: {'appointmentId': value.data.id},
        );
        return Success<StandardIdResponse>(value);
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'care.appointment.register.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure<StandardIdResponse>(error);
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
