import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../../use_cases/care/list_appointments_use_case.dart';
import '../../use_cases/care/register_appointment_use_case.dart';
import '../../use_cases/care/update_intake_info_use_case.dart';

/// Care sub-facade — 3 thin pass-through methods over the Care use
/// cases (A18b-v2).
class CareFacade {
  CareFacade.internal({
    required ListAppointmentsUseCase listAppointments,
    required RegisterAppointmentUseCase registerAppointment,
    required UpdateIntakeInfoUseCase updateIntakeInfo,
  }) : _listAppointments = listAppointments,
       _registerAppointment = registerAppointment,
       _updateIntakeInfo = updateIntakeInfo;

  final ListAppointmentsUseCase _listAppointments;
  final RegisterAppointmentUseCase _registerAppointment;
  final UpdateIntakeInfoUseCase _updateIntakeInfo;

  Future<Result<List<AppointmentResponse>>> listAppointments(
    String patientId, {
    int? limit,
  }) => _listAppointments(patientId, limit: limit);

  Future<Result<StandardIdResponse>> registerAppointment(
    String patientId,
    RegisterAppointmentRequest req,
  ) => _registerAppointment(patientId, req);

  Future<Result<void>> updateIntakeInfo(
    String patientId,
    RegisterIntakeInfoRequest req,
  ) => _updateIntakeInfo(patientId, req);
}
