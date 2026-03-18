import 'package:flutter/material.dart';
import 'package:core/core.dart';

/// An atomic widget that displays the current synchronization status.
///
/// Listens to a [ValueNotifier<SyncStatus>] and updates its icon and color accordingly.
class SyncIndicator extends StatelessWidget {
  final ValueNotifier<SyncStatus> status;

  const SyncIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: status,
      builder: (context, _) {
        final currentStatus = status.value;

        return Tooltip(
          message: _getMessage(currentStatus),
          child: _getIcon(currentStatus),
        );
      },
    );
  }

  Widget _getIcon(SyncStatus status) {
    return switch (status) {
      SyncIdle() => const Icon(
          Icons.cloud_done_outlined,
          color: Colors.green,
          size: 20,
        ),
      SyncInProgress(:final current) => Stack(
          alignment: Alignment.center,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            Text(
              '$current',
              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      SyncPending(:final count) || SyncOffline(:final count) => Badge(
          label: Text('$count'),
          backgroundColor: Colors.orange,
          child: const Icon(
            Icons.cloud_queue_outlined,
            color: Colors.orange,
            size: 20,
          ),
        ),
      SyncError(:final count) || SyncConflict(:final count) => Badge(
          label: Text('$count'),
          backgroundColor: Colors.red,
          child: const Icon(
            Icons.sync_problem_outlined,
            color: Colors.red,
            size: 20,
          ),
        ),
    };
  }

  String _getMessage(SyncStatus status) {
    return switch (status) {
      SyncIdle() => 'Tudo sincronizado',
      SyncInProgress(:final current, :final total) => 'Sincronizando $current de $total...',
      SyncPending(:final count) => '$count acções aguardando sincronização automática',
      SyncOffline(:final count) => 'Offline: $count acções aguardando conexão',
      SyncError(:final count) => '$count falhas de sincronização. Clique para ver detalhes.',
      SyncConflict(:final count) => '$count conflitos de versão detectados.',
    };
  }
}
