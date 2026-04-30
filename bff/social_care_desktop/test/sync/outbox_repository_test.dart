/// RED-phase tests for `OutboxRepository` (A18a-v2).
///
/// `OutboxRepository` is the persistence boundary of the SyncQueue. It
/// wraps the Drift-backed `Outbox` table and exposes a typed CRUD API:
///
/// ── Surface under test ────────────────────────────────────────────────
///   * `enqueue(SyncMutation mutation)`            → `Future<Result<void>>`
///   * `listByStatus(OutboxStatus s, {int? limit})` → `Future<Result<List<OutboxEntry>>>`
///   * `findById(String id)`                        → `Future<Result<OutboxEntry?>>`
///   * `markInFlight(String id)`                    → `Future<Result<void>>`
///   * `markCompleted(String id)`                   → `Future<Result<void>>`
///   * `markFailedRetriable(String id, String err)` → `Future<Result<void>>`
///   * `markFailedDead(String id, String err)`      → `Future<Result<void>>`
///   * `resetToPending(String id)`                  → `Future<Result<void>>`
///   * `clear()`                                    → `Future<Result<void>>`
///
/// ── Test axes ────────────────────────────────────────────────────────
///   1. Round-trip — payload, expectedVersion, createdAt preserved verbatim.
///   2. listByStatus filters by status; respects `limit`; ordered by createdAt ASC.
///   3. State transitions — markX moves the row to the right status.
///   4. attemptCount increments on retriable mark.
///   5. lastError stored on failure marks; lastAttemptAt set.
///   6. resetToPending clears in_flight bit and returns to pending.
///   7. clear() empties everything.
///   8. Failure branch — closed DB → `Failure(SyncFailure)`.
///
/// REGRA #2: status discriminator is a string in DB, but exposed as
/// the `OutboxStatus` enum. The repository is responsible for the
/// translation. Tests assert against the enum, never the raw string,
/// to avoid coupling test cases to the SQL serialization choice.
///
/// IMPORTANT (RED phase): `OutboxRepository`, `DriftOutboxRepository`,
/// `OutboxEntry`, `OutboxStatus`, and the `SyncMutation` hierarchy do
/// NOT exist yet. The `import` lines fail — that is the intended RED
/// signal. W1 implements them under `lib/src/sync/outbox/`.
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/sync/_shared/failures.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/sync/outbox/outbox_repository.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/sync/outbox/sync_mutation.dart';

import '../_test_uuids.dart';
import '_test_sync_db.dart';

void main() {
  group('OutboxRepository (Drift, in-memory)', () {
    late OutboxRepository outbox;
    // ignore: prefer_typing_uninitialized_variables
    late var database;

    setUp(() {
      database = newInMemorySyncDatabase();
      outbox = DriftOutboxRepository(database);
    });

    tearDown(() async {
      await safeCloseSync(database);
    });

    /// Builds a deterministic [DischargePatientMutation] for tests.
    SyncMutation dischargeFixture({
      String id = 'mut-discharge-1',
      String aggregateId = kPatientUuid,
      int expectedVersion = 7,
      DateTime? createdAt,
      String reason = 'transferred',
      String? notes = 'family relocated',
    }) {
      return DischargePatientMutation(
        id: id,
        aggregateId: aggregateId,
        expectedVersion: expectedVersion,
        createdAt: createdAt ?? DateTime.utc(2026, 4, 30, 12),
        request: DischargePatientRequest(reason: reason, notes: notes),
      );
    }

    // ── 1. Round-trip ───────────────────────────────────────────────────

    test(
      'enqueue + findById round-trips id, aggregate fields, payload, version, createdAt',
      () async {
        final m = dischargeFixture(
          createdAt: DateTime.utc(2026, 4, 30, 14, 22, 33),
        );

        final enq = await outbox.enqueue(m);
        expect(enq, isA<Success<void>>());

        final found = await outbox.findById('mut-discharge-1');
        expect(found, isA<Success<OutboxEntry?>>());
        final entry = (found as Success<OutboxEntry?>).value!;

        expect(entry.id, 'mut-discharge-1');
        expect(entry.aggregateType, 'patient');
        expect(entry.aggregateId, kPatientUuid);
        expect(entry.mutationType, 'discharge_patient');
        expect(entry.expectedVersion, 7);
        expect(entry.createdAt, DateTime.utc(2026, 4, 30, 14, 22, 33));
        expect(entry.attemptCount, 0);
        expect(entry.lastError, isNull);
        expect(entry.lastAttemptAt, isNull);
        expect(entry.status, OutboxStatus.pending);
        expect(entry.payload['reason'], 'transferred');
        expect(entry.payload['notes'], 'family relocated');
      },
    );

    test('findById returns Success(null) when row is missing', () async {
      final res = await outbox.findById('does-not-exist');
      expect(res, isA<Success<OutboxEntry?>>());
      expect((res as Success<OutboxEntry?>).value, isNull);
    });

    // ── 2. listByStatus filters / ordering ──────────────────────────────

    test(
      'listByStatus(pending) returns only pending rows in createdAt ASC order',
      () async {
        final older = dischargeFixture(
          id: 'mut-older',
          createdAt: DateTime.utc(2026, 4, 30, 10),
        );
        final newer = dischargeFixture(
          id: 'mut-newer',
          createdAt: DateTime.utc(2026, 4, 30, 12),
        );
        await outbox.enqueue(newer);
        await outbox.enqueue(older);

        final res = await outbox.listByStatus(OutboxStatus.pending);
        final list = (res as Success<List<OutboxEntry>>).value;

        expect(list.map((e) => e.id), ['mut-older', 'mut-newer']);
      },
    );

    test('listByStatus excludes rows in other statuses', () async {
      final pendingMut = dischargeFixture(id: 'p1');
      final completedMut = dischargeFixture(id: 'c1');
      await outbox.enqueue(pendingMut);
      await outbox.enqueue(completedMut);
      await outbox.markInFlight('c1');
      await outbox.markCompleted('c1');

      final pending = await outbox.listByStatus(OutboxStatus.pending);
      expect((pending as Success<List<OutboxEntry>>).value.map((e) => e.id), [
        'p1',
      ]);

      final completed = await outbox.listByStatus(OutboxStatus.completed);
      expect((completed as Success<List<OutboxEntry>>).value.map((e) => e.id), [
        'c1',
      ]);
    });

    test('listByStatus respects `limit`', () async {
      for (var i = 0; i < 5; i++) {
        await outbox.enqueue(
          dischargeFixture(
            id: 'm$i',
            createdAt: DateTime.utc(2026, 4, 30, 10 + i),
          ),
        );
      }
      final res = await outbox.listByStatus(OutboxStatus.pending, limit: 2);
      final list = (res as Success<List<OutboxEntry>>).value;
      expect(list, hasLength(2));
      expect(list.map((e) => e.id), ['m0', 'm1']);
    });

    // ── 3. State transitions ────────────────────────────────────────────

    test('markInFlight transitions pending → in_flight', () async {
      await outbox.enqueue(dischargeFixture());

      final res = await outbox.markInFlight('mut-discharge-1');
      expect(res, isA<Success<void>>());

      final entry =
          ((await outbox.findById('mut-discharge-1')) as Success<OutboxEntry?>)
              .value!;
      expect(entry.status, OutboxStatus.inFlight);
    });

    test('markCompleted transitions in_flight → completed', () async {
      await outbox.enqueue(dischargeFixture());
      await outbox.markInFlight('mut-discharge-1');

      final res = await outbox.markCompleted('mut-discharge-1');
      expect(res, isA<Success<void>>());

      final entry =
          ((await outbox.findById('mut-discharge-1')) as Success<OutboxEntry?>)
              .value!;
      expect(entry.status, OutboxStatus.completed);
    });

    test(
      'markFailedDead transitions in_flight → failed_dead and stores lastError',
      () async {
        await outbox.enqueue(dischargeFixture());
        await outbox.markInFlight('mut-discharge-1');

        final res = await outbox.markFailedDead(
          'mut-discharge-1',
          'OPTIMISTIC_LOCK_CONFLICT',
        );
        expect(res, isA<Success<void>>());

        final entry =
            ((await outbox.findById('mut-discharge-1'))
                    as Success<OutboxEntry?>)
                .value!;
        expect(entry.status, OutboxStatus.failedDead);
        expect(entry.lastError, 'OPTIMISTIC_LOCK_CONFLICT');
        expect(entry.lastAttemptAt, isNotNull);
      },
    );

    // ── 4. attemptCount + lastError on retriable mark ───────────────────

    test(
      'markFailedRetriable stores error, sets lastAttemptAt, increments attemptCount',
      () async {
        await outbox.enqueue(dischargeFixture());
        await outbox.markInFlight('mut-discharge-1');

        final res = await outbox.markFailedRetriable(
          'mut-discharge-1',
          '503 Service Unavailable',
        );
        expect(res, isA<Success<void>>());

        final entry =
            ((await outbox.findById('mut-discharge-1'))
                    as Success<OutboxEntry?>)
                .value!;
        expect(entry.status, OutboxStatus.failedRetriable);
        expect(entry.lastError, '503 Service Unavailable');
        expect(entry.attemptCount, 1);
        expect(entry.lastAttemptAt, isNotNull);
      },
    );

    test('attemptCount accumulates across multiple retriable marks', () async {
      await outbox.enqueue(dischargeFixture());
      await outbox.markInFlight('mut-discharge-1');
      await outbox.markFailedRetriable('mut-discharge-1', 'err1');
      await outbox.resetToPending('mut-discharge-1');
      await outbox.markInFlight('mut-discharge-1');
      await outbox.markFailedRetriable('mut-discharge-1', 'err2');

      final entry =
          ((await outbox.findById('mut-discharge-1')) as Success<OutboxEntry?>)
              .value!;
      expect(entry.attemptCount, 2);
      expect(entry.lastError, 'err2');
    });

    // ── 5. resetToPending ───────────────────────────────────────────────

    test(
      'resetToPending moves failed_retriable → pending (for retry after backoff)',
      () async {
        await outbox.enqueue(dischargeFixture());
        await outbox.markInFlight('mut-discharge-1');
        await outbox.markFailedRetriable('mut-discharge-1', 'transient');

        final res = await outbox.resetToPending('mut-discharge-1');
        expect(res, isA<Success<void>>());

        final entry =
            ((await outbox.findById('mut-discharge-1'))
                    as Success<OutboxEntry?>)
                .value!;
        expect(entry.status, OutboxStatus.pending);
        // attemptCount must be preserved across resetToPending — that is how
        // RetryPolicy decides "should we still retry?"
        expect(entry.attemptCount, 1);
      },
    );

    // ── 6. clear() ──────────────────────────────────────────────────────

    test('clear() removes every row regardless of status', () async {
      await outbox.enqueue(dischargeFixture(id: 'a'));
      await outbox.enqueue(dischargeFixture(id: 'b'));
      await outbox.markInFlight('b');

      final res = await outbox.clear();
      expect(res, isA<Success<void>>());

      final pending = await outbox.listByStatus(OutboxStatus.pending);
      final inFlight = await outbox.listByStatus(OutboxStatus.inFlight);
      expect((pending as Success<List<OutboxEntry>>).value, isEmpty);
      expect((inFlight as Success<List<OutboxEntry>>).value, isEmpty);
    });

    // ── 7. Failure branch ───────────────────────────────────────────────

    test('returns Failure(SyncFailure) when underlying DB is closed', () async {
      await database.close();

      final res = await outbox.enqueue(dischargeFixture());
      expect(res, isA<Failure<void>>());
      expect((res as Failure<void>).error, isA<SyncFailure>());
    });
  });
}
