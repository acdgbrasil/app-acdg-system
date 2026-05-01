import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:shared/shared.dart';

import '_http_shared.dart';

/// Split from HttpSocialCareClient — Protection endpoints (violations, referrals, placement).
///
/// Organizational split: no logic changes.
class ProtectionHttpClient {
  ProtectionHttpClient({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<Result<void>> updatePlacementHistory(
    PatientId patientId,
    PlacementHistory history,
  ) async {
    return putVoid(
      _dio,
      '/patients/${patientId.value}/placement-history',
      PatientTranslator.placementHistoryToJson(history),
    );
  }

  Future<Result<ViolationReportId>> reportViolation(
    PatientId patientId,
    RightsViolationReport report,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/patients/${patientId.value}/violations',
        data: PatientTranslator.violationReportToJson(report),
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final id = response.data!['id'] as String;
        return ViolationReportId.create(id);
      }
      return failureFromResponse(response, 'Failed to report violation');
    } catch (e) {
      return failureFromException(e);
    }
  }

  Future<Result<ReferralId>> createReferral(
    PatientId patientId,
    Referral referral,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/patients/${patientId.value}/referrals',
        data: PatientTranslator.referralToJson(referral),
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final id = response.data!['id'] as String;
        return ReferralId.create(id);
      }
      return failureFromResponse(response, 'Failed to create referral');
    } catch (e) {
      return failureFromException(e);
    }
  }
}
