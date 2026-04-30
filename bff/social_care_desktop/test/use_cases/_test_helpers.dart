/// Shared test scaffolding for A18b-v2 use case tests.
///
/// Builds an in-memory test context with:
///   * Real `CacheDatabase` (5 caches over Drift in-memory).
///   * Real `SyncDatabase` + `DriftOutboxRepository` (Outbox writes are
///     genuinely persisted).
///   * `FakeSyncEngine` (recording stub — see `_fakes/fake_sync_engine.dart`
///     for rationale).
///   * `FakeXBff` instances from `bff/shared/lib/src/testing/` for the
///     7 sub-contracts (Registry, Assessment, Care, Protection, Audit,
///     Lookup, Health).
///
/// Use cases consume these dependencies through constructor injection;
/// tests build them via [TestContext.fresh] and tear them down via
/// `addTearDown(ctx.close)`.
///
/// IMPORTANT (RED phase): the use case classes do NOT exist yet. The
/// `import` lines marked `uri_does_not_exist` fail — that is the
/// intended RED signal. W1 implements them under
/// `lib/src/use_cases/<bounded_context>/`.
///
/// REGRA #2 — Cache contract refactor (Option a from STATE.md):
///   Tests assume A17 cache contracts return `Cached<T>` wrappers
///   (envelope: `{ T dto; DateTime cachedAt; int version; }`) instead
///   of bare DTOs. W1 must refactor the 5 cache contracts + Drift
///   impls + existing A17 cache tests to honor this. If W1 chooses a
///   different option (b: side-channel `findByIdWithMeta`, c: row
///   reader), they MUST update these tests with documented justification
///   instead of cheating around the staleness check.
library;

import 'package:core_contracts/core_contracts.dart';
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

// ── Use case shared infrastructure (RED — does not exist yet) ─────────
// ignore: uri_does_not_exist, unused_import
import 'package:social_care_desktop/src/use_cases/_shared/cached.dart';
// ignore: uri_does_not_exist, unused_import
import 'package:social_care_desktop/src/use_cases/_shared/clock.dart';
// ignore: uri_does_not_exist, unused_import
import 'package:social_care_desktop/src/use_cases/_shared/use_case_failures.dart';

import '_fakes/fake_sync_engine.dart';

export 'package:social_care_desktop/social_care_desktop.dart';
// ignore: implementation_imports
export 'package:social_care_desktop/src/cache/_shared/cache_database.dart';
// ignore: implementation_imports
export 'package:social_care_desktop/src/sync/_shared/sync_database.dart';
// ignore: implementation_imports
export 'package:social_care_desktop/src/sync/outbox/outbox_repository.dart';

// ignore: uri_does_not_exist
export 'package:social_care_desktop/src/use_cases/_shared/cached.dart';
// ignore: uri_does_not_exist
export 'package:social_care_desktop/src/use_cases/_shared/clock.dart';
// ignore: uri_does_not_exist
export 'package:social_care_desktop/src/use_cases/_shared/use_case_failures.dart';

export '_fakes/fake_sync_engine.dart';

/// Test context bundling all dependencies needed by the 42 use cases.
class TestContext {
  TestContext._({
    required this.cacheDb,
    required this.syncDb,
    required this.patientsCache,
    required this.careCache,
    required this.protectionCache,
    required this.auditCache,
    required this.lookupCache,
    required this.outbox,
    required this.fakeEngine,
    required this.fakeRegistry,
    required this.fakeAssessment,
    required this.fakeCare,
    required this.fakeProtection,
    required this.fakeAudit,
    required this.fakeLookup,
    required this.fakeHealth,
    required this.fakeClock,
  });

  /// Spins up a fresh, isolated context. Each test should call
  /// `addTearDown(ctx.close)` to release Drift resources.
  static TestContext fresh({DateTime? now}) {
    final cacheDb = CacheDatabase(NativeDatabase.memory());
    final syncDb = SyncDatabase(NativeDatabase.memory());
    final fakeClock = FakeClock(now ?? DateTime.utc(2026, 4, 30, 12));
    return TestContext._(
      cacheDb: cacheDb,
      syncDb: syncDb,
      patientsCache: DriftPatientsCache(cacheDb, now: fakeClock.now),
      careCache: DriftCareCache(cacheDb, now: fakeClock.now),
      protectionCache: DriftProtectionCache(cacheDb, now: fakeClock.now),
      auditCache: DriftAuditCache(cacheDb, now: fakeClock.now),
      lookupCache: DriftLookupCache(cacheDb, now: fakeClock.now),
      outbox: DriftOutboxRepository(syncDb),
      fakeEngine: FakeSyncEngine(),
      fakeRegistry: FakeRegistryBff(),
      fakeAssessment: FakeAssessmentBff(),
      fakeCare: FakeCareBff(),
      fakeProtection: FakeProtectionBff(),
      fakeAudit: FakeAuditBff(),
      fakeLookup: FakeLookupBff(),
      fakeHealth: _FakeHealthBff(),
      fakeClock: fakeClock,
    );
  }

  final CacheDatabase cacheDb;
  final SyncDatabase syncDb;

  // Caches (real, Drift in-memory)
  final PatientsCache patientsCache;
  final CareCache careCache;
  final ProtectionCache protectionCache;
  final AuditCache auditCache;
  final LookupCache lookupCache;

  // Outbox (real, Drift in-memory)
  final OutboxRepository outbox;

  // Fakes
  final FakeSyncEngine fakeEngine;
  final FakeRegistryBff fakeRegistry;
  final FakeAssessmentBff fakeAssessment;
  final FakeCareBff fakeCare;
  final FakeProtectionBff fakeProtection;
  final FakeAuditBff fakeAudit;
  final FakeLookupBff fakeLookup;
  final HealthContract fakeHealth;
  final FakeClock fakeClock;

  Future<void> close() async {
    try {
      await cacheDb.close();
    } catch (_) {}
    try {
      await syncDb.close();
    } catch (_) {}
  }
}

/// Programmable health-contract fake. (No `FakeHealthBff` exists in
/// `bff/shared/`, so we ship a minimal local one — Health is purely a
/// passthrough.)
class _FakeHealthBff implements HealthContract {
  Result<void> healthResult = const Success(null);
  Result<void> readyResult = const Success(null);
  int healthCallCount = 0;
  int readyCallCount = 0;

  @override
  Future<Result<void>> checkHealth() async {
    healthCallCount++;
    return healthResult;
  }

  @override
  Future<Result<void>> checkReady() async {
    readyCallCount++;
    return readyResult;
  }
}

/// Programmable clock for tests. Use cases inject `Clock` (RED — not
/// yet defined) so their `_isStale` check uses [now] without colliding
/// with wall-clock drift in CI.
///
/// W1 will create `Clock` at `lib/src/use_cases/_shared/clock.dart`
/// with a single method: `DateTime now()`.
class FakeClock implements Clock {
  FakeClock(this._now);
  DateTime _now;

  @override
  DateTime now() => _now;

  /// Advances the fake clock. Tests use this to simulate stale cache.
  void advance(Duration delta) {
    _now = _now.add(delta);
  }

  /// Sets the clock to an absolute time. Useful for cache-stale axes.
  void setTo(DateTime t) {
    _now = t;
  }
}

/// Convenience: cast for tests reading `_FakeHealthBff` shape.
T asHealthFake<T extends HealthContract>(HealthContract h) => h as T;
