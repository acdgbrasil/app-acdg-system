import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '_shared/remote_base.dart';

/// Care remote — appointments and intake info.
class CareRemote extends RemoteBase implements CareContract {
  CareRemote({required super.dio});

  @override
  Future<Result<StandardIdResponse>> registerAppointment(
    String patientId,
    RegisterAppointmentRequest request,
  ) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/api/v1/patients/$patientId/appointments',
        data: request.toJson(),
        options: RemoteBase.passthroughStatus,
      );
      final code = response.statusCode;
      if (code == 201 || code == 200) {
        return Success<StandardIdResponse>(extractIdResponse(response.data!));
      }
      return backendFailure(response, 'Failed to register appointment');
    } catch (e, stackTrace) {
      return Failure<StandardIdResponse>(e, stackTrace: stackTrace);
    }
  }

  @override
  Future<Result<void>> updateIntakeInfo(
    String patientId,
    RegisterIntakeInfoRequest request,
  ) async {
    try {
      final response = await dio.put<dynamic>(
        '/api/v1/patients/$patientId/intake-info',
        data: request.toJson(),
        options: RemoteBase.passthroughStatus,
      );
      final code = response.statusCode;
      if (code == 204 || code == 200) {
        return const Success<void>(null);
      }
      return backendFailure(response, 'Failed to update intake info');
    } catch (e, stackTrace) {
      return Failure<void>(e, stackTrace: stackTrace);
    }
  }
}
