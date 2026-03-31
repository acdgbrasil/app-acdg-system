import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:core/core.dart';

/// An atomic widget that displays the current synchronization status.
class SyncIndicator extends StatelessWidget {
  final ValueNotifier<SyncStatus> status;
  final VoidCallback? onTap;

  const SyncIndicator({super.key, required this.status, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: status,
      builder: (context, _) {
        final currentStatus = status.value;

        return Tooltip(
          message: _getMessage(currentStatus),
          child: MouseRegion(
            cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
            child: GestureDetector(
              onTap: onTap,
              child: _getIcon(currentStatus),
            ),
          ),
        );
      },
    );
  }

  Widget _getIcon(SyncStatus status) {
    return switch (status) {
      SyncIdle() => const Icon(
        Icons.cloud_done_outlined,
        color: AppColors.primary,
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
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          AcdgText(
            '$current',
            variant: AcdgTextVariant.caption,
            color: AppColors.primary,
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
        backgroundColor: AppColors.danger,
        child: const Icon(
          Icons.sync_problem_outlined,
          color: AppColors.danger,
          size: 20,
        ),
      ),
    };
  }

  String _getMessage(SyncStatus status) {
    return switch (status) {
      SyncIdle() => 'Tudo sincronizado',
      SyncInProgress(:final current, :final total) =>
        'Sincronizando $current de $total...',
      SyncPending(:final count) =>
        '$count ações aguardando sincronização automática',
      SyncOffline(:final count) => 'Offline: $count ações aguardando conexão',
      SyncError(:final count) =>
        '$count falhas de sincronização. Clique para ver detalhes.',
      SyncConflict(:final count) =>
        '$count conflitos de versão. Clique para ver detalhes.',
    };
  }
}
