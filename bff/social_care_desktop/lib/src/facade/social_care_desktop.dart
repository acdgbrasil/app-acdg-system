/// Public entry point for the Desktop BFF (in-process facade).
///
/// Closes the Onda 4 rebuild: composes 7 thin remotes (A16-v2), 5 caches
/// (A17-v2), the SyncEngine + Outbox + 28 mutations (A18a-v2), and 42
/// use cases (A18b-v2) into a single `SocialCareDesktop` instance with 7
/// public sub-facades.
///
/// Lifecycle (D4 α — app-controlled):
///   * `create()` builds everything but does NOT start sync.
///   * `startSync()` enables the engine after login.
///   * `stopSync()` suspends the engine on logout (rows stay queued).
///   * `close()` releases all resources (databases, connectivity sub).
///
/// Connectivity (D5 γ — trigger-based drain on restore):
///   * Subscribes to `connectivity_plus` `onConnectivityChanged` ONCE
///     at `create()`.
///   * On offline → online edge, fires-and-forgets `engine.triggerDrain()`.
///   * Subscription cancelled by `close()`.
///
/// Path defaults (D3):
///   * Cache: `getApplicationDocumentsDirectory()/app_cache.sqlite`
///   * SyncQueue: `getApplicationDocumentsDirectory()/app_sync_queue.sqlite`
///   * Override via `cacheFilePath` / `syncQueueFilePath`. Use `':memory:'`
///     to spin Drift in-memory databases (tests).
library;

import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:core_contracts/core_contracts.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import '../cache/_shared/cache_database.dart';
import '../cache/impls/drift_audit_cache.dart';
import '../cache/impls/drift_care_cache.dart';
import '../cache/impls/drift_lookup_cache.dart';
import '../cache/impls/drift_patients_cache.dart';
import '../cache/impls/drift_protection_cache.dart';
import '../remote/_shared/remote_base.dart';
import '../remote/assessment_remote.dart';
import '../remote/audit_remote.dart';
import '../remote/care_remote.dart';
import '../remote/health_remote.dart';
import '../remote/lookup_remote.dart';
import '../remote/protection_remote.dart';
import '../remote/registry_remote.dart';
import '../sync/_shared/failures.dart';
import '../sync/_shared/sync_database.dart';
import '../sync/engine/sync_engine.dart';
import '../sync/outbox/outbox_repository.dart';
import '../use_cases/_shared/clock.dart';
import '../use_cases/assessment/update_community_support_network_use_case.dart';
import '../use_cases/assessment/update_educational_status_use_case.dart';
import '../use_cases/assessment/update_health_status_use_case.dart';
import '../use_cases/assessment/update_housing_condition_use_case.dart';
import '../use_cases/assessment/update_social_health_summary_use_case.dart';
import '../use_cases/assessment/update_socio_economic_situation_use_case.dart';
import '../use_cases/assessment/update_work_and_income_use_case.dart';
import '../use_cases/audit/fetch_audit_trail_use_case.dart';
import '../use_cases/care/list_appointments_use_case.dart';
import '../use_cases/care/register_appointment_use_case.dart';
import '../use_cases/care/update_intake_info_use_case.dart';
import '../use_cases/health/check_health_use_case.dart';
import '../use_cases/health/check_ready_use_case.dart';
import '../use_cases/lookup/approve_lookup_request_use_case.dart';
import '../use_cases/lookup/create_lookup_item_use_case.dart';
import '../use_cases/lookup/create_lookup_request_use_case.dart';
import '../use_cases/lookup/find_lookup_request_by_id_use_case.dart';
import '../use_cases/lookup/get_lookup_table_use_case.dart';
import '../use_cases/lookup/get_lookups_batch_use_case.dart';
import '../use_cases/lookup/list_lookup_requests_use_case.dart';
import '../use_cases/lookup/reject_lookup_request_use_case.dart';
import '../use_cases/lookup/toggle_lookup_item_use_case.dart';
import '../use_cases/lookup/update_lookup_item_use_case.dart';
import '../use_cases/protection/create_referral_use_case.dart';
import '../use_cases/protection/fetch_placement_history_use_case.dart';
import '../use_cases/protection/list_referrals_use_case.dart';
import '../use_cases/protection/list_violation_reports_use_case.dart';
import '../use_cases/protection/report_violation_use_case.dart';
import '../use_cases/protection/update_placement_history_use_case.dart';
import '../use_cases/registry/add_family_member_use_case.dart';
import '../use_cases/registry/admit_patient_use_case.dart';
import '../use_cases/registry/assign_primary_caregiver_use_case.dart';
import '../use_cases/registry/discharge_patient_use_case.dart';
import '../use_cases/registry/fetch_patient_by_person_id_use_case.dart';
import '../use_cases/registry/fetch_patient_use_case.dart';
import '../use_cases/registry/list_patients_use_case.dart';
import '../use_cases/registry/readmit_patient_use_case.dart';
import '../use_cases/registry/register_patient_use_case.dart';
import '../use_cases/registry/remove_family_member_use_case.dart';
import '../use_cases/registry/search_patients_use_case.dart';
import '../use_cases/registry/update_social_identity_use_case.dart';
import '../use_cases/registry/withdraw_patient_use_case.dart';
import 'sub_facades/assessment_facade.dart';
import 'sub_facades/audit_facade.dart';
import 'sub_facades/care_facade.dart';
import 'sub_facades/health_facade.dart';
import 'sub_facades/lookup_facade.dart';
import 'sub_facades/protection_facade.dart';
import 'sub_facades/registry_facade.dart';

/// In-memory marker recognised by Drift's `NativeDatabase` factory; used
/// by tests to spin a transient cache/sync DB without touching disk.
const String _inMemoryMarker = ':memory:';

/// SyncEngine subclass that pumps every successful drain summary onto
/// a broadcast controller. The facade exposes that controller as
/// [SocialCareDesktop.drainStream], so UI panels see EVERY drain
/// completion — including the ones triggered fire-and-forget by write
/// use cases (which call `_engine.triggerDrain()` directly).
///
/// Failures are NOT pumped — the panel UI surfaces them via the Result
/// returned from `triggerDrain` (or the engine's internal state). The
/// stream is intentionally success-only so a flapping connection
/// doesn't spam the UI with `Failure` events.
class _PumpingSyncEngine extends SyncEngine {
  _PumpingSyncEngine({
    required super.outbox,
    required super.registry,
    required super.assessment,
    required super.care,
    required super.protection,
    required super.lookup,
    required StreamController<DrainSummary> drainController,
  }) : _drainController = drainController;

  final StreamController<DrainSummary> _drainController;

  @override
  Future<Result<DrainSummary>> triggerDrain() async {
    final result = await super.triggerDrain();
    switch (result) {
      case Success<DrainSummary>(:final value):
        if (!_drainController.isClosed) {
          _drainController.add(value);
        }
      case Failure<DrainSummary>():
        break;
    }
    return result;
  }
}

/// Public entry point for the Desktop BFF.
///
/// See file-level doc for lifecycle, connectivity, and path semantics.
class SocialCareDesktop {
  SocialCareDesktop._({
    required this.registry,
    required this.assessment,
    required this.care,
    required this.protection,
    required this.audit,
    required this.lookup,
    required this.health,
    required SyncEngine engine,
    required CacheDatabase cacheDb,
    required SyncDatabase syncDb,
    required Connectivity connectivity,
    required StreamController<DrainSummary> drainController,
    required StreamSubscription<List<ConnectivityResult>> connectivitySub,
    required bool initialOnline,
  }) : _engine = engine,
       _cacheDb = cacheDb,
       _syncDb = syncDb,
       _connectivity = connectivity,
       _drainController = drainController,
       _connectivitySub = connectivitySub,
       _wasOnline = initialOnline;

  // ── Public sub-facades ─────────────────────────────────────────────

  final RegistryFacade registry;
  final AssessmentFacade assessment;
  final CareFacade care;
  final ProtectionFacade protection;
  final AuditFacade audit;
  final LookupFacade lookup;
  final HealthFacade health;

  // ── Internals ──────────────────────────────────────────────────────

  final SyncEngine _engine;
  final CacheDatabase _cacheDb;
  final SyncDatabase _syncDb;
  // ignore: unused_field
  final Connectivity _connectivity;
  final StreamController<DrainSummary> _drainController;
  final StreamSubscription<List<ConnectivityResult>> _connectivitySub;
  bool _wasOnline;
  bool _closed = false;

  // ── Public sync state ──────────────────────────────────────────────

  /// Broadcast stream of [DrainSummary] events — emits one per drain
  /// completion (manual `triggerDrain` or connectivity-restore edge).
  /// Multiple listeners (e.g. sync_detail_panel + home_page indicator)
  /// receive every event.
  Stream<DrainSummary> get drainStream => _drainController.stream;

  /// Manually triggers a drain pass. Pre-`startSync` this is a no-op
  /// (`Success(processed: 0)`) per D4 α; post-`close` it returns
  /// `Failure(SyncFailure)`.
  ///
  /// The underlying [_PumpingSyncEngine] pumps successful drain summaries
  /// onto [drainStream], so manual triggers AND fire-and-forget triggers
  /// from write use cases all surface there.
  Future<Result<DrainSummary>> triggerDrain() {
    if (_closed) {
      return Future.value(
        Failure<DrainSummary>(SyncFailure('SocialCareDesktop closed')),
      );
    }
    return _engine.triggerDrain();
  }

  // ── Public lifecycle (D4 α) ────────────────────────────────────────

  /// Enables the SyncEngine. Idempotent — calling twice is a no-op.
  /// Call this AFTER login when the auth token becomes available.
  Future<void> startSync() => _engine.start();

  /// Suspends the SyncEngine. Pending Outbox rows stay queued; subsequent
  /// `triggerDrain` returns `Success(processed: 0)` until `startSync`
  /// is called again.
  Future<void> stopSync() => _engine.stop();

  /// Releases resources:
  ///   1. Cancels the connectivity subscription.
  ///   2. Closes the SyncEngine (subsequent `triggerDrain` returns Failure).
  ///   3. Closes both Drift databases (cache + sync).
  ///   4. Closes the broadcast `drainController`.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _connectivitySub.cancel();
    await _engine.close();
    try {
      await _cacheDb.close();
    } catch (_) {}
    try {
      await _syncDb.close();
    } catch (_) {}
    if (!_drainController.isClosed) {
      await _drainController.close();
    }
  }

  // ── Factory (D3 + D4 + D5 wired) ──────────────────────────────────

  /// Builds the full Desktop BFF instance.
  ///
  /// Resolves file paths via `path_provider` (D3) when not overridden,
  /// then opens both Drift databases, builds 7 remotes via Dio (sharing
  /// one client with `X-Actor-Id` + `Authorization`-via-tokenProvider),
  /// composes 42 use cases, groups them into 7 sub-facades, and wires
  /// the connectivity listener (D5 γ).
  ///
  /// **Does NOT auto-start the engine** (D4 α). Call `startSync()` after
  /// login.
  static Future<SocialCareDesktop> create({
    required String baseUrl,
    required String actorId,
    required String? Function() tokenProvider,
    String? cacheFilePath,
    String? syncQueueFilePath,
    Dio? dio,
    Clock? clock,
    Duration staleAfter = const Duration(minutes: 5),
    Connectivity? connectivity,
  }) async {
    // ── Path resolution (D3) ─────────────────────────────────────────
    final resolvedCachePath =
        cacheFilePath ?? await _defaultPath('app_cache.sqlite');
    final resolvedSyncPath =
        syncQueueFilePath ?? await _defaultPath('app_sync_queue.sqlite');

    // ── Database open ────────────────────────────────────────────────
    final cacheDb = CacheDatabase(_openDriftExecutor(resolvedCachePath));
    final syncDb = SyncDatabase(_openDriftExecutor(resolvedSyncPath));

    // ── Clock + Dio ──────────────────────────────────────────────────
    final effectiveClock = clock ?? const SystemClock();
    final effectiveDio =
        dio ??
        RemoteBase.buildDio(
          baseUrl: baseUrl,
          actorId: actorId,
          tokenProvider: tokenProvider,
        );

    // ── Caches (5) ───────────────────────────────────────────────────
    final patientsCache = DriftPatientsCache(cacheDb, clock: effectiveClock);
    final careCache = DriftCareCache(cacheDb, clock: effectiveClock);
    final protectionCache = DriftProtectionCache(
      cacheDb,
      clock: effectiveClock,
    );
    final auditCache = DriftAuditCache(cacheDb, clock: effectiveClock);
    final lookupCache = DriftLookupCache(cacheDb, clock: effectiveClock);

    // ── Outbox + remotes ─────────────────────────────────────────────
    final outbox = DriftOutboxRepository(syncDb);
    final registryRemote = RegistryRemote(dio: effectiveDio);
    final assessmentRemote = AssessmentRemote(dio: effectiveDio);
    final careRemote = CareRemote(dio: effectiveDio);
    final protectionRemote = ProtectionRemote(dio: effectiveDio);
    final auditRemote = AuditRemote(dio: effectiveDio);
    final lookupRemote = LookupRemote(dio: effectiveDio);
    final healthRemote = HealthRemote(dio: effectiveDio);

    // ── DrainStream broadcast (created early so engine can pump it) ──
    final drainController = StreamController<DrainSummary>.broadcast();

    // ── Sync engine (pumping subclass — see _PumpingSyncEngine) ──────
    final engine = _PumpingSyncEngine(
      outbox: outbox,
      registry: registryRemote,
      assessment: assessmentRemote,
      care: careRemote,
      protection: protectionRemote,
      lookup: lookupRemote,
      drainController: drainController,
    );

    // ── Use cases — Registry (13) ────────────────────────────────────
    final fetchPatient = FetchPatientUseCase(
      cache: patientsCache,
      remote: registryRemote,
      clock: effectiveClock,
      staleAfter: staleAfter,
    );
    final fetchPatientByPersonId = FetchPatientByPersonIdUseCase(
      cache: patientsCache,
      remote: registryRemote,
      clock: effectiveClock,
      staleAfter: staleAfter,
    );
    final listPatients = ListPatientsUseCase(
      cache: patientsCache,
      remote: registryRemote,
      clock: effectiveClock,
      staleAfter: staleAfter,
    );
    final searchPatients = SearchPatientsUseCase(
      cache: patientsCache,
      remote: registryRemote,
      clock: effectiveClock,
      staleAfter: staleAfter,
    );
    final registerPatient = RegisterPatientUseCase(
      cache: patientsCache,
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
    );
    final addFamilyMember = AddFamilyMemberUseCase(
      cache: patientsCache,
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
    );
    final removeFamilyMember = RemoveFamilyMemberUseCase(
      cache: patientsCache,
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
    );
    final assignPrimaryCaregiver = AssignPrimaryCaregiverUseCase(
      cache: patientsCache,
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
    );
    final updateSocialIdentity = UpdateSocialIdentityUseCase(
      cache: patientsCache,
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
    );
    final dischargePatient = DischargePatientUseCase(
      cache: patientsCache,
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
    );
    final readmitPatient = ReadmitPatientUseCase(
      cache: patientsCache,
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
    );
    final admitPatient = AdmitPatientUseCase(
      cache: patientsCache,
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
    );
    final withdrawPatient = WithdrawPatientUseCase(
      cache: patientsCache,
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
    );

    // ── Use cases — Assessment (7) ───────────────────────────────────
    final updateHealthStatus = UpdateHealthStatusUseCase(
      cache: patientsCache,
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
    );
    final updateHousingCondition = UpdateHousingConditionUseCase(
      cache: patientsCache,
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
    );
    final updateEducationalStatus = UpdateEducationalStatusUseCase(
      cache: patientsCache,
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
    );
    final updateSocioEconomicSituation = UpdateSocioEconomicSituationUseCase(
      cache: patientsCache,
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
    );
    final updateWorkAndIncome = UpdateWorkAndIncomeUseCase(
      cache: patientsCache,
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
    );
    final updateCommunitySupportNetwork = UpdateCommunitySupportNetworkUseCase(
      cache: patientsCache,
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
    );
    final updateSocialHealthSummary = UpdateSocialHealthSummaryUseCase(
      cache: patientsCache,
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
    );

    // ── Use cases — Care (3) ─────────────────────────────────────────
    final listAppointments = ListAppointmentsUseCase(
      cache: careCache,
      remote: careRemote,
      clock: effectiveClock,
      staleAfter: staleAfter,
    );
    final registerAppointment = RegisterAppointmentUseCase(
      careCache: careCache,
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
    );
    final updateIntakeInfo = UpdateIntakeInfoUseCase(
      patientsCache: patientsCache,
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
    );

    // ── Use cases — Protection (6) ───────────────────────────────────
    final createReferral = CreateReferralUseCase(
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
    );
    final listReferrals = ListReferralsUseCase(
      cache: protectionCache,
      clock: effectiveClock,
      staleAfter: staleAfter,
    );
    final reportViolation = ReportViolationUseCase(
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
    );
    final listViolationReports = ListViolationReportsUseCase(
      cache: protectionCache,
      clock: effectiveClock,
      staleAfter: staleAfter,
    );
    final fetchPlacementHistory = FetchPlacementHistoryUseCase(
      cache: protectionCache,
      clock: effectiveClock,
      staleAfter: staleAfter,
    );
    final updatePlacementHistory = UpdatePlacementHistoryUseCase(
      patientsCache: patientsCache,
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
    );

    // ── Use cases — Audit (1) ────────────────────────────────────────
    final fetchAuditTrail = FetchAuditTrailUseCase(
      cache: auditCache,
      remote: auditRemote,
      clock: effectiveClock,
      staleAfter: staleAfter,
    );

    // ── Use cases — Lookup (10) ──────────────────────────────────────
    final getLookupTable = GetLookupTableUseCase(
      cache: lookupCache,
      remote: lookupRemote,
      clock: effectiveClock,
      staleAfter: staleAfter,
    );
    final getLookupsBatch = GetLookupsBatchUseCase(
      cache: lookupCache,
      remote: lookupRemote,
      clock: effectiveClock,
      staleAfter: staleAfter,
    );
    final createLookupItem = CreateLookupItemUseCase(
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
    );
    final updateLookupItem = UpdateLookupItemUseCase(
      cache: lookupCache,
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
    );
    final toggleLookupItem = ToggleLookupItemUseCase(
      cache: lookupCache,
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
    );
    final createLookupRequest = CreateLookupRequestUseCase(
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
    );
    final listLookupRequests = ListLookupRequestsUseCase(
      cache: lookupCache,
      remote: lookupRemote,
      clock: effectiveClock,
      staleAfter: staleAfter,
    );
    final findLookupRequestById = FindLookupRequestByIdUseCase(
      cache: lookupCache,
      remote: lookupRemote,
      clock: effectiveClock,
      staleAfter: staleAfter,
    );
    final approveLookupRequest = ApproveLookupRequestUseCase(
      cache: lookupCache,
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
    );
    final rejectLookupRequest = RejectLookupRequestUseCase(
      cache: lookupCache,
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
    );

    // ── Use cases — Health (2) ───────────────────────────────────────
    final checkHealth = CheckHealthUseCase(remote: healthRemote);
    final checkReady = CheckReadyUseCase(remote: healthRemote);

    // ── Sub-facades (7) ──────────────────────────────────────────────
    final registryFacade = RegistryFacade.internal(
      fetchPatient: fetchPatient,
      fetchPatientByPersonId: fetchPatientByPersonId,
      listPatients: listPatients,
      searchPatients: searchPatients,
      registerPatient: registerPatient,
      addFamilyMember: addFamilyMember,
      removeFamilyMember: removeFamilyMember,
      assignPrimaryCaregiver: assignPrimaryCaregiver,
      updateSocialIdentity: updateSocialIdentity,
      dischargePatient: dischargePatient,
      readmitPatient: readmitPatient,
      admitPatient: admitPatient,
      withdrawPatient: withdrawPatient,
    );
    final assessmentFacade = AssessmentFacade.internal(
      updateHealthStatus: updateHealthStatus,
      updateHousingCondition: updateHousingCondition,
      updateEducationalStatus: updateEducationalStatus,
      updateSocioEconomicSituation: updateSocioEconomicSituation,
      updateWorkAndIncome: updateWorkAndIncome,
      updateCommunitySupportNetwork: updateCommunitySupportNetwork,
      updateSocialHealthSummary: updateSocialHealthSummary,
    );
    final careFacade = CareFacade.internal(
      listAppointments: listAppointments,
      registerAppointment: registerAppointment,
      updateIntakeInfo: updateIntakeInfo,
    );
    final protectionFacade = ProtectionFacade.internal(
      createReferral: createReferral,
      listReferrals: listReferrals,
      reportViolation: reportViolation,
      listViolationReports: listViolationReports,
      fetchPlacementHistory: fetchPlacementHistory,
      updatePlacementHistory: updatePlacementHistory,
    );
    final auditFacade = AuditFacade.internal(fetchAuditTrail: fetchAuditTrail);
    final lookupFacade = LookupFacade.internal(
      getLookupTable: getLookupTable,
      getLookupsBatch: getLookupsBatch,
      createLookupItem: createLookupItem,
      updateLookupItem: updateLookupItem,
      toggleLookupItem: toggleLookupItem,
      createLookupRequest: createLookupRequest,
      listLookupRequests: listLookupRequests,
      findLookupRequestById: findLookupRequestById,
      approveLookupRequest: approveLookupRequest,
      rejectLookupRequest: rejectLookupRequest,
    );
    final healthFacade = HealthFacade.internal(
      checkHealth: checkHealth,
      checkReady: checkReady,
    );

    // ── Connectivity wiring (D5 γ) ───────────────────────────────────
    final effectiveConnectivity = connectivity ?? Connectivity();
    final initialResults = await effectiveConnectivity.checkConnectivity();
    final initialOnline = _resultsAreOnline(initialResults);

    // The subscription is bound LATE (after construction) so we can
    // call `triggerDrain` (which uses the wrapper's own logic to pump
    // the drainStream) when the offline → online edge happens. We
    // create the subscription with a placeholder closure first; the
    // closure body captures the constructed instance via `desktop`.
    late SocialCareDesktop desktop;
    final connectivitySub = effectiveConnectivity.onConnectivityChanged.listen((
      results,
    ) {
      final isOnline = _resultsAreOnline(results);
      if (isOnline && !desktop._wasOnline) {
        // Fire-and-forget the drain so the listener stays responsive.
        unawaited(desktop.triggerDrain());
      }
      desktop._wasOnline = isOnline;
    });

    desktop = SocialCareDesktop._(
      registry: registryFacade,
      assessment: assessmentFacade,
      care: careFacade,
      protection: protectionFacade,
      audit: auditFacade,
      lookup: lookupFacade,
      health: healthFacade,
      engine: engine,
      cacheDb: cacheDb,
      syncDb: syncDb,
      connectivity: effectiveConnectivity,
      drainController: drainController,
      connectivitySub: connectivitySub,
      initialOnline: initialOnline,
    );

    return desktop;
  }

  // ── Helpers ────────────────────────────────────────────────────────

  /// Resolves the default file path under `path_provider`'s
  /// `getApplicationDocumentsDirectory()`. Tests that omit
  /// `cacheFilePath` / `syncQueueFilePath` fall through here, which
  /// throws `MissingPluginException` in unit tests (intentional — see
  /// the path_provider gate test in `social_care_desktop_test.dart`).
  static Future<String> _defaultPath(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$fileName';
  }

  /// Maps a file path to a Drift `QueryExecutor`. The literal
  /// `':memory:'` (canonical SQLite in-memory marker) yields
  /// [NativeDatabase.memory()] for tests; any other string is treated
  /// as a real disk path.
  ///
  /// **T1.1 (2026-05-01):** disk-backed databases are opened via
  /// [NativeDatabase.createInBackground], which spawns a dedicated
  /// background isolate that owns the SQLite handle. The main isolate
  /// then communicates with it via `SendPort` — every Drift query runs
  /// off the UI/event-loop thread.
  ///
  /// Honors ADR-021's cited rationale (Drift's first-class multi-isolate
  /// support) which previously was paid-for-but-unused in production.
  /// In-memory databases stay on the calling isolate by design — Drift
  /// has no `createInBackground` for `NativeDatabase.memory()` and tests
  /// rely on synchronous in-isolate state.
  static QueryExecutor _openDriftExecutor(String filePath) {
    if (filePath == _inMemoryMarker) {
      return NativeDatabase.memory();
    }
    return NativeDatabase.createInBackground(File(filePath));
  }

  /// True if any [ConnectivityResult] in the list is non-`none`. The
  /// `connectivity_plus` v7 plugin emits a list per change to support
  /// devices with multiple active interfaces; ANY non-`none` member
  /// counts as online for our trigger.
  static bool _resultsAreOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}
