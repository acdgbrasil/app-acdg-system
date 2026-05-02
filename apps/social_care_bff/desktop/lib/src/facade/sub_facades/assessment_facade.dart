import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../composition/builders/assessment_use_cases.dart';

/// Assessment sub-facade — 7 thin pass-through methods over the
/// Assessment use cases (A18b-v2). All methods follow Pattern 2
/// (patient-aggregate write): take `(String patientId, XxxRequest req)`
/// and return `Result<void>`.
///
/// Backed by [AssessmentUseCases] — a data class grouping the 7 use
/// cases (D02).
class AssessmentFacade {
  AssessmentFacade.internal({required AssessmentUseCases useCases})
    : _useCases = useCases;

  final AssessmentUseCases _useCases;

  Future<Result<void>> updateHealthStatus(
    String patientId,
    UpdateHealthStatusRequest req,
  ) => _useCases.updateHealthStatus(patientId, req);

  Future<Result<void>> updateHousingCondition(
    String patientId,
    UpdateHousingConditionRequest req,
  ) => _useCases.updateHousingCondition(patientId, req);

  Future<Result<void>> updateEducationalStatus(
    String patientId,
    UpdateEducationalStatusRequest req,
  ) => _useCases.updateEducationalStatus(patientId, req);

  Future<Result<void>> updateSocioEconomicSituation(
    String patientId,
    UpdateSocioEconomicSituationRequest req,
  ) => _useCases.updateSocioEconomicSituation(patientId, req);

  Future<Result<void>> updateWorkAndIncome(
    String patientId,
    UpdateWorkAndIncomeRequest req,
  ) => _useCases.updateWorkAndIncome(patientId, req);

  Future<Result<void>> updateCommunitySupportNetwork(
    String patientId,
    UpdateCommunitySupportNetworkRequest req,
  ) => _useCases.updateCommunitySupportNetwork(patientId, req);

  Future<Result<void>> updateSocialHealthSummary(
    String patientId,
    UpdateSocialHealthSummaryRequest req,
  ) => _useCases.updateSocialHealthSummary(patientId, req);
}
