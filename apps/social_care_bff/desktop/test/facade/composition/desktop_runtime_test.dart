/// RED-phase tests for `DesktopRuntime` (D03 W0.5).
///
/// `DesktopRuntime` is an immutable data class produced by
/// `DesktopAssembler.build()`. It bundles the 12 fields that
/// `SocialCareDesktop._()` previously took as 14 individual constructor
/// parameters (post-D02). After D03, `SocialCareDesktop._(this._runtime)`
/// takes ONE parameter — the runtime — and delegates to its fields.
///
/// ── Surface under test (per ticket D03 000-request.md, lines 26-56) ─
///
/// ```dart
/// class DesktopRuntime {
///   const DesktopRuntime({
///     required this.cacheDb,
///     required this.syncDb,
///     required this.engine,
///     required this.connectivityObserver,
///     required this.drainController,
///     required this.registry,
///     required this.assessment,
///     required this.care,
///     required this.protection,
///     required this.audit,
///     required this.lookup,
///     required this.health,
///   });
///
///   final CacheDatabase cacheDb;
///   final SyncDatabase syncDb;
///   final SyncEngine engine;
///   final AutoDrainObserver connectivityObserver;
///   final StreamController<DrainSummary> drainController;
///
///   final RegistryFacade registry;
///   final AssessmentFacade assessment;
///   final CareFacade care;
///   final ProtectionFacade protection;
///   final AuditFacade audit;
///   final LookupFacade lookup;
///   final HealthFacade health;
/// }
/// ```
///
/// ── Test contract ───────────────────────────────────────────────────
///
/// The data class has no behavior — every test exercises structural
/// guarantees:
///
///   1. Constructor accepts all 12 named parameters as `required`. Every
///      field is non-null after construction.
///   2. Each field has the expected concrete static type. (Catches the
///      "engine got assigned to drainController" class of refactor bugs
///      that no compiler would surface if both ends had `dynamic`.)
///   3. Two distinct `DesktopRuntime` instances can be constructed
///      independently (no hidden static state). Field identity is
///      preserved through the constructor (`expect(r.engine, same(eng))`).
///
/// ── Why we don't go through `DesktopAssembler` here ─────────────────
///
/// The runtime is a data class — its contract (12 fields, 12 types) is
/// independent of the assembler that populates it. Going through
/// `DesktopAssembler.build()` would conflate the two contracts and
/// double-test the assembler. Tests in
/// `desktop_assembler_test.dart` cover the assembler → runtime path;
/// these three tests cover the runtime → fields path.
///
/// ── Where the dependencies come from ────────────────────────────────
///
/// The 12 fields fall into 3 groups:
///
///   a) Drift databases + StreamController — straightforward to build
///      with `NativeDatabase.memory()` and `StreamController.broadcast()`.
///   b) `SyncEngine` — we use the existing `FakeSyncEngine` from
///      `test/use_cases/_fakes/`.
///   c) `AutoDrainObserver` — we build via its `watch()` static factory
///      with a `FakeConnectivity` + the fake engine. (D03 — this also
///      indirectly verifies the observer integrates with the runtime.)
///   d) 7 sub-facades — each has a `XxxFacade.internal(useCases:)` ctor.
///      We construct each using the per-context `XxxUseCases.build(...)`
///      from D02 plus the deps bundle from `_builders_test_helpers.dart`.
///
/// IMPORTANT (RED phase): the imports below resolve to files W1 has
/// not created yet — `desktop_runtime.dart` and `auto_drain_observer.dart`.
/// Until then this test file fails to analyze. That is the intended
/// RED signal.
library;

import 'dart:async';

import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'package:social_care_desktop/social_care_desktop.dart';
// ignore: implementation_imports
import 'package:social_care_desktop/src/cache/_shared/cache_database.dart';
// ignore: implementation_imports
import 'package:social_care_desktop/src/sync/_shared/sync_database.dart';

// ── Builders (D02 — present) ────────────────────────────────────────
// ignore: implementation_imports
import 'package:social_care_desktop/src/facade/composition/builders/assessment_use_cases.dart';
// ignore: implementation_imports
import 'package:social_care_desktop/src/facade/composition/builders/audit_use_cases.dart';
// ignore: implementation_imports
import 'package:social_care_desktop/src/facade/composition/builders/care_use_cases.dart';
// ignore: implementation_imports
import 'package:social_care_desktop/src/facade/composition/builders/health_use_cases.dart';
// ignore: implementation_imports
import 'package:social_care_desktop/src/facade/composition/builders/lookup_use_cases.dart';
// ignore: implementation_imports
import 'package:social_care_desktop/src/facade/composition/builders/protection_use_cases.dart';
// ignore: implementation_imports
import 'package:social_care_desktop/src/facade/composition/builders/registry_use_cases.dart';

// ── Sub-facades (D02 — present) ─────────────────────────────────────
// ignore: implementation_imports
import 'package:social_care_desktop/src/facade/sub_facades/assessment_facade.dart';
// ignore: implementation_imports
import 'package:social_care_desktop/src/facade/sub_facades/audit_facade.dart';
// ignore: implementation_imports
import 'package:social_care_desktop/src/facade/sub_facades/care_facade.dart';
// ignore: implementation_imports
import 'package:social_care_desktop/src/facade/sub_facades/health_facade.dart';
// ignore: implementation_imports
import 'package:social_care_desktop/src/facade/sub_facades/lookup_facade.dart';
// ignore: implementation_imports
import 'package:social_care_desktop/src/facade/sub_facades/protection_facade.dart';
// ignore: implementation_imports
import 'package:social_care_desktop/src/facade/sub_facades/registry_facade.dart';

// ── D03 NEW — RED until W1 lands ────────────────────────────────────
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/facade/composition/desktop_runtime.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/sync/connectivity/auto_drain_observer.dart';

import 'builders/_builders_test_helpers.dart';
import '../_fakes/fake_connectivity.dart';

void main() {
  /// Builds the 12 fields of a `DesktopRuntime` using the same fakes the
  /// rest of the desktop test-suite uses. Returns the runtime + a tear-
  /// down hook for the disposable parts (databases, observer, controller,
  /// connectivity fake).
  Future<({DesktopRuntime runtime, Future<void> Function() teardown})>
  buildRuntime() async {
    final deps = BuilderDeps.fresh();
    final fakeConnectivity = FakeConnectivity();

    final observer = await AutoDrainObserver.watch(
      engine: deps.engine,
      connectivity: fakeConnectivity,
    );

    final drainController = StreamController<DrainSummary>.broadcast();

    // 7 sub-facades via the D02 builders + .internal() ctors.
    final registryFacade = RegistryFacade.internal(
      useCases: RegistryUseCases.build(
        patientsCache: deps.patientsCache,
        remote: deps.registryRemote,
        outbox: deps.outbox,
        engine: deps.engine,
        clock: deps.clock,
        staleAfter: deps.staleAfter,
      ),
    );
    final assessmentFacade = AssessmentFacade.internal(
      useCases: AssessmentUseCases.build(
        patientsCache: deps.patientsCache,
        outbox: deps.outbox,
        engine: deps.engine,
        clock: deps.clock,
      ),
    );
    final careFacade = CareFacade.internal(
      useCases: CareUseCases.build(
        careCache: deps.careCache,
        patientsCache: deps.patientsCache,
        remote: deps.careRemote,
        outbox: deps.outbox,
        engine: deps.engine,
        clock: deps.clock,
        staleAfter: deps.staleAfter,
      ),
    );
    final protectionFacade = ProtectionFacade.internal(
      useCases: ProtectionUseCases.build(
        protectionCache: deps.protectionCache,
        patientsCache: deps.patientsCache,
        outbox: deps.outbox,
        engine: deps.engine,
        clock: deps.clock,
        staleAfter: deps.staleAfter,
      ),
    );
    final auditFacade = AuditFacade.internal(
      useCases: AuditUseCases.build(
        auditCache: deps.auditCache,
        remote: deps.auditRemote,
        clock: deps.clock,
        staleAfter: deps.staleAfter,
      ),
    );
    final lookupFacade = LookupFacade.internal(
      useCases: LookupUseCases.build(
        lookupCache: deps.lookupCache,
        remote: deps.lookupRemote,
        outbox: deps.outbox,
        engine: deps.engine,
        clock: deps.clock,
        staleAfter: deps.staleAfter,
      ),
    );
    final healthFacade = HealthFacade.internal(
      useCases: HealthUseCases.build(remote: deps.healthRemote),
    );

    final runtime = DesktopRuntime(
      cacheDb: deps.cacheDb,
      syncDb: deps.syncDb,
      engine: deps.engine,
      connectivityObserver: observer,
      drainController: drainController,
      registry: registryFacade,
      assessment: assessmentFacade,
      care: careFacade,
      protection: protectionFacade,
      audit: auditFacade,
      lookup: lookupFacade,
      health: healthFacade,
    );

    return (
      runtime: runtime,
      teardown: () async {
        await observer.dispose();
        if (!drainController.isClosed) {
          await drainController.close();
        }
        await fakeConnectivity.close();
        await deps.close();
      },
    );
  }

  group('DesktopRuntime — construction & non-null fields', () {
    test('all 12 required fields populated and non-null', () async {
      final ctx = await buildRuntime();
      addTearDown(ctx.teardown);
      final r = ctx.runtime;

      // Infrastructure (5)
      expect(r.cacheDb, isNotNull);
      expect(r.syncDb, isNotNull);
      expect(r.engine, isNotNull);
      expect(r.connectivityObserver, isNotNull);
      expect(r.drainController, isNotNull);

      // Sub-facades (7)
      expect(r.registry, isNotNull);
      expect(r.assessment, isNotNull);
      expect(r.care, isNotNull);
      expect(r.protection, isNotNull);
      expect(r.audit, isNotNull);
      expect(r.lookup, isNotNull);
      expect(r.health, isNotNull);
    });
  });

  group('DesktopRuntime — field static types', () {
    test(
      'each field has the contract-mandated static type',
      () async {
        final ctx = await buildRuntime();
        addTearDown(ctx.teardown);
        final r = ctx.runtime;

        // Infrastructure
        expect(r.cacheDb, isA<CacheDatabase>());
        expect(r.syncDb, isA<SyncDatabase>());
        expect(r.engine, isA<SyncEngine>());
        expect(r.connectivityObserver, isA<AutoDrainObserver>());
        expect(r.drainController, isA<StreamController<DrainSummary>>());

        // Sub-facades — abstract type identity (caller-visible).
        expect(r.registry, isA<RegistryFacade>());
        expect(r.assessment, isA<AssessmentFacade>());
        expect(r.care, isA<CareFacade>());
        expect(r.protection, isA<ProtectionFacade>());
        expect(r.audit, isA<AuditFacade>());
        expect(r.lookup, isA<LookupFacade>());
        expect(r.health, isA<HealthFacade>());
      },
    );
  });

  group('DesktopRuntime — instance independence', () {
    test(
      'two distinct runtimes hold independent references (no hidden state)',
      () async {
        final ctxA = await buildRuntime();
        addTearDown(ctxA.teardown);
        final ctxB = await buildRuntime();
        addTearDown(ctxB.teardown);

        // Different runtime objects.
        expect(identical(ctxA.runtime, ctxB.runtime), isFalse);

        // Probe a representative field from each layer (infra + facade).
        // Each runtime got its own deps from a fresh BuilderDeps, so
        // identity must NOT match across runtimes — proves there is no
        // accidental static caching inside DesktopRuntime.
        expect(identical(ctxA.runtime.cacheDb, ctxB.runtime.cacheDb), isFalse);
        expect(identical(ctxA.runtime.engine, ctxB.runtime.engine), isFalse);
        expect(
          identical(ctxA.runtime.registry, ctxB.runtime.registry),
          isFalse,
        );
        expect(identical(ctxA.runtime.health, ctxB.runtime.health), isFalse);
      },
    );

    test(
      'constructor preserves field identity (no copy, no wrap)',
      () async {
        // Build dependencies first so we can assert pointer identity.
        final deps = BuilderDeps.fresh();
        addTearDown(deps.close);
        final fakeConnectivity = FakeConnectivity();
        addTearDown(fakeConnectivity.close);

        final observer = await AutoDrainObserver.watch(
          engine: deps.engine,
          connectivity: fakeConnectivity,
        );
        addTearDown(observer.dispose);

        final drainController =
            StreamController<DrainSummary>.broadcast();
        addTearDown(drainController.close);

        final registryFacade = RegistryFacade.internal(
          useCases: RegistryUseCases.build(
            patientsCache: deps.patientsCache,
            remote: deps.registryRemote,
            outbox: deps.outbox,
            engine: deps.engine,
            clock: deps.clock,
            staleAfter: deps.staleAfter,
          ),
        );

        // Use placeholders for the 6 other facades — only Registry is
        // probed for identity below.
        final assessmentFacade = AssessmentFacade.internal(
          useCases: AssessmentUseCases.build(
            patientsCache: deps.patientsCache,
            outbox: deps.outbox,
            engine: deps.engine,
            clock: deps.clock,
          ),
        );
        final careFacade = CareFacade.internal(
          useCases: CareUseCases.build(
            careCache: deps.careCache,
            patientsCache: deps.patientsCache,
            remote: deps.careRemote,
            outbox: deps.outbox,
            engine: deps.engine,
            clock: deps.clock,
            staleAfter: deps.staleAfter,
          ),
        );
        final protectionFacade = ProtectionFacade.internal(
          useCases: ProtectionUseCases.build(
            protectionCache: deps.protectionCache,
            patientsCache: deps.patientsCache,
            outbox: deps.outbox,
            engine: deps.engine,
            clock: deps.clock,
            staleAfter: deps.staleAfter,
          ),
        );
        final auditFacade = AuditFacade.internal(
          useCases: AuditUseCases.build(
            auditCache: deps.auditCache,
            remote: deps.auditRemote,
            clock: deps.clock,
            staleAfter: deps.staleAfter,
          ),
        );
        final lookupFacade = LookupFacade.internal(
          useCases: LookupUseCases.build(
            lookupCache: deps.lookupCache,
            remote: deps.lookupRemote,
            outbox: deps.outbox,
            engine: deps.engine,
            clock: deps.clock,
            staleAfter: deps.staleAfter,
          ),
        );
        final healthFacade = HealthFacade.internal(
          useCases: HealthUseCases.build(remote: deps.healthRemote),
        );

        final runtime = DesktopRuntime(
          cacheDb: deps.cacheDb,
          syncDb: deps.syncDb,
          engine: deps.engine,
          connectivityObserver: observer,
          drainController: drainController,
          registry: registryFacade,
          assessment: assessmentFacade,
          care: careFacade,
          protection: protectionFacade,
          audit: auditFacade,
          lookup: lookupFacade,
          health: healthFacade,
        );

        // Pointer identity — the runtime stored exactly what we passed
        // in, not a copy or a decorator wrapping it.
        expect(identical(runtime.cacheDb, deps.cacheDb), isTrue);
        expect(identical(runtime.syncDb, deps.syncDb), isTrue);
        expect(identical(runtime.engine, deps.engine), isTrue);
        expect(identical(runtime.connectivityObserver, observer), isTrue);
        expect(identical(runtime.drainController, drainController), isTrue);
        expect(identical(runtime.registry, registryFacade), isTrue);
      },
    );
  });
}
