/// GoF Builder for the Desktop BFF composition root.
///
/// Replaces the in-line "phase 1 → phase 8" sequence inside
/// `SocialCareDesktop.create()` (post-D02) with a fluent API:
///
/// ```dart
/// final runtime = await DesktopAssembler(
///   baseUrl: '...',
///   actorId: '...',
///   tokenProvider: () => 'token',
/// )
///   .withConnectivity(fakeConnectivity)
///   .withClock(fakeClock)
///   .withExecutorFactory(DriftExecutorFactory.inMemory)
///   .build();
/// ```
///
/// Each `with*()` setter mutates the assembler and returns `this` for
/// chaining. [build] is reusable — every call produces a fresh
/// [DesktopRuntime] with new database, engine, observer, and sub-facade
/// instances. The caller owns the lifecycle of each runtime it builds.
///
/// `SocialCareDesktop.create()` is a thin wrapper around this assembler
/// — the public surface is preserved 100%, but composition is now
/// re-entrant and step-by-step.
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../../cache/_shared/cache_database.dart';
import '../../cache/impls/drift_audit_cache.dart';
import '../../cache/impls/drift_care_cache.dart';
import '../../cache/impls/drift_lookup_cache.dart';
import '../../cache/impls/drift_patients_cache.dart';
import '../../cache/impls/drift_protection_cache.dart';
import '../../remote/_shared/remote_base.dart';
import '../../remote/assessment_remote.dart';
import '../../remote/audit_remote.dart';
import '../../remote/care_remote.dart';
import '../../remote/health_remote.dart';
import '../../remote/lookup_remote.dart';
import '../../remote/protection_remote.dart';
import '../../remote/registry_remote.dart';
import '../../sync/_shared/sync_database.dart';
import '../../sync/connectivity/auto_drain_observer.dart';
import '../../sync/engine/pumping_sync_engine.dart';
import '../../sync/engine/sync_engine.dart';
import '../../sync/outbox/outbox_repository.dart';
import '../../use_cases/_shared/clock.dart';
import '../sub_facades/assessment_facade.dart';
import '../sub_facades/audit_facade.dart';
import '../sub_facades/care_facade.dart';
import '../sub_facades/health_facade.dart';
import '../sub_facades/lookup_facade.dart';
import '../sub_facades/protection_facade.dart';
import '../sub_facades/registry_facade.dart';
import 'builders/assessment_use_cases.dart';
import 'builders/audit_use_cases.dart';
import 'builders/care_use_cases.dart';
import 'builders/health_use_cases.dart';
import 'builders/lookup_use_cases.dart';
import 'builders/protection_use_cases.dart';
import 'builders/registry_use_cases.dart';
import 'db_executor.dart';
import 'desktop_runtime.dart';

/// Fluent builder for [DesktopRuntime].
class DesktopAssembler {
  DesktopAssembler({
    required this.baseUrl,
    required this.actorId,
    required this.tokenProvider,
  });

  final String baseUrl;
  final String actorId;
  final String? Function() tokenProvider;

  String? _cacheFilePath;
  String? _syncQueueFilePath;
  Dio? _dio;
  Clock? _clock;
  Duration _staleAfter = const Duration(minutes: 5);
  Connectivity? _connectivity;
  DriftExecutorFactory _executorFactory = DriftExecutorFactory.production;

  /// Overrides the cache file path. When omitted, [build] falls through
  /// to [defaultDesktopFilePath] (which uses `path_provider`).
  DesktopAssembler withLocalCache({String? path}) {
    _cacheFilePath = path;
    return this;
  }

  /// Overrides the sync-queue file path. When omitted, [build] falls
  /// through to [defaultDesktopFilePath].
  DesktopAssembler withSyncQueue({String? path}) {
    _syncQueueFilePath = path;
    return this;
  }

  /// Injects a pre-built [Dio] client. When omitted, [build]
  /// constructs one via [RemoteBase.buildDio].
  DesktopAssembler withDio(Dio dio) {
    _dio = dio;
    return this;
  }

  /// Injects a [Clock]. Defaults to [SystemClock].
  DesktopAssembler withClock(Clock clock) {
    _clock = clock;
    return this;
  }

  /// Overrides the stale-after duration used by read use cases.
  /// Default is 5 minutes (matches `SocialCareDesktop.create()`).
  DesktopAssembler withStaleAfter(Duration duration) {
    _staleAfter = duration;
    return this;
  }

  /// Injects a [Connectivity] (typically a fake in tests). Defaults
  /// to the real `Connectivity()` plugin instance.
  DesktopAssembler withConnectivity(Connectivity connectivity) {
    _connectivity = connectivity;
    return this;
  }

  /// Injects a [DriftExecutorFactory]. Defaults to
  /// [DriftExecutorFactory.production] (disk-backed background isolate).
  DesktopAssembler withExecutorFactory(DriftExecutorFactory factory) {
    _executorFactory = factory;
    return this;
  }

  /// Builds a fresh [DesktopRuntime].
  ///
  /// Each call produces a new independent runtime — caches, databases,
  /// engine, observer, and sub-facades are all re-instantiated. The
  /// caller is responsible for disposing each runtime it builds.
  ///
  /// Phase order (mirrors the legacy `SocialCareDesktop.create()` body):
  ///   1. Resolve file paths.
  ///   2. Open Drift databases via the executor factory.
  ///   3. Build infra (clock + dio).
  ///   4. Build caches + remotes + outbox.
  ///   5. Build the sync engine + drain controller.
  ///   6. Build use cases via the 7 D02 builders.
  ///   7. Build the 7 sub-facades.
  ///   8. Build the [AutoDrainObserver] over connectivity.
  Future<DesktopRuntime> build() async {
    // Phase 1: Resolve paths.
    //
    // When the in-memory factory is used, the file path is ignored
    // entirely — short-circuit with the `:memory:` sentinel so we
    // never reach `path_provider` (whose platform channel is unwired
    // in unit tests and would throw `MissingPluginException`).
    final isInMemory = identical(
      _executorFactory,
      DriftExecutorFactory.inMemory,
    );
    final cachePath =
        _cacheFilePath ??
        (isInMemory
            ? ':memory:'
            : await defaultDesktopFilePath('app_cache.sqlite'));
    final syncPath =
        _syncQueueFilePath ??
        (isInMemory
            ? ':memory:'
            : await defaultDesktopFilePath('app_sync_queue.sqlite'));

    // Phase 2: Open databases.
    final cacheDb = CacheDatabase(_executorFactory.open(cachePath));
    final syncDb = SyncDatabase(_executorFactory.open(syncPath));

    // Phase 3: Infra (clock + dio).
    final clock = _clock ?? const SystemClock();
    final dio =
        _dio ??
        RemoteBase.buildDio(
          baseUrl: baseUrl,
          actorId: actorId,
          tokenProvider: tokenProvider,
        );

    // Phase 4: Caches + remotes + outbox.
    final patientsCache = DriftPatientsCache(cacheDb, clock: clock);
    final careCache = DriftCareCache(cacheDb, clock: clock);
    final protectionCache = DriftProtectionCache(cacheDb, clock: clock);
    final auditCache = DriftAuditCache(cacheDb, clock: clock);
    final lookupCache = DriftLookupCache(cacheDb, clock: clock);

    final registryRemote = RegistryRemote(dio: dio);
    final assessmentRemote = AssessmentRemote(dio: dio);
    final careRemote = CareRemote(dio: dio);
    final protectionRemote = ProtectionRemote(dio: dio);
    final auditRemote = AuditRemote(dio: dio);
    final lookupRemote = LookupRemote(dio: dio);
    final healthRemote = HealthRemote(dio: dio);

    final outbox = DriftOutboxRepository(syncDb);

    // Phase 5: Sync engine + drain controller.
    final drainController = StreamController<DrainSummary>.broadcast();
    final engine = PumpingSyncEngine(
      outbox: outbox,
      registry: registryRemote,
      assessment: assessmentRemote,
      care: careRemote,
      protection: protectionRemote,
      lookup: lookupRemote,
      drainController: drainController,
    );

    // Phase 6: Use cases (7 builders from D02).
    final registryUseCases = RegistryUseCases.build(
      patientsCache: patientsCache,
      remote: registryRemote,
      outbox: outbox,
      engine: engine,
      clock: clock,
      staleAfter: _staleAfter,
    );
    final assessmentUseCases = AssessmentUseCases.build(
      patientsCache: patientsCache,
      outbox: outbox,
      engine: engine,
      clock: clock,
    );
    final careUseCases = CareUseCases.build(
      careCache: careCache,
      patientsCache: patientsCache,
      remote: careRemote,
      outbox: outbox,
      engine: engine,
      clock: clock,
      staleAfter: _staleAfter,
    );
    final protectionUseCases = ProtectionUseCases.build(
      protectionCache: protectionCache,
      patientsCache: patientsCache,
      outbox: outbox,
      engine: engine,
      clock: clock,
      staleAfter: _staleAfter,
    );
    final auditUseCases = AuditUseCases.build(
      auditCache: auditCache,
      remote: auditRemote,
      clock: clock,
      staleAfter: _staleAfter,
    );
    final lookupUseCases = LookupUseCases.build(
      lookupCache: lookupCache,
      remote: lookupRemote,
      outbox: outbox,
      engine: engine,
      clock: clock,
      staleAfter: _staleAfter,
    );
    final healthUseCases = HealthUseCases.build(remote: healthRemote);

    // Phase 7: Sub-facades.
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

    // Phase 8: Connectivity observer.
    final connectivity = _connectivity ?? Connectivity();
    final connectivityObserver = await AutoDrainObserver.watch(
      engine: engine,
      connectivity: connectivity,
    );

    return DesktopRuntime(
      cacheDb: cacheDb,
      syncDb: syncDb,
      engine: engine,
      connectivityObserver: connectivityObserver,
      drainController: drainController,
      registry: registryFacade,
      assessment: assessmentFacade,
      care: careFacade,
      protection: protectionFacade,
      audit: auditFacade,
      lookup: lookupFacade,
      health: healthFacade,
    );
  }
}
