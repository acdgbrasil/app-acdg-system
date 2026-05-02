/// Shared scaffolding for D02 builder tests (`composition/builders/*`).
///
/// 7 builders group the 42 use cases per bounded context. Each builder
/// is a data class with a `build()` static factory that constructs all
/// its use cases from a small set of shared dependencies (Cache, Remote,
/// Outbox, SyncEngine, Clock, Duration). These tests verify the
/// **structural contract** of those builders — that `build()` returns a
/// non-null instance with every field populated and typed correctly.
///
/// They explicitly do NOT re-test use case behaviour — that is the
/// territory of the existing 22+ tests under `test/use_cases/` (450
/// GREEN baseline preserved). A builder is just a composition root for
/// 1-13 use cases; the only failure modes worth testing are:
///   1. `build()` throws (broken composition) — caught by NPE on field
///      access in test #1.
///   2. A field is wired with the wrong type (e.g. `fetchPatient` was
///      assigned to `ListPatientsUseCase` by mistake) — caught by
///      `isA<T>` in test #2.
///   3. `build()` returns the SAME instance across calls (broken
///      factory — would pin all callers to a singleton) — caught by
///      `identical(...)` in test #3.
///
/// ── Reuse of existing fakes ──────────────────────────────────────────
/// This file does NOT duplicate fakes; it leans on:
///   * `FakeRegistryBff` / `FakeAssessmentBff` / `FakeCareBff` /
///     `FakeProtectionBff` / `FakeAuditBff` / `FakeLookupBff` from
///     `bff/contracts/lib/src/testing/` — implement the 6 remote
///     sub-contracts.
///   * `FakeSyncEngine` from `test/use_cases/_fakes/fake_sync_engine.dart`
///     — same one A18b uses; bypasses the dispatch chain.
///   * Real Drift in-memory caches (`DriftPatientsCache`, etc.) over
///     `CacheDatabase(NativeDatabase.memory())` — same pattern as
///     `test/use_cases/_test_helpers.dart`.
///   * Real `DriftOutboxRepository` over `SyncDatabase(NativeDatabase.memory())`.
///   * Local `_FakeHealthBff` — `bff/contracts/` doesn't ship one
///     (Health is a passthrough), so we re-declare it here. Identical
///     shape to the one in `test/use_cases/_test_helpers.dart`.
///   * Local `BuilderFakeClock` — same shape as the FakeClock in
///     `test/use_cases/_test_helpers.dart` and `test/facade/_test_helpers.dart`,
///     re-declared to keep this builder-specific helper self-contained
///     (avoids a cross-folder import that would couple two test folders).
///
/// ── REGRA #2 — abstract vs concrete remote types ─────────────────────
/// The D02 ticket spec (000-request.md, lines 54-60) lists
/// `required RegistryRemote remote` (concrete) on `build()`. The
/// existing use case constructors, however, take the **abstract**
/// `RegistryContract` (and similar). Since `RegistryRemote implements
/// RegistryContract`, both work at the call site — but ONLY the
/// abstract form lets these tests pass `FakeRegistryBff` (which
/// implements the contract, not the concrete remote).
///
/// W0.5 (this file) ASSUMES the builder will accept the abstract
/// contract as `remote:` (parametric — matches how use cases already
/// declare their dependency, supports fakes). W1 has two paths:
///
///   (a) Implement builder with abstract types — these tests pass.
///       This is the recommended path: it keeps DI uniform with use
///       cases and avoids forcing test code to instantiate real
///       `RegistryRemote(dio: Dio())` (which would require Dio +
///       network setup just to verify a struct has 13 fields).
///
///   (b) Implement builder with concrete remote types — these tests
///       fail to compile. W1 must surface this in W2-CODE-REVIEW.md
///       with rationale, and update these tests to construct real
///       `RegistryRemote(dio: Dio())` etc. (which still works without
///       a network — Dio is a pure HTTP client that never dials until
///       a method is invoked).
///
/// IMPORTANT (RED phase): the imports below resolve to files W1 has
/// not created yet — `lib/src/facade/composition/builders/*.dart`. Until
/// then this helper file fails to analyze. That is the intended RED
/// signal.
library;

import 'package:drift/native.dart';
import 'package:shared/shared.dart';
import 'package:social_care_desktop/social_care_desktop.dart';
// ignore: implementation_imports
import 'package:social_care_desktop/src/cache/_shared/cache_database.dart';
// ignore: implementation_imports
import 'package:social_care_desktop/src/cache/impls/drift_audit_cache.dart';
// ignore: implementation_imports
import 'package:social_care_desktop/src/cache/impls/drift_care_cache.dart';
// ignore: implementation_imports
import 'package:social_care_desktop/src/cache/impls/drift_lookup_cache.dart';
// ignore: implementation_imports
import 'package:social_care_desktop/src/cache/impls/drift_patients_cache.dart';
// ignore: implementation_imports
import 'package:social_care_desktop/src/cache/impls/drift_protection_cache.dart';
// ignore: implementation_imports
import 'package:social_care_desktop/src/sync/_shared/sync_database.dart';
// ignore: implementation_imports
import 'package:social_care_desktop/src/sync/outbox/outbox_repository.dart';

// ── Reuse the SyncEngine fake from A18b's fakes folder ───────────────
// ignore: implementation_imports
import '../../../use_cases/_fakes/fake_sync_engine.dart';

export 'package:social_care_desktop/social_care_desktop.dart';
// ignore: implementation_imports
export 'package:social_care_desktop/src/cache/_shared/cache_database.dart';
// ignore: implementation_imports
export 'package:social_care_desktop/src/sync/_shared/sync_database.dart';
// ignore: implementation_imports
export 'package:social_care_desktop/src/sync/outbox/outbox_repository.dart';

// ignore: implementation_imports
export '../../../use_cases/_fakes/fake_sync_engine.dart';

/// Bundle of shared dependencies a builder's `build()` factory consumes.
///
/// Each test calls [BuilderDeps.fresh] in `setUp`, then `addTearDown`
/// to release the two Drift databases. The fakes themselves are stateless
/// (or trivially stateful — `triggerDrainCount`) and need no teardown.
class BuilderDeps {
  BuilderDeps._({
    required this.cacheDb,
    required this.syncDb,
    required this.patientsCache,
    required this.careCache,
    required this.protectionCache,
    required this.auditCache,
    required this.lookupCache,
    required this.outbox,
    required this.engine,
    required this.registryRemote,
    required this.assessmentRemote,
    required this.careRemote,
    required this.protectionRemote,
    required this.auditRemote,
    required this.lookupRemote,
    required this.healthRemote,
    required this.clock,
    required this.staleAfter,
  });

  /// Spins up a fresh, isolated dep bundle. Each builder test should
  /// chain `addTearDown(deps.close)` so the in-memory Drift instances
  /// are released between tests (avoids Isolate-pool resource leaks
  /// in long suite runs).
  static BuilderDeps fresh({DateTime? now, Duration? staleAfter}) {
    final cacheDb = CacheDatabase(NativeDatabase.memory());
    final syncDb = SyncDatabase(NativeDatabase.memory());
    final clock = BuilderFakeClock(now ?? DateTime.utc(2026, 5, 1, 12));
    return BuilderDeps._(
      cacheDb: cacheDb,
      syncDb: syncDb,
      patientsCache: DriftPatientsCache(cacheDb, clock: clock),
      careCache: DriftCareCache(cacheDb, clock: clock),
      protectionCache: DriftProtectionCache(cacheDb, clock: clock),
      auditCache: DriftAuditCache(cacheDb, clock: clock),
      lookupCache: DriftLookupCache(cacheDb, clock: clock),
      outbox: DriftOutboxRepository(syncDb),
      engine: FakeSyncEngine(),
      registryRemote: FakeRegistryBff(),
      assessmentRemote: FakeAssessmentBff(),
      careRemote: FakeCareBff(),
      protectionRemote: FakeProtectionBff(),
      auditRemote: FakeAuditBff(),
      lookupRemote: FakeLookupBff(),
      healthRemote: _FakeHealthBff(),
      clock: clock,
      staleAfter: staleAfter ?? const Duration(minutes: 1),
    );
  }

  final CacheDatabase cacheDb;
  final SyncDatabase syncDb;

  final PatientsCache patientsCache;
  final CareCache careCache;
  final ProtectionCache protectionCache;
  final AuditCache auditCache;
  final LookupCache lookupCache;

  final OutboxRepository outbox;
  final FakeSyncEngine engine;

  // Remote fakes — typed as the abstract sub-contract because that is
  // what the use case constructors require. See the REGRA #2 note in
  // this file's library doc for the abstract-vs-concrete trade-off.
  final RegistryContract registryRemote;
  final AssessmentContract assessmentRemote;
  final CareContract careRemote;
  final ProtectionContract protectionRemote;
  final AuditContract auditRemote;
  final LookupContract lookupRemote;
  final HealthContract healthRemote;

  final Clock clock;
  final Duration staleAfter;

  Future<void> close() async {
    try {
      await cacheDb.close();
    } catch (_) {}
    try {
      await syncDb.close();
    } catch (_) {}
  }
}

/// Programmable clock — same shape as the `FakeClock` declared in
/// `test/use_cases/_test_helpers.dart` and `test/facade/_test_helpers.dart`.
/// Local copy keeps the builder helper self-contained so we don't pull
/// in either of those neighbour helper files (they bundle a lot more
/// than these tests need).
class BuilderFakeClock implements Clock {
  BuilderFakeClock(this._now);
  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration delta) {
    _now = _now.add(delta);
  }

  void setTo(DateTime t) {
    _now = t;
  }
}

/// Programmable health-contract fake. (No `FakeHealthBff` exists in
/// `bff/contracts/lib/src/testing/`, so we ship a minimal local one —
/// Health is purely a passthrough.) Identical shape to the one in
/// `test/use_cases/_test_helpers.dart`.
class _FakeHealthBff implements HealthContract {
  @override
  Future<Result<void>> checkHealth() async => const Success(null);

  @override
  Future<Result<void>> checkReady() async => const Success(null);
}
