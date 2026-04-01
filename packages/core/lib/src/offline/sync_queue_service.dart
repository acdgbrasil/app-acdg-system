import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:persistence/persistence.dart';

import 'drift_database_service.dart';

/// Service responsible for managing the sync action queue.
///
/// Provides reactive [watchPendingActions] stream that replaces
/// the former polling-based approach. The SyncEngine subscribes
/// to this stream and processes actions as they become available.
class SyncQueueService {
  final DriftDatabaseService _dbService;

  SyncQueueService(this._dbService);

  AcdgDatabase get _db => _dbService.db;

  /// Enqueues a new action for synchronization.
  Future<void> enqueue({
    required String patientId,
    required String actionType,
    required Map<String, dynamic> payload,
  }) async {
    await _db.into(_db.syncActions).insert(
      SyncActionsCompanion.insert(
        actionId: DateTime.now().millisecondsSinceEpoch.toString(),
        patientId: patientId,
        actionType: actionType,
        payloadJson: jsonEncode(payload),
        timestamp: DateTime.now().toUtc(),
      ),
    );
  }

  /// Returns all pending actions that are ready for processing.
  ///
  /// Filters by status = PENDING and nextRetryAt <= now (or null).
  Future<List<SyncAction>> getPendingActions() async {
    final now = DateTime.now().toUtc();
    final query = _db.select(_db.syncActions)
      ..where(
        (t) =>
            t.status.equals('PENDING') &
            (t.nextRetryAt.isNull() | t.nextRetryAt.isSmallerOrEqualValue(now)),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]);
    return query.get();
  }

  /// Reactive stream that emits whenever pending actions change.
  ///
  /// Watches all PENDING actions from Drift (no time filter in SQL).
  /// The time filter (`nextRetryAt <= now`) is applied in Dart at each
  /// emission so that `DateTime.now()` is always fresh — fixing the
  /// frozen-timestamp bug where retries with future `nextRetryAt` were
  /// permanently excluded from the stream.
  ///
  /// Returns a record with:
  /// - `ready`: actions eligible for processing right now
  /// - `nextRetryAt`: earliest retry time among not-yet-ready actions,
  ///   so the caller can schedule a precise delayed re-check
  Stream<({List<SyncAction> ready, DateTime? nextRetryAt})>
      watchPendingActions() {
    final query = _db.select(_db.syncActions)
      ..where((t) => t.status.equals('PENDING'))
      ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]);

    return query.watch().map((actions) {
      final now = DateTime.now().toUtc();
      final ready = <SyncAction>[];
      DateTime? earliestRetry;

      for (final action in actions) {
        if (action.nextRetryAt == null || !action.nextRetryAt!.isAfter(now)) {
          ready.add(action);
        } else {
          final retryAt = action.nextRetryAt!;
          if (earliestRetry == null || retryAt.isBefore(earliestRetry)) {
            earliestRetry = retryAt;
          }
        }
      }

      return (ready: ready, nextRetryAt: earliestRetry);
    });
  }

  /// Returns all actions in the queue (any status).
  Future<List<SyncAction>> getAllActions() async {
    return (_db.select(_db.syncActions)
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .get();
  }

  /// Updates the status of a sync action by [id].
  Future<void> updateStatus(int id, String status, {String? error}) async {
    final companion = SyncActionsCompanion(
      status: Value(status),
      lastError: error != null ? Value(error) : const Value.absent(),
    );
    await (_db.update(_db.syncActions)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  /// Marks an action as failed with exponential backoff retry scheduling.
  ///
  /// After 10 retries, the action is permanently marked as FAILED.
  Future<void> markFailed(int id, String error) async {
    final action =
        await (_db.select(_db.syncActions)..where((t) => t.id.equals(id)))
            .getSingleOrNull();
    if (action == null) return;

    final newRetryCount = action.retryCount + 1;

    if (newRetryCount >= 10) {
      await (_db.update(_db.syncActions)..where((t) => t.id.equals(id))).write(
        SyncActionsCompanion(
          status: const Value('FAILED'),
          retryCount: Value(newRetryCount),
          lastError: Value(error),
        ),
      );
    } else {
      final seconds = min(pow(2, newRetryCount) * 5, 300).toInt();
      final nextRetry = DateTime.now().toUtc().add(Duration(seconds: seconds));

      await (_db.update(_db.syncActions)..where((t) => t.id.equals(id))).write(
        SyncActionsCompanion(
          status: const Value('PENDING'),
          retryCount: Value(newRetryCount),
          lastError: Value(error),
          nextRetryAt: Value(nextRetry),
        ),
      );
    }
  }

  /// Marks an action as CONFLICT (409 version mismatch).
  Future<void> markConflict(int id, String details) async {
    await (_db.update(_db.syncActions)..where((t) => t.id.equals(id))).write(
      SyncActionsCompanion(
        status: const Value('CONFLICT'),
        conflictDetails: Value(details),
      ),
    );
  }

  /// Removes a sync action after successful synchronization.
  Future<void> removeAction(int id) async {
    await (_db.delete(_db.syncActions)..where((t) => t.id.equals(id))).go();
  }

  /// Removes all actions from the sync queue.
  Future<void> clearAllActions() async {
    await _db.delete(_db.syncActions).go();
  }
}
