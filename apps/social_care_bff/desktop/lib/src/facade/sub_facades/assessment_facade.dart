import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../../use_cases/assessment/update_community_support_network_use_case.dart';
import '../../use_cases/assessment/update_educational_status_use_case.dart';
import '../../use_cases/assessment/update_health_status_use_case.dart';
import '../../use_cases/assessment/update_housing_condition_use_case.dart';
import '../../use_cases/assessment/update_social_health_summary_use_case.dart';
import '../../use_cases/assessment/update_socio_economic_situation_use_case.dart';
import '../../use_cases/assessment/update_work_and_income_use_case.dart';

/// Assessment sub-facade — 7 thin pass-through methods over the
/// Assessment use cases (A18b-v2). All methods follow Pattern 2
/// (patient-aggregate write): take `(String patientId, XxxRequest req)`
/// and return `Result<void>`.
class AssessmentFacade {
  AssessmentFacade.internal({
    required UpdateHealthStatusUseCase updateHealthStatus,
    required UpdateHousingConditionUseCase updateHousingCondition,
    required UpdateEducationalStatusUseCase updateEducationalStatus,
    required UpdateSocioEconomicSituationUseCase updateSocioEconomicSituation,
    required UpdateWorkAndIncomeUseCase updateWorkAndIncome,
    required UpdateCommunitySupportNetworkUseCase updateCommunitySupportNetwork,
    required UpdateSocialHealthSummaryUseCase updateSocialHealthSummary,
  }) : _updateHealthStatus = updateHealthStatus,
       _updateHousingCondition = updateHousingCondition,
       _updateEducationalStatus = updateEducationalStatus,
       _updateSocioEconomicSituation = updateSocioEconomicSituation,
       _updateWorkAndIncome = updateWorkAndIncome,
       _updateCommunitySupportNetwork = updateCommunitySupportNetwork,
       _updateSocialHealthSummary = updateSocialHealthSummary;

  final UpdateHealthStatusUseCase _updateHealthStatus;
  final UpdateHousingConditionUseCase _updateHousingCondition;
  final UpdateEducationalStatusUseCase _updateEducationalStatus;
  final UpdateSocioEconomicSituationUseCase _updateSocioEconomicSituation;
  final UpdateWorkAndIncomeUseCase _updateWorkAndIncome;
  final UpdateCommunitySupportNetworkUseCase _updateCommunitySupportNetwork;
  final UpdateSocialHealthSummaryUseCase _updateSocialHealthSummary;

  Future<Result<void>> updateHealthStatus(
    String patientId,
    UpdateHealthStatusRequest req,
  ) => _updateHealthStatus(patientId, req);

  Future<Result<void>> updateHousingCondition(
    String patientId,
    UpdateHousingConditionRequest req,
  ) => _updateHousingCondition(patientId, req);

  Future<Result<void>> updateEducationalStatus(
    String patientId,
    UpdateEducationalStatusRequest req,
  ) => _updateEducationalStatus(patientId, req);

  Future<Result<void>> updateSocioEconomicSituation(
    String patientId,
    UpdateSocioEconomicSituationRequest req,
  ) => _updateSocioEconomicSituation(patientId, req);

  Future<Result<void>> updateWorkAndIncome(
    String patientId,
    UpdateWorkAndIncomeRequest req,
  ) => _updateWorkAndIncome(patientId, req);

  Future<Result<void>> updateCommunitySupportNetwork(
    String patientId,
    UpdateCommunitySupportNetworkRequest req,
  ) => _updateCommunitySupportNetwork(patientId, req);

  Future<Result<void>> updateSocialHealthSummary(
    String patientId,
    UpdateSocialHealthSummaryRequest req,
  ) => _updateSocialHealthSummary(patientId, req);
}
