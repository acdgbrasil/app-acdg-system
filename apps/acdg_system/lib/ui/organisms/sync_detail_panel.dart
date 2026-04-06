import 'dart:ui';
import 'package:core/core_offline.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persistence/persistence.dart';
import 'package:social_care_desktop/social_care_desktop.dart';

/// Panel that shows sync queue details — failed and conflicting actions.
class SyncDetailPanel extends StatefulWidget {
  final SyncQueueService queueService;
  final SyncEngine syncEngine;
  final DriftDatabaseService? dbService;

  const SyncDetailPanel({
    super.key,
    required this.queueService,
    required this.syncEngine,
    this.dbService,
  });

  static Future<void> show(
    BuildContext context, {
    required SyncQueueService queueService,
    required SyncEngine syncEngine,
    DriftDatabaseService? dbService,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0x73261D11),
      builder: (_) => SyncDetailPanel(
        queueService: queueService,
        syncEngine: syncEngine,
        dbService: dbService,
      ),
    );
  }

  @override
  State<SyncDetailPanel> createState() => _SyncDetailPanelState();
}

class _SyncDetailPanelState extends State<SyncDetailPanel> {
  List<SyncAction> _actions = [];
  bool _loading = true;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    _loadActions();
  }

  Future<void> _loadActions() async {
    setState(() => _loading = true);
    final actions = await widget.queueService.getAllActions();
    setState(() {
      _actions = actions;
      _loading = false;
    });
  }

  void _copyErrorsToClipboard() {
    final buffer = StringBuffer();
    buffer.writeln('=== SYNC QUEUE REPORT ===');
    buffer.writeln('Total: ${_actions.length} ações');
    buffer.writeln('Failed: ${_actions.where((a) => a.status == "FAILED").length}');
    buffer.writeln('Conflict: ${_actions.where((a) => a.status == "CONFLICT").length}');
    buffer.writeln('Pending: ${_actions.where((a) => a.status == "PENDING").length}');
    buffer.writeln('');

    for (final action in _actions) {
      buffer.writeln('--- ${action.actionType} ---');
      buffer.writeln('  Status: ${action.status}');
      buffer.writeln('  Patient: ${action.patientId}');
      buffer.writeln('  Retries: ${action.retryCount}');
      buffer.writeln('  Timestamp: ${action.timestamp.toIso8601String()}');
      if (action.lastError != null) {
        buffer.writeln('  Error: ${action.lastError}');
      }
      if (action.conflictDetails != null) {
        buffer.writeln('  Conflict: ${action.conflictDetails}');
      }
      buffer.writeln('');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erros copiados para a área de transferência'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _clearLocalCache() async {
    final dbService = widget.dbService;
    if (dbService == null) return;

    setState(() => _loading = true);

    await widget.queueService.clearAllActions();
    await dbService.clearAllPatients();

    // Pull fresh data from server
    await widget.syncEngine.pullPatients();
    await widget.syncEngine.refreshStatus();
    await _loadActions();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache local limpo e dados atualizados do servidor'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _syncNow() async {
    setState(() => _retrying = true);

    // Reset FAILED back to PENDING so they get retried
    for (final action in _actions.where((a) => a.status == 'FAILED')) {
      await widget.queueService.updateStatus(action.id, 'PENDING');
    }

    // Trigger sync (force — bypass connectivity check)
    await widget.syncEngine.forceSyncNow();
    await widget.syncEngine.refreshStatus();
    await _loadActions();

    setState(() => _retrying = false);
  }

  Future<void> _retrySingle(SyncAction action) async {
    await widget.queueService.updateStatus(action.id, 'PENDING');
    await widget.syncEngine.processQueue();
    await widget.syncEngine.refreshStatus();
    await _loadActions();
  }

  Future<void> _dismissAction(SyncAction action) async {
    await widget.queueService.removeAction(action.id);
    await widget.syncEngine.refreshStatus();
    await _loadActions();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 600),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF172D48),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x4D172D48),
                  blurRadius: 64,
                  offset: Offset(0, 24),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(color: Color(0xFFF2E2C4)),
                  )
                else if (_actions.isEmpty)
                  _buildEmptyState()
                else
                  _buildActionList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final failedCount = _actions.where((a) => a.status == 'FAILED').length;
    final conflictCount = _actions.where((a) => a.status == 'CONFLICT').length;
    final pendingCount = _actions.where((a) => a.status == 'PENDING').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Sincronização',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                    color: Color(0xFFF2E2C4),
                    letterSpacing: -0.02 * 28,
                  ),
                ),
              ),
              _CircleClose(onTap: () => Navigator.of(context).pop()),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_actions.isNotEmpty)
                _HeaderAction(
                  label: 'Copiar log',
                  icon: Icons.copy_rounded,
                  onTap: _copyErrorsToClipboard,
                ),
              if (_actions.isNotEmpty)
                _HeaderAction(
                  label: failedCount > 0 ? 'Tentar tudo' : 'Sincronizar',
                  icon: Icons.sync_rounded,
                  isLoading: _retrying,
                  onTap: _syncNow,
                ),
              if (widget.dbService != null)
                _HeaderAction(
                  label: 'Limpar cache',
                  icon: Icons.delete_sweep_rounded,
                  onTap: _clearLocalCache,
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Summary chips
          Wrap(
            spacing: 8,
            children: [
              if (pendingCount > 0) _StatusChip(label: '$pendingCount pendentes', color: Colors.orange),
              if (failedCount > 0) _StatusChip(label: '$failedCount falhas', color: const Color(0xFFA6290D)),
              if (conflictCount > 0) _StatusChip(label: '$conflictCount conflitos', color: const Color(0xFFC4441F)),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0x26F2E2C4), height: 1),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(Icons.cloud_done_outlined, size: 48, color: Color(0xFF4F8448)),
          SizedBox(height: 16),
          Text(
            'Fila de sincronização vazia',
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontStyle: FontStyle.italic,
              fontSize: 16,
              color: Color(0x80F2E2C4),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Todos os dados estão sincronizados com o servidor.',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 13,
              color: Color(0x60F2E2C4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionList() {
    // Sort: FAILED first, then CONFLICT, then PENDING
    final sorted = [..._actions]..sort((a, b) {
      const order = {'FAILED': 0, 'CONFLICT': 1, 'IN_PROGRESS': 2, 'PENDING': 3};
      return (order[a.status] ?? 4).compareTo(order[b.status] ?? 4);
    });

    return Flexible(
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
        itemCount: sorted.length,
        separatorBuilder: (_, _) => const Divider(color: Color(0x15F2E2C4), height: 1),
        itemBuilder: (context, index) {
          final action = sorted[index];
          return _ActionRow(
            action: action,
            onRetry: () => _retrySingle(action),
            onDismiss: () => _dismissAction(action),
          );
        },
      ),
    );
  }
}

// ─── Sub-components ──────────────────────────────────────────

class _HeaderAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;

  const _HeaderAction({
    required this.label,
    required this.icon,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF4F8448),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF2E2C4)),
                )
              else
                Icon(icon, size: 14, color: const Color(0xFFF2E2C4)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFFF2E2C4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleClose extends StatelessWidget {
  final VoidCallback onTap;
  const _CircleClose({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x66F2E2C4), width: 1.5),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.close, size: 16, color: Color(0xFFA6290D)),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Satoshi',
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: color,
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final SyncAction action;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  const _ActionRow({
    required this.action,
    required this.onRetry,
    required this.onDismiss,
  });

  Color get _statusColor => switch (action.status) {
    'FAILED' => const Color(0xFFA6290D),
    'CONFLICT' => const Color(0xFFC4441F),
    'PENDING' => Colors.orange,
    'IN_PROGRESS' => const Color(0xFF4F8448),
    _ => const Color(0x80F2E2C4),
  };

  String get _statusLabel => switch (action.status) {
    'FAILED' => 'Falha',
    'CONFLICT' => 'Conflito',
    'PENDING' => 'Pendente',
    'IN_PROGRESS' => 'Em progresso',
    _ => action.status,
  };

  String get _actionLabel => switch (action.actionType) {
    'REGISTER_PATIENT' => 'Cadastro de paciente',
    'ADD_FAMILY_MEMBER' => 'Adicionar membro familiar',
    'REMOVE_FAMILY_MEMBER' => 'Remover membro familiar',
    'ASSIGN_CAREGIVER' => 'Atribuir cuidador',
    'UPDATE_SOCIAL_IDENTITY' => 'Identidade social',
    'UPDATE_HOUSING' => 'Condições de moradia',
    'UPDATE_SOCIO_ECONOMIC' => 'Situação socioeconômica',
    'UPDATE_WORK_AND_INCOME' => 'Trabalho e renda',
    'UPDATE_EDUCATION' => 'Condições educacionais',
    'UPDATE_HEALTH' => 'Condições de saúde',
    'UPDATE_COMMUNITY_SUPPORT' => 'Rede de apoio comunitário',
    'UPDATE_SOCIAL_HEALTH' => 'Resumo sociossanitário',
    'REGISTER_APPOINTMENT' => 'Atendimento',
    'UPDATE_INTAKE' => 'Acolhimento',
    'UPDATE_PLACEMENT' => 'Histórico institucional',
    'REPORT_VIOLATION' => 'Violação de direitos',
    'CREATE_REFERRAL' => 'Encaminhamento',
    _ => action.actionType,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: action type + status + buttons
          Row(
            children: [
              // Status dot
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(shape: BoxShape.circle, color: _statusColor),
              ),
              // Action name
              Expanded(
                child: Text(
                  _actionLabel,
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFFF2E2C4),
                  ),
                ),
              ),
              // Status label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: _statusColor,
                  ),
                ),
              ),
              // Action buttons
              if (action.status == 'FAILED' || action.status == 'CONFLICT') ...[
                const SizedBox(width: 8),
                _SmallButton(
                  icon: Icons.refresh,
                  tooltip: 'Tentar novamente',
                  onTap: onRetry,
                ),
                const SizedBox(width: 4),
                _SmallButton(
                  icon: Icons.delete_outline,
                  tooltip: 'Descartar',
                  color: const Color(0xFFA6290D),
                  onTap: onDismiss,
                ),
              ],
            ],
          ),
          // Error details
          if (action.lastError != null && action.lastError!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(left: 18),
              decoration: BoxDecoration(
                color: const Color(0x0DF2E2C4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                action.lastError!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Consolas',
                  fontSize: 11,
                  color: Color(0x80F2E2C4),
                  height: 1.5,
                ),
              ),
            ),
          ],
          // Conflict details
          if (action.conflictDetails != null && action.conflictDetails!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(left: 18),
              decoration: BoxDecoration(
                color: const Color(0x15C4441F),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                action.conflictDetails!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Consolas',
                  fontSize: 11,
                  color: Color(0xFFC4441F),
                  height: 1.5,
                ),
              ),
            ),
          ],
          // Meta: retry count + timestamp
          Padding(
            padding: const EdgeInsets.only(left: 18, top: 4),
            child: Text(
              '${action.retryCount > 0 ? "${action.retryCount} tentativas · " : ""}'
              'ID: ${action.patientId.substring(0, 8)}…',
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 11,
                color: Color(0x50F2E2C4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _SmallButton({
    required this.icon,
    required this.tooltip,
    this.color = const Color(0xFFF2E2C4),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 14, color: color),
          ),
        ),
      ),
    );
  }
}
