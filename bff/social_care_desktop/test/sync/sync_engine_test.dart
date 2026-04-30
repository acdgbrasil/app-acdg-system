/// RED-phase tests for `SyncEngine` (A18a-v2).
///
/// `SyncEngine` is the orchestrator that drains the Outbox and dispatches
/// each `SyncMutation` to the right sub-contract method. It owns the
/// state machine for an Outbox row across its lifecycle.
///
/// ── Surface under test ────────────────────────────────────────────────
///   * `SyncEngine({...})` — constructor takes `OutboxRepository` plus
///     all 5 write sub-contracts, plus `RetryPolicy` and
///     `ConflictResolver`.
///   * `Future<void> start()` — enables drain.
///   * `Future<void> stop()`  — disables drain.
///   * `Future<Result<DrainSummary>> triggerDrain()` — single-flight,
///     FIFO over `pending` rows.
///   * `Future<void> close()` — releases resources.
///
/// ── Test axes ────────────────────────────────────────────────────────
///   1. start/stop control: triggerDrain pre-start is a no-op (Success
///      with processed=0); after start it actually drains.
///   2. Single-flight: concurrent `triggerDrain()` calls share the same
///      in-flight Future (no double-drain).
///   3. FIFO: drain processes mutations in `createdAt ASC` order.
///   4. Success path: dispatch hits the correct sub-contract method;
///      Outbox row transitions to `completed`.
///   5. Retriable failure: row → `failed_retriable`, attemptCount = 1,
///      lastError populated.
///   6. Dead failure (409): row → `failed_dead` immediately, no retry.
///   7. Mixed batch: 3+ mutations of different types drained in one
///      pass, each landing on the correct status.
///   8. Empty queue: drain returns Success with processed = 0.
///   9. close(): subsequent triggerDrain returns Failure.
///
/// ── REGRA #2: drain semantics on stop() ──────────────────────────────
/// STATE.md says "drain only runs when started". We assert that
/// triggerDrain pre-start returns Success(processed: 0) — the engine
/// MUST NOT silently throw or process anything before start. If the
/// implementer chooses to fail loudly with `Failure(SyncFailure)`
/// instead, that is a contract change and must be flagged.
///
/// ── REGRA #2: single-flight semantics ────────────────────────────────
/// STATE.md says "concurrent calls become no-op if a drain already
/// running". We model that as "concurrent triggerDrain returns the
/// SAME Future" (pure single-flight). That is a stronger guarantee
/// than no-op-and-discard but matches the typical mutex-with-completion
/// pattern. If the implementer chooses to short-circuit later calls
/// with a fresh `Success(DrainSummary(processed: 0))`, that is
/// acceptable, but they MUST flag the difference here.
///
/// IMPORTANT (RED phase): `SyncEngine`, `DrainSummary`, the Outbox
/// types, and the `SyncMutation` hierarchy do NOT exist yet. The
/// `import` lines fail — that is the intended RED signal.
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/sync/_shared/failures.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/sync/engine/conflict_resolver.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/sync/engine/retry_policy.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/sync/engine/sync_engine.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/sync/outbox/outbox_repository.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/sync/outbox/sync_mutation.dart';

import '../_test_uuids.dart';
import '_test_sync_db.dart';

/// Programmable Registry fake — overrides only the methods we exercise,
/// returning whatever Result the test sets.
class _ProgrammableRegistryFake extends FakeRegistryBff {
  /// If set for a given `mutationType` discriminator, that result is
  /// returned next time the mapped contract method runs. Otherwise we
  /// fall back to the parent fake's default Success.
  final Map<String, Result<Object?>> overrides = {};

  /// Records, in call order, the `mutationType` discriminators that hit
  /// the contract — letting tests assert FIFO ordering.
  final List<String> calls = [];

  Result<T> _take<T>(String key, Result<T> fallback) {
    final v = overrides.remove(key);
    return (v as Result<T>?) ?? fallback;
  }

  @override
  Future<Result<StandardIdResponse>> registerPatient(
    RegisterPatientRequest request,
  ) async {
    calls.add('register_patient');
    return _take('register_patient', await super.registerPatient(request));
  }

  @override
  Future<Result<void>> dischargePatient(
    String patientId,
    DischargePatientRequest request,
  ) async {
    calls.add('discharge_patient');
    return _take('discharge_patient', const Success(null));
  }

  @override
  Future<Result<void>> readmitPatient(
    String patientId,
    ReadmitPatientRequest request,
  ) async {
    calls.add('readmit_patient');
    return _take('readmit_patient', const Success(null));
  }

  @override
  Future<Result<void>> withdrawPatient(
    String patientId,
    WithdrawPatientRequest request,
  ) async {
    calls.add('withdraw_patient');
    return _take('withdraw_patient', const Success(null));
  }
}

void main() {
  // Stable createdAt anchor for fixtures.
  final t0 = DateTime.utc(2026, 4, 30, 12);

  /// Constructs a SyncEngine with all dependencies + a fresh in-memory DB.
  ({
    SyncEngine engine,
    OutboxRepository outbox,
    _ProgrammableRegistryFake registry,
    Object database,
  })
  buildEngine() {
    final db = newInMemorySyncDatabase();
    final outbox = DriftOutboxRepository(db);
    final registry = _ProgrammableRegistryFake();
    final engine = SyncEngine(
      outbox: outbox,
      registry: registry,
      assessment: FakeAssessmentBff(),
      care: FakeCareBff(),
      protection: FakeProtectionBff(),
      lookup: FakeLookupBff(),
      retryPolicy: const RetryPolicy(),
      conflictResolver: const ConflictResolver(),
    );
    return (engine: engine, outbox: outbox, registry: registry, database: db);
  }

  /// Discharge fixture used everywhere — minimal request body.
  DischargePatientMutation dischargeFixture({
    required String id,
    String aggregateId = kPatientUuid,
    int expectedVersion = 0,
    DateTime? createdAt,
  }) {
    return DischargePatientMutation(
      id: id,
      aggregateId: aggregateId,
      expectedVersion: expectedVersion,
      createdAt: createdAt ?? t0,
      request: const DischargePatientRequest(reason: 'transferred'),
    );
  }

  group('SyncEngine — start/stop control', () {
    test('triggerDrain pre-start is a no-op: processed = 0', () async {
      final ctx = buildEngine();
      addTearDown(() => ctx.engine.close());

      await ctx.outbox.enqueue(dischargeFixture(id: 'm1'));

      final res = await ctx.engine.triggerDrain();
      expect(res, isA<Success<DrainSummary>>());
      final summary = (res as Success<DrainSummary>).value;
      expect(
        summary.processed,
        0,
        reason: 'engine has not been started yet — must not drain',
      );

      // Outbox row stayed pending.
      final list = await ctx.outbox.listByStatus(OutboxStatus.pending);
      expect((list as Success<List<OutboxEntry>>).value, hasLength(1));
    });

    test('after start(), triggerDrain processes the queue', () async {
      final ctx = buildEngine();
      addTearDown(() => ctx.engine.close());
      await ctx.engine.start();

      await ctx.outbox.enqueue(dischargeFixture(id: 'm1'));
      final res = await ctx.engine.triggerDrain();

      final summary = (res as Success<DrainSummary>).value;
      expect(summary.processed, 1);
      expect(summary.completed, 1);
      expect(ctx.registry.calls, ['discharge_patient']);
    });

    test(
      'stop() suspends drain — pending rows remain after triggerDrain',
      () async {
        final ctx = buildEngine();
        addTearDown(() => ctx.engine.close());
        await ctx.engine.start();
        await ctx.engine.stop();

        await ctx.outbox.enqueue(dischargeFixture(id: 'm1'));
        final res = await ctx.engine.triggerDrain();
        expect((res as Success<DrainSummary>).value.processed, 0);

        final list = await ctx.outbox.listByStatus(OutboxStatus.pending);
        expect((list as Success<List<OutboxEntry>>).value, hasLength(1));
        expect(ctx.registry.calls, isEmpty);
      },
    );
  });

  group('SyncEngine — single-flight', () {
    test('concurrent triggerDrain calls share an in-flight drain', () async {
      final ctx = buildEngine();
      addTearDown(() => ctx.engine.close());
      await ctx.engine.start();

      // 3 mutations enqueued — drain will dispatch each to the registry.
      for (var i = 0; i < 3; i++) {
        await ctx.outbox.enqueue(
          dischargeFixture(
            id: 'm$i',
            createdAt: t0.add(Duration(seconds: i)),
          ),
        );
      }

      // Fire two drains in parallel.
      final f1 = ctx.engine.triggerDrain();
      final f2 = ctx.engine.triggerDrain();
      final results = await Future.wait([f1, f2]);

      // Each contract method must be hit exactly once per row — never
      // twice — even though we kicked drain twice.
      expect(
        ctx.registry.calls,
        hasLength(3),
        reason: 'single-flight: each row dispatched exactly once',
      );
      // Both drains return Success.
      expect(results.every((r) => r is Success<DrainSummary>), isTrue);
    });
  });

  group('SyncEngine — FIFO ordering', () {
    test('drain processes pending rows in createdAt ASC order', () async {
      final ctx = buildEngine();
      addTearDown(() => ctx.engine.close());
      await ctx.engine.start();

      // Enqueue out-of-order; drain must reorder by createdAt.
      await ctx.outbox.enqueue(
        WithdrawPatientMutation(
          id: 'newest',
          aggregateId: kPatientUuid,
          expectedVersion: 0,
          createdAt: t0.add(const Duration(minutes: 10)),
          request: const WithdrawPatientRequest(reason: 'last'),
        ),
      );
      await ctx.outbox.enqueue(dischargeFixture(id: 'oldest', createdAt: t0));
      await ctx.outbox.enqueue(
        ReadmitPatientMutation(
          id: 'middle',
          aggregateId: kPatientUuid,
          expectedVersion: 0,
          createdAt: t0.add(const Duration(minutes: 5)),
          request: const ReadmitPatientRequest(),
        ),
      );

      await ctx.engine.triggerDrain();

      expect(ctx.registry.calls, [
        'discharge_patient',
        'readmit_patient',
        'withdraw_patient',
      ], reason: 'FIFO by createdAt: oldest → middle → newest');
    });
  });

  group('SyncEngine — outcome state transitions', () {
    test('Success: row marked completed', () async {
      final ctx = buildEngine();
      addTearDown(() => ctx.engine.close());
      await ctx.engine.start();

      await ctx.outbox.enqueue(dischargeFixture(id: 'ok'));
      await ctx.engine.triggerDrain();

      final entry =
          ((await ctx.outbox.findById('ok')) as Success<OutboxEntry?>).value!;
      expect(entry.status, OutboxStatus.completed);
    });

    test(
      'Retriable failure: row → failed_retriable + attemptCount=1 + lastError',
      () async {
        final ctx = buildEngine();
        addTearDown(() => ctx.engine.close());
        await ctx.engine.start();
        ctx.registry.overrides['discharge_patient'] = Failure<void>(
          BackendErrorResponse(
            error: BackendError(
              id: 'e',
              code: 'INTERNAL_SERVER_ERROR',
              message: 'transient',
              http: 503,
            ),
          ),
        );

        await ctx.outbox.enqueue(dischargeFixture(id: 'fail-503'));
        await ctx.engine.triggerDrain();

        final entry =
            ((await ctx.outbox.findById('fail-503')) as Success<OutboxEntry?>)
                .value!;
        expect(entry.status, OutboxStatus.failedRetriable);
        expect(entry.attemptCount, 1);
        expect(entry.lastError, isNotNull);
      },
    );

    test(
      'Dead failure (409): row → failed_dead immediately, no retry',
      () async {
        final ctx = buildEngine();
        addTearDown(() => ctx.engine.close());
        await ctx.engine.start();
        ctx.registry.overrides['discharge_patient'] = Failure<void>(
          BackendErrorResponse(
            error: BackendError(
              id: 'e',
              code: 'OPTIMISTIC_LOCK_CONFLICT',
              message: 'version mismatch',
              http: 409,
            ),
          ),
        );

        await ctx.outbox.enqueue(dischargeFixture(id: 'fail-409'));
        final res = await ctx.engine.triggerDrain();

        final summary = (res as Success<DrainSummary>).value;
        expect(summary.failedDead, 1);
        expect(summary.failedRetriable, 0);

        final entry =
            ((await ctx.outbox.findById('fail-409')) as Success<OutboxEntry?>)
                .value!;
        expect(entry.status, OutboxStatus.failedDead);
      },
    );
  });

  group('SyncEngine — mixed batch + DrainSummary', () {
    test(
      '3 mutations of different types drained: each lands on correct status',
      () async {
        final ctx = buildEngine();
        addTearDown(() => ctx.engine.close());
        await ctx.engine.start();

        // 1 ok, 1 retriable (503), 1 dead (404).
        ctx.registry.overrides['readmit_patient'] = Failure<void>(
          BackendErrorResponse(
            error: BackendError(id: '1', code: 'X', message: 'srv', http: 503),
          ),
        );
        ctx.registry.overrides['withdraw_patient'] = Failure<void>(
          BackendErrorResponse(
            error: BackendError(
              id: '2',
              code: 'X',
              message: 'not found',
              http: 404,
            ),
          ),
        );

        await ctx.outbox.enqueue(dischargeFixture(id: 'A', createdAt: t0));
        await ctx.outbox.enqueue(
          ReadmitPatientMutation(
            id: 'B',
            aggregateId: kPatientUuid,
            expectedVersion: 0,
            createdAt: t0.add(const Duration(seconds: 1)),
            request: const ReadmitPatientRequest(),
          ),
        );
        await ctx.outbox.enqueue(
          WithdrawPatientMutation(
            id: 'C',
            aggregateId: kPatientUuid,
            expectedVersion: 0,
            createdAt: t0.add(const Duration(seconds: 2)),
            request: const WithdrawPatientRequest(reason: 'declined'),
          ),
        );

        final res = await ctx.engine.triggerDrain();
        final summary = (res as Success<DrainSummary>).value;

        expect(summary.processed, 3);
        expect(summary.completed, 1);
        expect(summary.failedRetriable, 1);
        expect(summary.failedDead, 1);

        expect(
          (((await ctx.outbox.findById('A')) as Success<OutboxEntry?>).value!)
              .status,
          OutboxStatus.completed,
        );
        expect(
          (((await ctx.outbox.findById('B')) as Success<OutboxEntry?>).value!)
              .status,
          OutboxStatus.failedRetriable,
        );
        expect(
          (((await ctx.outbox.findById('C')) as Success<OutboxEntry?>).value!)
              .status,
          OutboxStatus.failedDead,
        );
      },
    );
  });

  group('SyncEngine — edge cases', () {
    test(
      'empty queue: triggerDrain returns Success with processed = 0',
      () async {
        final ctx = buildEngine();
        addTearDown(() => ctx.engine.close());
        await ctx.engine.start();

        final res = await ctx.engine.triggerDrain();
        expect(res, isA<Success<DrainSummary>>());
        final summary = (res as Success<DrainSummary>).value;
        expect(summary.processed, 0);
        expect(summary.completed, 0);
        expect(summary.failedRetriable, 0);
        expect(summary.failedDead, 0);
        expect(ctx.registry.calls, isEmpty);
      },
    );

    test(
      'close(): subsequent triggerDrain returns Failure(SyncFailure)',
      () async {
        final ctx = buildEngine();
        await ctx.engine.start();
        await ctx.engine.close();

        final res = await ctx.engine.triggerDrain();
        expect(res, isA<Failure<DrainSummary>>());
        expect((res as Failure<DrainSummary>).error, isA<SyncFailure>());
      },
    );
  });
}
