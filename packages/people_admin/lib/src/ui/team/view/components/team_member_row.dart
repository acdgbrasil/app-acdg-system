import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../../domain/models/team_member.dart';
import '../../constants/team_l10n.dart';

/// M3 two-line list item for a team member.
///
/// Layout: [Avatar] [Name / CPF | Status] [Role badge] [⋮ actions]
/// Follows Material 3 list specs: 72dp height, 16dp leading padding,
/// 24dp trailing padding, 48dp touch target for actions.
class TeamMemberRow extends StatelessWidget {
  final TeamMember member;
  final void Function(String personId, bool activate) onToggle;
  final void Function(String personId) onResetPassword;

  const TeamMemberRow({
    super.key,
    required this.member,
    required this.onToggle,
    required this.onResetPassword,
  });

  String get _roleLabel => switch (member.role) {
    'social_worker' => TeamL10n.roleSocialWorker,
    'admin' => TeamL10n.roleAdmin,
    _ => TeamL10n.roleUnknown,
  };

  String get _initials {
    final parts = member.fullName.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String get _statusLine {
    final parts = <String>[];
    if (member.cpf != null && member.cpf!.isNotEmpty) {
      parts.add(member.cpf!);
    }
    parts.add(member.active ? TeamL10n.statusActive : TeamL10n.statusInactive);
    return parts.join(' | ');
  }

  @override
  Widget build(BuildContext context) {
    final isActive = member.active;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
        ),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor:
              isActive
                  ? AppColors.accent.withValues(alpha: 0.12)
                  : AppColors.textMuted.withValues(alpha: 0.12),
          child: AcdgText(
            _initials,
            variant: AcdgTextVariant.bodyMedium,
            color: isActive ? AppColors.accent : AppColors.textMuted,
          ),
        ),
        title: AcdgText(
          member.fullName,
          variant: AcdgTextVariant.bodyMedium,
          color: isActive ? AppColors.textPrimary : AppColors.textMuted,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: AcdgText(
          _statusLine,
          variant: AcdgTextVariant.caption,
          color:
              isActive
                  ? AppColors.textMuted
                  : AppColors.textMuted.withValues(alpha: 0.6),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AcdgBadge(
              label: _roleLabel,
              color: isActive ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.space2),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                color: AppColors.textMuted,
                size: 20,
              ),
              tooltip: 'Ações',
              color: AppColors.backgroundDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (action) {
                switch (action) {
                  case 'toggle':
                    onToggle(member.personId, !isActive);
                  case 'reset_password':
                    onResetPassword(member.personId);
                }
              },
              itemBuilder:
                  (_) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            isActive ? Icons.block : Icons.check_circle_outline,
                            color:
                                isActive ? AppColors.danger : AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.space2),
                          AcdgText(
                            isActive
                                ? TeamL10n.actionDeactivate
                                : TeamL10n.actionReactivate,
                            variant: AcdgTextVariant.caption,
                            color: AppColors.textOnDark,
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'reset_password',
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_reset,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                          SizedBox(width: AppSpacing.space2),
                          AcdgText(
                            TeamL10n.actionResetPassword,
                            variant: AcdgTextVariant.caption,
                            color: AppColors.textOnDark,
                          ),
                        ],
                      ),
                    ),
                  ],
            ),
          ],
        ),
      ),
    );
  }
}
