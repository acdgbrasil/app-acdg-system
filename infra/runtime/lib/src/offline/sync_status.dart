import 'package:core_contracts/core_contracts.dart';

/// Represents the possible states of the synchronization engine.
sealed class SyncStatus with Equatable {
  const SyncStatus();

  @override
  List<Object?> get props => [];
}

/// No pending actions, everything is synchronized.
final class SyncIdle extends SyncStatus {
  const SyncIdle();
}

/// Currently processing actions from the queue.
final class SyncInProgress extends SyncStatus {
  final int current;
  final int total;

  const SyncInProgress({required this.current, required this.total});

  @override
  List<Object?> get props => [current, total];
}

/// Online but waiting for the next scheduled retry timer.
final class SyncPending extends SyncStatus {
  final int count;
  const SyncPending(this.count);

  @override
  List<Object?> get props => [count];
}

/// Offline, actions are queued but cannot be synchronized.
final class SyncOffline extends SyncStatus {
  final int count;
  const SyncOffline(this.count);

  @override
  List<Object?> get props => [count];
}

/// One or more actions failed permanently (max retries reached).
final class SyncError extends SyncStatus {
  final int count;
  const SyncError(this.count);

  @override
  List<Object?> get props => [count];
}

/// One or more actions have version conflicts (409) requiring user intervention.
final class SyncConflict extends SyncStatus {
  final int count;
  const SyncConflict(this.count);

  @override
  List<Object?> get props => [count];
}
