import 'package:core_contracts/core_contracts.dart';

import '../dto/requests/care/register_appointment_request.dart';
import '../dto/requests/care/register_intake_info_request.dart';
import '../dto/shared/standard_response.dart';

/// Care contract — appointments and intake information.
abstract interface class CareContract {
  /// Registers a new social care appointment.
  /// Returns [StandardIdResponse] with the generated appointment ID.
  Future<Result<StandardIdResponse>> registerAppointment(
    String patientId,
    RegisterAppointmentRequest request,
  );

  /// Updates the intake (acolhimento) information.
  Future<Result<void>> updateIntakeInfo(
    String patientId,
    RegisterIntakeInfoRequest request,
  );
}
