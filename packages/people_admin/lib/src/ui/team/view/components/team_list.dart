import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../../domain/models/team_member.dart';
import '../../constants/team_l10n.dart';
import 'team_member_row.dart';

/// Scrollable list of team members with M3 dividers.
///
/// Uses [ListView.separated] with inset dividers (indent = avatar width).
/// Bottom padding reserves space for the FAB.
class TeamList extends StatelessWidget {
  final List<TeamMember> members;
  final void Function(String personId, bool activate) onToggle;
  final void Function(String personId) onResetPassword;

  const TeamList({
    super.key,
    required this.members,
    required this.onToggle,
    required this.onResetPassword,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.group_outlined,
                size: 48,
                color: AppColors.textMuted.withValues(alpha: 0.4),
              ),
              const SizedBox(height: AppSpacing.space3),
              const AcdgText(
                TeamL10n.emptyState,
                variant: AcdgTextVariant.bodyMedium,
                color: AppColors.textMuted,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: members.length,
      separatorBuilder:
          (_, _) =>
              const Divider(height: 1, indent: 72, color: AppColors.border),
      itemBuilder: (context, index) {
        return TeamMemberRow(
          member: members[index],
          onToggle: onToggle,
          onResetPassword: onResetPassword,
        );
      },
    );
  }
}
