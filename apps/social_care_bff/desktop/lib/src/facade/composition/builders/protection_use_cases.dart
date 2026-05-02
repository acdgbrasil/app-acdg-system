/// Bundles the 6 Protection use cases (A18b-v2):
///   * `CreateReferralUseCase`        — write, outbox + engine (no cache)
///   * `ListReferralsUseCase`         — read, `protectionCache` only
///   * `ReportViolationUseCase`       — write, outbox + engine (no cache)
///   * `ListViolationReportsUseCase`  — read, `protectionCache` only
///   * `FetchPlacementHistoryUseCase` — read, `protectionCache` only
///   * `UpdatePlacementHistoryUseCase`— write, `patientsCache` (placement
///                                      history lives on Patient aggregate)
///                                      + outbox + engine
///
/// No `remote:` parameter — Phase 5 backend doesn't expose protection
/// list/get endpoints; reads serve from cache, writes ride the Outbox.
/// `staleAfter` is accepted for Pattern-1 uniformity (H3).
library;

import '../../../cache/contracts/patients_cache.dart';
import '../../../cache/contracts/protection_cache.dart';
import '../../../sync/engine/sync_engine.dart';
import '../../../sync/outbox/outbox_repository.dart';
import '../../../use_cases/_shared/clock.dart';
import '../../../use_cases/protection/create_referral_use_case.dart';
import '../../../use_cases/protection/fetch_placement_history_use_case.dart';
import '../../../use_cases/protection/list_referrals_use_case.dart';
import '../../../use_cases/protection/list_violation_reports_use_case.dart';
import '../../../use_cases/protection/report_violation_use_case.dart';
import '../../../use_cases/protection/update_placement_history_use_case.dart';

/// Data class grouping the 6 Protection use cases.
class ProtectionUseCases {
  ProtectionUseCases({
    required this.createReferral,
    required this.listReferrals,
    required this.reportViolation,
    required this.listViolationReports,
    required this.fetchPlacementHistory,
    required this.updatePlacementHistory,
  });

  final CreateReferralUseCase createReferral;
  final ListReferralsUseCase listReferrals;
  final ReportViolationUseCase reportViolation;
  final ListViolationReportsUseCase listViolationReports;
  final FetchPlacementHistoryUseCase fetchPlacementHistory;
  final UpdatePlacementHistoryUseCase updatePlacementHistory;

  /// Constructs all 6 Protection use cases from shared dependencies.
  static ProtectionUseCases build({
    required ProtectionCache protectionCache,
    required PatientsCache patientsCache,
    required OutboxRepository outbox,
    required SyncEngine engine,
    required Clock clock,
    required Duration staleAfter,
  }) {
    return ProtectionUseCases(
      createReferral: CreateReferralUseCase(
        outbox: outbox,
        engine: engine,
        clock: clock,
      ),
      listReferrals: ListReferralsUseCase(
        cache: protectionCache,
        clock: clock,
        staleAfter: staleAfter,
      ),
      reportViolation: ReportViolationUseCase(
        outbox: outbox,
        engine: engine,
        clock: clock,
      ),
      listViolationReports: ListViolationReportsUseCase(
        cache: protectionCache,
        clock: clock,
        staleAfter: staleAfter,
      ),
      fetchPlacementHistory: FetchPlacementHistoryUseCase(
        cache: protectionCache,
        clock: clock,
        staleAfter: staleAfter,
      ),
      updatePlacementHistory: UpdatePlacementHistoryUseCase(
        patientsCache: patientsCache,
        outbox: outbox,
        engine: engine,
        clock: clock,
      ),
    );
  }
}
