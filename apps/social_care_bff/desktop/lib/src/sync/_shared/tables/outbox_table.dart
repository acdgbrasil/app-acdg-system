import 'package:drift/drift.dart';

/// Drift table backing the SyncQueue Outbox.
///
/// One row per pending write mutation. The full request body is stored as
/// JSON in [payload]; [mutationType] is the discriminator that drives
/// `SyncMutation.fromOutboxEntry` — see `sync_mutation.dart` for the 27
/// canonical values.
///
/// Indexed by `(status, createdAt)` because the drain query is
/// `WHERE status='pending' ORDER BY createdAt ASC LIMIT N` — a composite
/// index lets SQLite serve the drain without a sort step.
@TableIndex(name: 'outbox_status_created_idx', columns: {#status, #createdAt})
class Outbox extends Table {
  /// UUID v4. Idempotency key — re-enqueueing the same mutation is a
  /// no-op (the drain has already processed it or is about to).
  TextColumn get id => text()();

  /// Aggregate root the mutation targets — `'patient'`, `'appointment'`,
  /// `'referral'`, `'violation_report'`, `'lookup_item'`,
  /// `'lookup_request'`. Used for invalidation hints; not for routing
  /// (routing is by [mutationType]).
  TextColumn get aggregateType => text()();

  /// Identity of the entity being mutated (UUID for patient/appointment/
  /// referral/violation_report/lookup_request; table name for
  /// lookup_item creates).
  TextColumn get aggregateId => text()();

  /// Discriminator for the mutation kind — one of the 27 values listed
  /// in STATE.md. Drives the dispatch table in `SyncEngine` and the
  /// `SyncMutation.fromOutboxEntry` switch.
  TextColumn get mutationType => text()();

  /// Serialized request body (`request.toJson()`) as JSON text. Body-less
  /// mutations (admit/approve/reject) store `'{}'`.
  TextColumn get payload => text()();

  /// Optimistic-locking version expected at the backend. Forward-compat
  /// (D1 (a)): written today, ignored by Vapor today, used when
  /// concurrency control lands. Never decremented.
  IntColumn get expectedVersion => integer()();

  /// Wall-clock at enqueue. FIFO ordering of the drain depends on this
  /// being monotonic per producer; concurrent producers are tie-broken
  /// by SQL row order (acceptable — A18b serializes writes per
  /// aggregate).
  DateTimeColumn get createdAt => dateTime()();

  /// Number of attempts that have failed (retriable) so far. Read by
  /// `RetryPolicy.shouldRetry` to decide pending vs. failed_dead.
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();

  /// Wall-clock of the most recent attempt (success or failure). Null
  /// before the first dispatch.
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();

  /// Human-readable error string from the most recent failure. Cleared
  /// implicitly when the row resets to pending.
  TextColumn get lastError => text().nullable()();

  /// Lifecycle state. Lowercase snake_case; see `OutboxStatus` for the
  /// canonical enum. `pending` | `in_flight` | `failed_retriable` |
  /// `failed_dead` | `completed`.
  TextColumn get status => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
