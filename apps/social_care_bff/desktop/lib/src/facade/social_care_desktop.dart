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
///     at `create()` via [AutoDrainObserver] (D03).
///   * On offline → online edge, fires-and-forgets `engine.triggerDrain()`.
///   * Subscription cancelled by `close()`.
///
/// Path defaults (D3):
///   * Cache: `getApplicationDocumentsDirectory()/app_cache.sqlite`
///   * SyncQueue: `getApplicationDocumentsDirectory()/app_sync_queue.sqlite`
///   * Override via `cacheFilePath` / `syncQueueFilePath`. Use `':memory:'`
///     to spin Drift in-memory databases (tests).
///
/// Composition (D02 + D03):
///   * 7 per-bounded-context builders under `composition/builders/`
///     group the 42 use cases into 7 data classes (`RegistryUseCases`,
///     `AssessmentUseCases`, ...) — added in D02.
///   * `DesktopAssembler` (Builder GoF, D03) orchestrates the composition
///     phases with a fluent API; `create()` is a thin wrapper that maps
///     its named args to `with*()` calls.
///   * `DesktopRuntime` (D03) bundles the 12 fields the facade
///     consumes — every sub-facade getter and lifecycle method delegates
///     to it.
///
/// Cross-link: pumping behaviour lives in
/// `lib/src/sync/engine/pumping_sync_engine.dart` (D01); the offline →
/// online edge detector lives in
/// `lib/src/sync/connectivity/auto_drain_observer.dart` (D03).
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:core_contracts/core_contracts.dart';
import 'package:dio/dio.dart';

import '../sync/_shared/failures.dart';
import '../sync/engine/sync_engine.dart';
import '../use_cases/_shared/clock.dart';
import 'composition/db_executor.dart';
import 'composition/desktop_assembler.dart';
import 'composition/desktop_runtime.dart';
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
  SocialCareDesktop._(this._runtime);

  final DesktopRuntime _runtime;
  bool _closed = false;

  // ── Public sub-facades (delegate to runtime) ─────────────────────────

  RegistryFacade get registry => _runtime.registry;
  AssessmentFacade get assessment => _runtime.assessment;
  CareFacade get care => _runtime.care;
  ProtectionFacade get protection => _runtime.protection;
  AuditFacade get audit => _runtime.audit;
  LookupFacade get lookup => _runtime.lookup;
  HealthFacade get health => _runtime.health;

  // ── Public sync state ──────────────────────────────────────────────

  /// Broadcast stream of [DrainSummary] events — emits one per drain
  /// completion (manual `triggerDrain` or connectivity-restore edge).
  /// Multiple listeners (e.g. sync_detail_panel + home_page indicator)
  /// receive every event.
  Stream<DrainSummary> get drainStream => _runtime.drainController.stream;

  /// Manually triggers a drain pass. Pre-`startSync` this is a no-op
  /// (`Success(processed: 0)`) per D4 α; post-`close` it returns
  /// `Failure(SyncFailure)`.
  ///
  /// The underlying `PumpingSyncEngine` pumps successful drain summaries
  /// onto [drainStream], so manual triggers AND fire-and-forget triggers
  /// from write use cases all surface there.
  Future<Result<DrainSummary>> triggerDrain() {
    if (_closed) {
      return Future.value(
        Failure<DrainSummary>(SyncFailure('SocialCareDesktop closed')),
      );
    }
    return _runtime.engine.triggerDrain();
  }

  // ── Public lifecycle (D4 α) ────────────────────────────────────────

  /// Enables the SyncEngine. Idempotent — calling twice is a no-op.
  /// Call this AFTER login when the auth token becomes available.
  Future<void> startSync() => _runtime.engine.start();

  /// Suspends the SyncEngine. Pending Outbox rows stay queued; subsequent
  /// `triggerDrain` returns `Success(processed: 0)` until `startSync`
  /// is called again.
  Future<void> stopSync() => _runtime.engine.stop();

  /// Releases resources:
  ///   1. Cancels the connectivity subscription.
  ///   2. Closes the SyncEngine (subsequent `triggerDrain` returns Failure).
  ///   3. Closes both Drift databases (cache + sync).
  ///   4. Closes the broadcast `drainController`.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _runtime.connectivityObserver.dispose();
    await _runtime.engine.close();
    try {
      await _runtime.cacheDb.close();
    } catch (_) {}
    try {
      await _runtime.syncDb.close();
    } catch (_) {}
    if (!_runtime.drainController.isClosed) {
      await _runtime.drainController.close();
    }
  }

  // ── Factory (delegates to DesktopAssembler — D03) ───────────────────

  /// Builds the full Desktop BFF instance.
  ///
  /// Resolves file paths via `path_provider` (D3) when not overridden,
  /// then opens both Drift databases, builds 7 remotes via Dio (sharing
  /// one client with `X-Actor-Id` + `Authorization`-via-tokenProvider),
  /// composes 42 use cases via 7 per-context builders (D02), groups them
  /// into 7 sub-facades, and wires the connectivity listener (D5 γ /
  /// D03 [AutoDrainObserver]).
  ///
  /// **Does NOT auto-start the engine** (D4 α). Call `startSync()` after
  /// login.
  ///
  /// Public surface preserved 100% across D03 — same parameters as
  /// before. Internal composition now flows through [DesktopAssembler].
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
    final assembler = DesktopAssembler(
      baseUrl: baseUrl,
      actorId: actorId,
      tokenProvider: tokenProvider,
    ).withStaleAfter(staleAfter);

    if (cacheFilePath != null) assembler.withLocalCache(path: cacheFilePath);
    if (syncQueueFilePath != null) {
      assembler.withSyncQueue(path: syncQueueFilePath);
    }
    if (dio != null) assembler.withDio(dio);
    if (clock != null) assembler.withClock(clock);
    if (connectivity != null) assembler.withConnectivity(connectivity);
    if (executorFactory != null) assembler.withExecutorFactory(executorFactory);

    final runtime = await assembler.build();
    return SocialCareDesktop._(runtime);
  }
}
