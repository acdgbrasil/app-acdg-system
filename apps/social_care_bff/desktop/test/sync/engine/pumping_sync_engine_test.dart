/// RED-phase tests for `PumpingSyncEngine` (D01 W0.5).
///
/// `PumpingSyncEngine` is the `SyncEngine` subclass that pumps every
/// successful drain summary onto a broadcast `StreamController` so the UI
/// (sub-facade `drainStream`) sees every drain completion — including
/// fire-and-forget triggers from write use cases. Today it lives as
/// `_PumpingSyncEngine` (private) inside `social_care_desktop.dart`
/// (lines 120-146). D01 promotes it to a public class living next to
/// `SyncEngine` at `lib/src/sync/engine/pumping_sync_engine.dart`.
///
/// ── Surface under test ────────────────────────────────────────────────
///   * `class PumpingSyncEngine extends SyncEngine`
///       Ctor: `PumpingSyncEngine({required outbox, registry, assessment,
///              care, protection, lookup, required drainController})`
///       Override: `Future<Result<DrainSummary>> triggerDrain()` — pumps
///       on Success, swallows on Failure, NEVER throws when controller
///       is closed.
///
/// ── Pump semantics (the contract being asserted) ──────────────────────
///   1. On Success → controller.add(summary) called exactly once with
///      the SAME `DrainSummary` value the underlying engine produced.
///   2. On Failure → controller.add NOT called. The Result still
///      propagates to the caller — pumping is observation, not gating.
///   3. Closed controller → triggerDrain still returns the underlying
///      Result; the pump short-circuits silently. We MUST NOT raise a
///      `StateError("Cannot add events after closing")` in this branch
///      (regression against `_drainController.isClosed` check at line 138
///      of the legacy code).
///   4. Broadcast contract — multiple subscribers ALL receive the event.
///
/// ── REGRA #2: failure pump policy ─────────────────────────────────────
/// The legacy code intentionally pumps ONLY successes ("Failures are NOT
/// pumped — the panel UI surfaces them via the Result returned" — facade
/// line 116-119). A future redesign might pump both, but that's a
/// behavior change. Tests #20 pin the current contract; W1 must not
/// silently widen it.
///
/// ── REGRA #2: close-after-controller policy ───────────────────────────
/// Test #22 closes the controller BEFORE calling `triggerDrain`. The
/// engine is not closed (so the underlying drain still runs), but the
/// pump can no longer write. The current impl checks `isClosed` before
/// `.add()` — we assert that no `StateError` escapes and the underlying
/// Result still flows. If W1 chooses to make this branch return a
/// `Failure(SyncFailure)` instead, that's a behavior change to flag.
///
/// IMPORTANT (RED phase): the import resolves to a file that does NOT
/// exist yet — `lib/src/sync/engine/pumping_sync_engine.dart` is W1's
/// output. Until then this file fails to analyze. That is the intended
/// RED signal.
library;

import 'dart:async';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_desktop/src/sync/_shared/sync_database.dart';
import 'package:social_care_desktop/src/sync/engine/sync_engine.dart';
import 'package:social_care_desktop/src/sync/outbox/outbox_repository.dart';
import 'package:social_care_desktop/src/sync/outbox/sync_mutation.dart';

// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/sync/engine/pumping_sync_engine.dart';

import '../../_test_uuids.dart';
import '../_test_sync_db.dart';

/// Programmable Registry fake — same shape used by `sync_engine_test.dart`.
/// Lets us push the underlying engine into success/failure outcomes
/// deterministically per call.
class _ProgrammableRegistryFake extends FakeRegistryBff {
  final Map<String, Result<Object?>> overrides = {};
  final List<String> calls = [];

  Result<T> _take<T>(String key, Result<T> fallback) {
    final v = overrides.remove(key);
    return (v as Result<T>?) ?? fallback;
  }

  @override
  Future<Result<void>> dischargePatient(
    String patientId,
    DischargePatientRequest request,
  ) async {
    calls.add('discharge_patient');
    return _take('discharge_patient', const Success(null));
  }
}

void main() {
  final t0 = DateTime.utc(2026, 5, 1, 12);

  /// Builds a `PumpingSyncEngine` plus its outbox + registry + a fresh
  /// broadcast controller. The engine is auto-started so triggerDrain
  /// actually drains pending rows.
  Future<({
    PumpingSyncEngine engine,
    OutboxRepository outbox,
    _ProgrammableRegistryFake registry,
    StreamController<DrainSummary> controller,
    SyncDatabase database,
  })>
      buildEngine({StreamController<DrainSummary>? sharedController}) async {
    final db = newInMemorySyncDatabase();
    final outbox = DriftOutboxRepository(db);
    final registry = _ProgrammableRegistryFake();
    final controller =
        sharedController ?? StreamController<DrainSummary>.broadcast();
    final engine = PumpingSyncEngine(
      outbox: outbox,
      registry: registry,
      assessment: FakeAssessmentBff(),
      care: FakeCareBff(),
      protection: FakeProtectionBff(),
      lookup: FakeLookupBff(),
      drainController: controller,
    );
    await engine.start();
    return (
      engine: engine,
      outbox: outbox,
      registry: registry,
      controller: controller,
      database: db,
    );
  }

  DischargePatientMutation dischargeFixture({
    required String id,
    DateTime? createdAt,
  }) {
    return DischargePatientMutation(
      id: id,
      aggregateId: kPatientUuid,
      expectedVersion: 0,
      createdAt: createdAt ?? t0,
      request: const DischargePatientRequest(reason: 'transferred'),
    );
  }

  group('PumpingSyncEngine — type identity', () {
    test('extends SyncEngine (substitutable everywhere SyncEngine is used)',
        () async {
      final ctx = await buildEngine();
      addTearDown(() async {
        await ctx.engine.close();
        await ctx.controller.close();
      });

      expect(ctx.engine, isA<SyncEngine>());
    });
  });

  group('PumpingSyncEngine — pump on Success', () {
    test('Success drain pumps the SAME DrainSummary onto the controller',
        () async {
      final ctx = await buildEngine();
      addTearDown(() async {
        await ctx.engine.close();
        await ctx.controller.close();
      });

      // Pre-subscribe BEFORE triggering — broadcast streams drop events
      // emitted while no listener is attached.
      final pumped = <DrainSummary>[];
      final sub = ctx.controller.stream.listen(pumped.add);
      addTearDown(sub.cancel);

      await ctx.outbox.enqueue(dischargeFixture(id: 'm1'));
      final result = await ctx.engine.triggerDrain();

      // Allow the broadcast scheduler one microtask hop.
      await Future<void>.delayed(Duration.zero);

      expect(result, isA<Success<DrainSummary>>());
      final returned = (result as Success<DrainSummary>).value;
      expect(pumped, hasLength(1),
          reason: 'pump must fire exactly once per success');
      expect(
        identical(pumped.single, returned),
        isTrue,
        reason: 'the pumped summary MUST be the same instance Result holds',
      );
    });

    test(
      'multiple subscribers each receive the pumped summary (broadcast contract)',
      () async {
        final ctx = await buildEngine();
        addTearDown(() async {
          await ctx.engine.close();
          await ctx.controller.close();
        });

        final received1 = <DrainSummary>[];
        final received2 = <DrainSummary>[];
        final sub1 = ctx.controller.stream.listen(received1.add);
        final sub2 = ctx.controller.stream.listen(received2.add);
        addTearDown(sub1.cancel);
        addTearDown(sub2.cancel);

        await ctx.outbox.enqueue(dischargeFixture(id: 'm1'));
        await ctx.engine.triggerDrain();
        await Future<void>.delayed(Duration.zero);

        expect(received1, hasLength(1));
        expect(received2, hasLength(1));
        expect(identical(received1.single, received2.single), isTrue);
      },
    );

    test('one triggerDrain call = at most one pump (no duplicate emission)',
        () async {
      final ctx = await buildEngine();
      addTearDown(() async {
        await ctx.engine.close();
        await ctx.controller.close();
      });

      final pumped = <DrainSummary>[];
      final sub = ctx.controller.stream.listen(pumped.add);
      addTearDown(sub.cancel);

      // 3 mutations → 1 drain → 1 summary. The pump must NOT fire per
      // mutation (per-row events would spam the panel UI).
      for (var i = 0; i < 3; i++) {
        await ctx.outbox.enqueue(
          dischargeFixture(
            id: 'm$i',
            createdAt: t0.add(Duration(seconds: i)),
          ),
        );
      }

      await ctx.engine.triggerDrain();
      await Future<void>.delayed(Duration.zero);

      expect(
        pumped,
        hasLength(1),
        reason: 'pump granularity is per-drain, not per-mutation',
      );
      expect(pumped.single.processed, 3);
    });
  });

  group('PumpingSyncEngine — no pump on Failure', () {
    test('post-close drain returns Failure → controller receives NOTHING',
        () async {
      final ctx = await buildEngine();
      addTearDown(() async {
        await ctx.controller.close();
      });

      final pumped = <DrainSummary>[];
      final sub = ctx.controller.stream.listen(pumped.add);
      addTearDown(sub.cancel);

      // Close the engine so the next triggerDrain is forced into the
      // Failure(SyncFailure) branch — that's the existing surface
      // exercised by `sync_engine_test.dart`'s "close()" test.
      await ctx.engine.close();
      final result = await ctx.engine.triggerDrain();
      await Future<void>.delayed(Duration.zero);

      expect(result, isA<Failure<DrainSummary>>(),
          reason: 'sanity: post-close drain MUST be Failure');
      expect(
        pumped,
        isEmpty,
        reason:
            'Failure branch MUST NOT pump — the panel UI sees errors via '
            'the Result, not the stream (legacy comment lines 116-119)',
      );
    });
  });

  group('PumpingSyncEngine — closed controller is non-fatal', () {
    test(
      'controller closed BEFORE drain → triggerDrain still returns Success, '
      'no StateError leaks',
      () async {
        final ctx = await buildEngine();
        addTearDown(() => ctx.engine.close());

        // Close the broadcast controller while the engine is still running.
        await ctx.controller.close();
        expect(ctx.controller.isClosed, isTrue, reason: 'sanity');

        await ctx.outbox.enqueue(dischargeFixture(id: 'm1'));

        // The drain itself succeeds; the pump silently no-ops because of
        // the `isClosed` guard. We must NOT see a StateError surface.
        final result = await ctx.engine.triggerDrain();

        expect(result, isA<Success<DrainSummary>>());
        expect((result as Success<DrainSummary>).value.processed, 1);
      },
    );
  });
}
