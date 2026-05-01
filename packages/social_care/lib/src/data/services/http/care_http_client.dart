import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:shared/shared.dart';

import '_http_shared.dart';

/// Split from HttpSocialCareClient — Care endpoints (appointments, intake).
///
/// Organizational split: no logic changes.
class CareHttpClient {
  CareHttpClient({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<Result<AppointmentId>> registerAppointment(
    PatientId patientId,
    SocialCareAppointment appointment,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/patients/${patientId.value}/appointments',
        data: PatientTranslator.appointmentToJson(appointment),
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final id = response.data!['id'] as String;
        return AppointmentId.create(id);
      }
      return failureFromResponse(response, 'Failed to register appointment');
    } catch (e) {
      return failureFromException(e);
    }
  }

  Future<Result<void>> updateIntakeInfo(
    PatientId patientId,
    IngressInfo info,
  ) async {
    return putVoid(
      _dio,
      '/patients/${patientId.value}/intake',
      PatientTranslator.intakeInfoToJson(info),
    );
  }
}
