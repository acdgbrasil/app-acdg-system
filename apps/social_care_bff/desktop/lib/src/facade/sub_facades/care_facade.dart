import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../composition/builders/care_use_cases.dart';

/// Care sub-facade — 3 thin pass-through methods over the Care use
/// cases (A18b-v2).
///
/// Backed by [CareUseCases] — a data class grouping the 3 use cases (D02).
class CareFacade {
  CareFacade.internal({required CareUseCases useCases}) : _useCases = useCases;

  final CareUseCases _useCases;

  Future<Result<List<AppointmentResponse>>> listAppointments(
    String patientId, {
    int? limit,
  }) => _useCases.listAppointments(patientId, limit: limit);

  Future<Result<StandardIdResponse>> registerAppointment(
    String patientId,
    RegisterAppointmentRequest req,
  ) => _useCases.registerAppointment(patientId, req);

  Future<Result<void>> updateIntakeInfo(
    String patientId,
    RegisterIntakeInfoRequest req,
  ) => _useCases.updateIntakeInfo(patientId, req);
}
