import 'package:core_contracts/core_contracts.dart';

import '../dto/requests/assessment/update_community_support_network_request.dart';
import '../dto/requests/assessment/update_educational_status_request.dart';
import '../dto/requests/assessment/update_health_status_request.dart';
import '../dto/requests/assessment/update_housing_condition_request.dart';
import '../dto/requests/assessment/update_social_health_summary_request.dart';
import '../dto/requests/assessment/update_socio_economic_situation_request.dart';
import '../dto/requests/assessment/update_work_and_income_request.dart';

/// Assessment contract — all 7 assessment fichas.
abstract interface class AssessmentContract {
  /// Updates housing condition assessment.
  Future<Result<void>> updateHousingCondition(
    String patientId,
    UpdateHousingConditionRequest request,
  );

  /// Updates socioeconomic situation assessment.
  Future<Result<void>> updateSocioEconomicSituation(
    String patientId,
    UpdateSocioEconomicSituationRequest request,
  );

  /// Updates work and income assessment.
  Future<Result<void>> updateWorkAndIncome(
    String patientId,
    UpdateWorkAndIncomeRequest request,
  );

  /// Updates educational status assessment.
  Future<Result<void>> updateEducationalStatus(
    String patientId,
    UpdateEducationalStatusRequest request,
  );

  /// Updates health status assessment.
  Future<Result<void>> updateHealthStatus(
    String patientId,
    UpdateHealthStatusRequest request,
  );

  /// Updates community support network assessment.
  Future<Result<void>> updateCommunitySupportNetwork(
    String patientId,
    UpdateCommunitySupportNetworkRequest request,
  );

  /// Updates social health summary assessment.
  Future<Result<void>> updateSocialHealthSummary(
    String patientId,
    UpdateSocialHealthSummaryRequest request,
  );
}
