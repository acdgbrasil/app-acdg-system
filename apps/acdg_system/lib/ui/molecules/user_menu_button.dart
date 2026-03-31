import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import '../atoms/role_badge.dart';

class UserMenuButton extends StatelessWidget {
  const UserMenuButton({super.key, required this.user, required this.onLogout});

  final AuthUser user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      onSelected: (value) {
        if (value == 'logout') onLogout();
      },
      color: AppColors.background,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AcdgText(
                user.displayName,
                variant: AcdgTextVariant.headingSmall,
                color: AppColors.textPrimary,
              ),
              if (user.email != null)
                AcdgText(
                  user.email!,
                  variant: AcdgTextVariant.caption,
                  color: AppColors.textMuted,
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: user.roles
                    .map((role) => RoleBadge(role: role))
                    .toList(),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: const [
              Icon(Icons.logout, size: 18, color: AppColors.danger),
              SizedBox(width: 8),
              AcdgText(
                'Sair',
                variant: AcdgTextVariant.bodyLarge,
                color: AppColors.danger,
              ),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Text(
                _initials(user),
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnDark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: AcdgText(
                user.displayName,
                variant: AcdgTextVariant.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: AppColors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }

  String _initials(AuthUser user) {
    final name = user.name ?? user.preferredUsername ?? '';
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';

    final first = parts.first[0].toUpperCase();
    if (parts.length == 1) return first;

    final last = parts.last[0].toUpperCase();
    return '$first$last';
  }
}
