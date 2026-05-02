/// Bundles the 7 Assessment use cases (A18b-v2) — all Pattern-2 writes
/// against the Patient aggregate (the social-health fichas live embedded
/// in `Patient`).
///
/// `AssessmentUseCases.build()` does NOT take a `remote:` parameter —
/// none of its 7 use cases consume an `AssessmentContract`. Writes ride
/// the Outbox (engine drains them later); the AssessmentRemote is
/// exercised by the engine's drain, not by the use case itself.
library;

import '../../../cache/contracts/patients_cache.dart';
import '../../../sync/engine/sync_engine.dart';
import '../../../sync/outbox/outbox_repository.dart';
import '../../../use_cases/_shared/clock.dart';
import '../../../use_cases/assessment/update_community_support_network_use_case.dart';
import '../../../use_cases/assessment/update_educational_status_use_case.dart';
import '../../../use_cases/assessment/update_health_status_use_case.dart';
import '../../../use_cases/assessment/update_housing_condition_use_case.dart';
import '../../../use_cases/assessment/update_social_health_summary_use_case.dart';
import '../../../use_cases/assessment/update_socio_economic_situation_use_case.dart';
import '../../../use_cases/assessment/update_work_and_income_use_case.dart';

/// Data class grouping the 7 Assessment use cases.
class AssessmentUseCases {
  AssessmentUseCases({
    required this.updateHealthStatus,
    required this.updateHousingCondition,
    required this.updateEducationalStatus,
    required this.updateSocioEconomicSituation,
    required this.updateWorkAndIncome,
    required this.updateCommunitySupportNetwork,
    required this.updateSocialHealthSummary,
  });

  final UpdateHealthStatusUseCase updateHealthStatus;
  final UpdateHousingConditionUseCase updateHousingCondition;
  final UpdateEducationalStatusUseCase updateEducationalStatus;
  final UpdateSocioEconomicSituationUseCase updateSocioEconomicSituation;
  final UpdateWorkAndIncomeUseCase updateWorkAndIncome;
  final UpdateCommunitySupportNetworkUseCase updateCommunitySupportNetwork;
  final UpdateSocialHealthSummaryUseCase updateSocialHealthSummary;

  /// Constructs all 7 Assessment use cases from shared dependencies.
  static AssessmentUseCases build({
    required PatientsCache patientsCache,
    required OutboxRepository outbox,
    required SyncEngine engine,
    required Clock clock,
  }) {
    return AssessmentUseCases(
      updateHealthStatus: UpdateHealthStatusUseCase(
        cache: patientsCache,
        outbox: outbox,
        engine: engine,
        clock: clock,
      ),
      updateHousingCondition: UpdateHousingConditionUseCase(
        cache: patientsCache,
        outbox: outbox,
        engine: engine,
        clock: clock,
      ),
      updateEducationalStatus: UpdateEducationalStatusUseCase(
        cache: patientsCache,
        outbox: outbox,
        engine: engine,
        clock: clock,
      ),
      updateSocioEconomicSituation: UpdateSocioEconomicSituationUseCase(
        cache: patientsCache,
        outbox: outbox,
        engine: engine,
        clock: clock,
      ),
      updateWorkAndIncome: UpdateWorkAndIncomeUseCase(
        cache: patientsCache,
        outbox: outbox,
        engine: engine,
        clock: clock,
      ),
      updateCommunitySupportNetwork: UpdateCommunitySupportNetworkUseCase(
        cache: patientsCache,
        outbox: outbox,
        engine: engine,
        clock: clock,
      ),
      updateSocialHealthSummary: UpdateSocialHealthSummaryUseCase(
        cache: patientsCache,
        outbox: outbox,
        engine: engine,
        clock: clock,
      ),
    );
  }
}
