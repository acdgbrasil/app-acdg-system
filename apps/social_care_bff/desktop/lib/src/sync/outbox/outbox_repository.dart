import 'dart:convert';

import 'package:core_contracts/core_contracts.dart';
import 'package:drift/drift.dart';

import '../_shared/failures.dart';
import '../_shared/sync_database.dart';
import '../_shared/tables/outbox_table.drift.dart';
import 'sync_mutation.dart';

/// Lifecycle state of an Outbox row.
///
/// Persisted as lowercase snake_case strings so the SQL is greppable and
/// matches the discriminator convention used throughout `SyncMutation`.
enum OutboxStatus {
  pending,
  inFlight,
  failedRetriable,
  failedDead,
  completed;

  /// Persists as `'pending'` | `'in_flight'` | `'failed_retriable'` |
  /// `'failed_dead'` | `'completed'`.
  String toSql() {
    switch (this) {
      case OutboxStatus.pending:
        return 'pending';
      case OutboxStatus.inFlight:
        return 'in_flight';
      case OutboxStatus.failedRetriable:
        return 'failed_retriable';
      case OutboxStatus.failedDead:
        return 'failed_dead';
      case OutboxStatus.completed:
        return 'completed';
    }
  }

  static OutboxStatus fromSql(String raw) {
    switch (raw) {
      case 'pending':
        return OutboxStatus.pending;
      case 'in_flight':
        return OutboxStatus.inFlight;
      case 'failed_retriable':
        return OutboxStatus.failedRetriable;
      case 'failed_dead':
        return OutboxStatus.failedDead;
      case 'completed':
        return OutboxStatus.completed;
      default:
        throw StateError('Unknown OutboxStatus: $raw');
    }
  }
}

/// In-memory projection of an `Outbox` row. Returned by
/// [OutboxRepository] read methods and consumed by
/// [SyncMutation.fromOutboxEntry].
///
/// Immutable; equality is reference-only — tests assert field-by-field.
class OutboxEntry {
  const OutboxEntry({
    required this.id,
    required this.aggregateType,
    required this.aggregateId,
    required this.mutationType,
    required this.payload,
    required this.expectedVersion,
    required this.createdAt,
    required this.attemptCount,
    required this.lastAttemptAt,
    required this.lastError,
    required this.status,
  });

  final String id;
  final String aggregateType;
  final String aggregateId;
  final String mutationType;
  final Map<String, dynamic> payload;
  final int expectedVersion;
  final DateTime createdAt;
  final int attemptCount;
  final DateTime? lastAttemptAt;
  final String? lastError;
  final OutboxStatus status;
}

/// Persistence boundary for the SyncQueue Outbox.
///
/// Wraps Drift, exposing typed CRUD over `Outbox` rows and converting
/// every raw exception into `Failure(SyncFailure(...))`. Missing rows
/// surface as `Success(null)`, never `Failure`.
abstract interface class OutboxRepository {
  /// Inserts a new row for [mutation] in `pending` state. Idempotent on
  /// the mutation id (upsert semantics — re-enqueue replaces the row).
  Future<Result<void>> enqueue(SyncMutation mutation);

  /// Returns rows matching [status] in `createdAt ASC` order. The drain
  /// query uses `OutboxStatus.pending`; tests use the others to verify
  /// state transitions.
  Future<Result<List<OutboxEntry>>> listByStatus(
    OutboxStatus status, {
    int? limit,
  });

  /// Looks up a single row by id. `Success(null)` for missing rows.
  Future<Result<OutboxEntry?>> findById(String id);

  /// Transitions `pending` → `in_flight` (no retry counter change).
  Future<Result<void>> markInFlight(String id);

  /// Transitions `in_flight` → `completed` (terminal — drained
  /// successfully).
  Future<Result<void>> markCompleted(String id);

  /// Transitions `in_flight` → `failed_retriable`. Increments
  /// `attemptCount` (read by `RetryPolicy.shouldRetry`) and stamps
  /// `lastAttemptAt` + `lastError`.
  Future<Result<void>> markFailedRetriable(String id, String error);

  /// Transitions `in_flight` → `failed_dead` (terminal — manual
  /// reconciliation required). Stamps `lastAttemptAt` + `lastError`.
  Future<Result<void>> markFailedDead(String id, String error);

  /// Transitions `failed_retriable` → `pending`, preserving
  /// `attemptCount` (so `RetryPolicy.shouldRetry` can decide whether
  /// to retry next drain).
  Future<Result<void>> resetToPending(String id);

  /// Clears every row regardless of status. Test helper; production
  /// code should never invoke this.
  Future<Result<void>> clear();
}

/// Drift-backed implementation of [OutboxRepository].
///
/// The constructor eagerly fires a no-op `SELECT 1` to force Drift's
/// `ensureOpen` (which runs `MigrationStrategy.onCreate`) BEFORE the
/// caller can interleave a `database.close()`. Without this warm-up,
/// closing a never-opened Drift DB silently re-opens on the next
/// query (Drift quirk for lazy-init), so DB-failure paths would
/// surface as `Success(null)` instead of `Failure`. The warm-up is
/// awaited at the start of every public method.
class DriftOutboxRepository implements OutboxRepository {
  DriftOutboxRepository(SyncDatabase db)
    : _db = db,
      _ready = db.customSelect('SELECT 1').get();

  final SyncDatabase _db;
  final Future<Object?> _ready;

  @override
  Future<Result<void>> enqueue(SyncMutation mutation) async {
    try {
      await _ready;
      await _db
          .into(_db.outbox)
          .insertOnConflictUpdate(
            OutboxCompanion.insert(
              id: mutation.id,
              aggregateType: mutation.aggregateType,
              aggregateId: mutation.aggregateId,
              mutationType: mutation.mutationType,
              payload: jsonEncode(mutation.toPayload()),
              expectedVersion: mutation.expectedVersion,
              createdAt: mutation.createdAt,
              status: OutboxStatus.pending.toSql(),
            ),
          );
      return const Success(null);
    } catch (e, st) {
      return Failure<void>(SyncFailure(e), stackTrace: st);
    }
  }

  @override
  Future<Result<List<OutboxEntry>>> listByStatus(
    OutboxStatus status, {
    int? limit,
  }) async {
    try {
      await _ready;
      final query = _db.select(_db.outbox)
        ..where((t) => t.status.equals(status.toSql()))
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
      if (limit != null) query.limit(limit);
      final rows = await query.get();
      return Success(rows.map(_mapRow).toList());
    } catch (e, st) {
      return Failure<List<OutboxEntry>>(SyncFailure(e), stackTrace: st);
    }
  }

  @override
  Future<Result<OutboxEntry?>> findById(String id) async {
    try {
      await _ready;
      final row = await (_db.select(
        _db.outbox,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (row == null) return const Success(null);
      return Success(_mapRow(row));
    } catch (e, st) {
      return Failure<OutboxEntry?>(SyncFailure(e), stackTrace: st);
    }
  }

  @override
  Future<Result<void>> markInFlight(String id) =>
      _updateStatus(id, OutboxStatus.inFlight);

  @override
  Future<Result<void>> markCompleted(String id) =>
      _updateStatus(id, OutboxStatus.completed);

  @override
  Future<Result<void>> markFailedRetriable(String id, String error) async {
    try {
      await _ready;
      // Read first so we can increment the in-memory attemptCount in a
      // single UPDATE — Drift companions don't expose `expression += 1`
      // at this layer.
      final row = await (_db.select(
        _db.outbox,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (row == null) {
        return Failure<void>(SyncFailure('Outbox row not found: $id'));
      }
      await (_db.update(_db.outbox)..where((t) => t.id.equals(id))).write(
        OutboxCompanion(
          status: Value(OutboxStatus.failedRetriable.toSql()),
          attemptCount: Value(row.attemptCount + 1),
          lastAttemptAt: Value(DateTime.now()),
          lastError: Value(error),
        ),
      );
      return const Success(null);
    } catch (e, st) {
      return Failure<void>(SyncFailure(e), stackTrace: st);
    }
  }

  @override
  Future<Result<void>> markFailedDead(String id, String error) async {
    try {
      await _ready;
      await (_db.update(_db.outbox)..where((t) => t.id.equals(id))).write(
        OutboxCompanion(
          status: Value(OutboxStatus.failedDead.toSql()),
          lastAttemptAt: Value(DateTime.now()),
          lastError: Value(error),
        ),
      );
      return const Success(null);
    } catch (e, st) {
      return Failure<void>(SyncFailure(e), stackTrace: st);
    }
  }

  @override
  Future<Result<void>> resetToPending(String id) =>
      _updateStatus(id, OutboxStatus.pending);

  @override
  Future<Result<void>> clear() async {
    try {
      await _ready;
      await _db.delete(_db.outbox).go();
      return const Success(null);
    } catch (e, st) {
      return Failure<void>(SyncFailure(e), stackTrace: st);
    }
  }

  Future<Result<void>> _updateStatus(String id, OutboxStatus status) async {
    try {
      await _ready;
      await (_db.update(_db.outbox)..where((t) => t.id.equals(id))).write(
        OutboxCompanion(status: Value(status.toSql())),
      );
      return const Success(null);
    } catch (e, st) {
      return Failure<void>(SyncFailure(e), stackTrace: st);
    }
  }

  OutboxEntry _mapRow(OutboxData row) => OutboxEntry(
    id: row.id,
    aggregateType: row.aggregateType,
    aggregateId: row.aggregateId,
    mutationType: row.mutationType,
    payload: jsonDecode(row.payload) as Map<String, dynamic>,
    expectedVersion: row.expectedVersion,
    createdAt: row.createdAt,
    attemptCount: row.attemptCount,
    lastAttemptAt: row.lastAttemptAt,
    lastError: row.lastError,
    status: OutboxStatus.fromSql(row.status),
  );
}
