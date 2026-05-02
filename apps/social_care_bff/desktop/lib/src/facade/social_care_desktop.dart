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
///
/// Composition (D02):
///   * 7 per-bounded-context builders under `composition/builders/`
///     group the 42 use cases into 7 data classes (`RegistryUseCases`,
///     `AssessmentUseCases`, ...). Adding a new use case touches the
///     bundle + the relevant sub-facade — `create()` itself is stable.
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:core_contracts/core_contracts.dart';
import 'package:dio/dio.dart';

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
import '../sync/engine/pumping_sync_engine.dart';
import '../sync/engine/sync_engine.dart';
import '../sync/outbox/outbox_repository.dart';
import '../use_cases/_shared/clock.dart';
import 'composition/builders/assessment_use_cases.dart';
import 'composition/builders/audit_use_cases.dart';
import 'composition/builders/care_use_cases.dart';
import 'composition/builders/health_use_cases.dart';
import 'composition/builders/lookup_use_cases.dart';
import 'composition/builders/protection_use_cases.dart';
import 'composition/builders/registry_use_cases.dart';
import 'composition/connectivity_helpers.dart';
import 'composition/db_executor.dart';
import 'sub_facades/assessment_facade.dart';
import 'sub_facades/audit_facade.dart';
import 'sub_facades/care_facade.dart';
import 'sub_facades/health_facade.dart';
import 'sub_facades/lookup_facade.dart';
import 'sub_facades/protection_facade.dart';
import 'sub_facades/registry_facade.dart';

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
  /// The underlying [PumpingSyncEngine] pumps successful drain summaries
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

  // ── Factory (D3 + D4 + D5 + D02 wired) ────────────────────────────

  /// Builds the full Desktop BFF instance.
  ///
  /// Resolves file paths via `path_provider` (D3) when not overridden,
  /// then opens both Drift databases, builds 7 remotes via Dio (sharing
  /// one client with `X-Actor-Id` + `Authorization`-via-tokenProvider),
  /// composes 42 use cases via 7 per-context builders (D02), groups them
  /// into 7 sub-facades, and wires the connectivity listener (D5 γ).
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
    DriftExecutorFactory? executorFactory,
  }) async {
    final factory = executorFactory ?? DriftExecutorFactory.production;

    // ── Path resolution (D3) ─────────────────────────────────────────
    final resolvedCachePath =
        cacheFilePath ?? await defaultDesktopFilePath('app_cache.sqlite');
    final resolvedSyncPath =
        syncQueueFilePath ??
        await defaultDesktopFilePath('app_sync_queue.sqlite');

    // ── Database open ────────────────────────────────────────────────
    final cacheDb = CacheDatabase(factory.open(resolvedCachePath));
    final syncDb = SyncDatabase(factory.open(resolvedSyncPath));

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

    // ── Outbox + remotes (7) ─────────────────────────────────────────
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

    // ── Sync engine (pumping subclass — see PumpingSyncEngine) ───────
    final engine = PumpingSyncEngine(
      outbox: outbox,
      registry: registryRemote,
      assessment: assessmentRemote,
      care: careRemote,
      protection: protectionRemote,
      lookup: lookupRemote,
      drainController: drainController,
    );

    // ── Use case bundles (D02 — 7 per-bounded-context builders) ──────
    final registryUseCases = RegistryUseCases.build(
      patientsCache: patientsCache,
      remote: registryRemote,
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
      staleAfter: staleAfter,
    );
    final assessmentUseCases = AssessmentUseCases.build(
      patientsCache: patientsCache,
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
    );
    final careUseCases = CareUseCases.build(
      careCache: careCache,
      patientsCache: patientsCache,
      remote: careRemote,
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
      staleAfter: staleAfter,
    );
    final protectionUseCases = ProtectionUseCases.build(
      protectionCache: protectionCache,
      patientsCache: patientsCache,
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
      staleAfter: staleAfter,
    );
    final auditUseCases = AuditUseCases.build(
      auditCache: auditCache,
      remote: auditRemote,
      clock: effectiveClock,
      staleAfter: staleAfter,
    );
    final lookupUseCases = LookupUseCases.build(
      lookupCache: lookupCache,
      remote: lookupRemote,
      outbox: outbox,
      engine: engine,
      clock: effectiveClock,
      staleAfter: staleAfter,
    );
    final healthUseCases = HealthUseCases.build(remote: healthRemote);

    // ── Sub-facades (7) ──────────────────────────────────────────────
    final registryFacade = RegistryFacade.internal(useCases: registryUseCases);
    final assessmentFacade = AssessmentFacade.internal(
      useCases: assessmentUseCases,
    );
    final careFacade = CareFacade.internal(useCases: careUseCases);
    final protectionFacade = ProtectionFacade.internal(
      useCases: protectionUseCases,
    );
    final auditFacade = AuditFacade.internal(useCases: auditUseCases);
    final lookupFacade = LookupFacade.internal(useCases: lookupUseCases);
    final healthFacade = HealthFacade.internal(useCases: healthUseCases);

    // ── Connectivity wiring (D5 γ) ───────────────────────────────────
    final effectiveConnectivity = connectivity ?? Connectivity();
    final initialResults = await effectiveConnectivity.checkConnectivity();
    final initialOnline = resultsAreOnline(initialResults);

    // The subscription is bound LATE (after construction) so we can
    // call `triggerDrain` (which uses the wrapper's own logic to pump
    // the drainStream) when the offline → online edge happens. We
    // create the subscription with a placeholder closure first; the
    // closure body captures the constructed instance via `desktop`.
    late SocialCareDesktop desktop;
    final connectivitySub = effectiveConnectivity.onConnectivityChanged.listen((
      results,
    ) {
      final isOnline = resultsAreOnline(results);
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
}
