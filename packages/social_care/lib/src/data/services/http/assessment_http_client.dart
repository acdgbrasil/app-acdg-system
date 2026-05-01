import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:shared/shared.dart';

import '_http_shared.dart';

/// Split from HttpSocialCareClient — Assessment endpoints (7 fichas).
///
/// Organizational split: no logic changes.
class AssessmentHttpClient {
  AssessmentHttpClient({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<Result<void>> updateHousingCondition(
    PatientId patientId,
    HousingCondition condition,
  ) async {
    return putVoid(
      _dio,
      '/patients/${patientId.value}/assessment/housing',
      PatientTranslator.housingConditionToJson(condition),
    );
  }

  Future<Result<void>> updateSocioEconomicSituation(
    PatientId patientId,
    SocioEconomicSituation situation,
  ) async {
    return putVoid(
      _dio,
      '/patients/${patientId.value}/assessment/socioeconomic',
      PatientTranslator.socioEconomicToJson(situation),
    );
  }

  Future<Result<void>> updateWorkAndIncome(
    PatientId patientId,
    WorkAndIncome data,
  ) async {
    return putVoid(
      _dio,
      '/patients/${patientId.value}/assessment/work-income',
      PatientTranslator.workAndIncomeToJson(data),
    );
  }

  Future<Result<void>> updateEducationalStatus(
    PatientId patientId,
    EducationalStatus status,
  ) async {
    return putVoid(
      _dio,
      '/patients/${patientId.value}/assessment/education',
      PatientTranslator.educationalStatusToJson(status),
    );
  }

  Future<Result<void>> updateHealthStatus(
    PatientId patientId,
    HealthStatus status,
  ) async {
    return putVoid(
      _dio,
      '/patients/${patientId.value}/assessment/health',
      PatientTranslator.healthStatusToJson(status),
    );
  }

  Future<Result<void>> updateCommunitySupportNetwork(
    PatientId patientId,
    CommunitySupportNetwork network,
  ) async {
    return putVoid(
      _dio,
      '/patients/${patientId.value}/assessment/community-support',
      PatientTranslator.communitySupportToJson(network),
    );
  }

  Future<Result<void>> updateSocialHealthSummary(
    PatientId patientId,
    SocialHealthSummary summary,
  ) async {
    return putVoid(
      _dio,
      '/patients/${patientId.value}/assessment/social-health-summary',
      PatientTranslator.socialHealthSummaryToJson(summary),
    );
  }
}
