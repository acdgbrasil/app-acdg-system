import 'package:core_contracts/core_contracts.dart';

import '../contract/dto/requests/assessment/update_community_support_network_request.dart';
import '../contract/dto/requests/assessment/update_educational_status_request.dart';
import '../contract/dto/requests/assessment/update_health_status_request.dart';
import '../contract/dto/requests/assessment/update_housing_condition_request.dart';
import '../contract/dto/requests/assessment/update_social_health_summary_request.dart';
import '../contract/dto/requests/assessment/update_socio_economic_situation_request.dart';
import '../contract/dto/requests/assessment/update_work_and_income_request.dart';
import '../contract/sub_contracts/assessment_contract.dart';

/// In-memory fake for [AssessmentContract] — returns Success for all
/// ficha updates; no payload is stored.
class FakeAssessmentBff implements AssessmentContract {
  @override
  Future<Result<void>> updateHousingCondition(
    String patientId,
    UpdateHousingConditionRequest request,
  ) async => const Success(null);

  @override
  Future<Result<void>> updateSocioEconomicSituation(
    String patientId,
    UpdateSocioEconomicSituationRequest request,
  ) async => const Success(null);

  @override
  Future<Result<void>> updateWorkAndIncome(
    String patientId,
    UpdateWorkAndIncomeRequest request,
  ) async => const Success(null);

  @override
  Future<Result<void>> updateEducationalStatus(
    String patientId,
    UpdateEducationalStatusRequest request,
  ) async => const Success(null);

  @override
  Future<Result<void>> updateHealthStatus(
    String patientId,
    UpdateHealthStatusRequest request,
  ) async => const Success(null);

  @override
  Future<Result<void>> updateCommunitySupportNetwork(
    String patientId,
    UpdateCommunitySupportNetworkRequest request,
  ) async => const Success(null);

  @override
  Future<Result<void>> updateSocialHealthSummary(
    String patientId,
    UpdateSocialHealthSummaryRequest request,
  ) async => const Success(null);
}
