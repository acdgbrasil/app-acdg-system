import 'dart:convert';
import 'dart:math';
import 'package:persistence/persistence.dart';
import 'isar_service.dart';

/// Service responsible for managing the queue of actions to be synchronized with the backend.
class SyncQueueService {
  final IsarService _isarService;

  SyncQueueService(this._isarService);

  /// Enqueues a new action for synchronization.
  Future<void> enqueue({
    required String patientId,
    required String actionType,
    required Map<String, dynamic> payload,
  }) async {
    final action = SyncAction()
      ..actionId = DateTime.now().millisecondsSinceEpoch.toString()
      ..patientId = patientId
      ..actionType = actionType
      ..payloadJson = jsonEncode(payload)
      ..timestamp = DateTime.now().toUtc()
      ..status = 'PENDING'
      ..retryCount = 0;

    await _isarService.db.writeTxn(() async {
      await _isarService.db.syncActions.put(action);
    });
  }

  /// Returns all pending actions that are ready for retry.
  Future<List<SyncAction>> getPendingActions() async {
    final now = DateTime.now().toUtc();
    return await _isarService.db.syncActions
        .filter()
        .statusEqualTo('PENDING')
        .and()
        .group((q) => q
            .nextRetryAtIsNull()
            .or()
            .nextRetryAtLessThan(now))
        .sortByTimestamp()
        .findAll();
  }

  /// Returns all actions in the queue (pending, failed, conflict, etc).
  Future<List<SyncAction>> getAllActions() async {
    return await _isarService.db.syncActions.where().findAll();
  }

  /// Updates the status of a sync action.
  Future<void> updateStatus(Id id, String status, {String? error}) async {
    await _isarService.db.writeTxn(() async {
      final action = await _isarService.db.syncActions.get(id);
      if (action != null) {
        action.status = status;
        if (error != null) action.lastError = error;
        await _isarService.db.syncActions.put(action);
      }
    });
  }

  /// Marks an action as failed and schedules a retry with exponential backoff.
  Future<void> markFailed(Id id, String error) async {
    await _isarService.db.writeTxn(() async {
      final action = await _isarService.db.syncActions.get(id);
      if (action != null) {
        action.retryCount++;
        action.lastError = error;
        
        if (action.retryCount >= 10) {
          action.status = 'FAILED'; // Permanent failure
        } else {
          action.status = 'PENDING';
          // Exponential backoff: 5s, 10s, 20s, 40s... up to 5 min
          final seconds = min(pow(2, action.retryCount) * 5, 300).toInt();
          action.nextRetryAt = DateTime.now().toUtc().add(Duration(seconds: seconds));
        }
        
        await _isarService.db.syncActions.put(action);
      }
    });
  }

  /// Marks an action as CONFLICT.
  Future<void> markConflict(Id id, String details) async {
    await _isarService.db.writeTxn(() async {
      final action = await _isarService.db.syncActions.get(id);
      if (action != null) {
        action.status = 'CONFLICT';
        action.conflictDetails = details;
        await _isarService.db.syncActions.put(action);
      }
    });
  }

  /// Deletes a sync action.
  Future<void> removeAction(Id id) async {
    await _isarService.db.writeTxn(() async {
      await _isarService.db.syncActions.delete(id);
    });
  }
}
