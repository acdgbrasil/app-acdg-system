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
              if (user.email != null) ...[
                const SizedBox(height: 4),
                AcdgText(
                  user.email!,
                  variant: AcdgTextVariant.caption,
                  color: AppColors.textMuted,
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children:
                    user.roles.map((role) => RoleBadge(role: role)).toList(),
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
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Text(
                _initials(user),
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnDark,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AcdgText(
                    _shortName(user),
                    variant: AcdgTextVariant.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user.roles.isNotEmpty)
                    AcdgText(
                      _roleLabel(user),
                      variant: AcdgTextVariant.caption,
                      color: AppColors.textMuted,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: AppColors.textMuted,
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

  /// Shows first name + last initial instead of full ID.
  String _shortName(AuthUser user) {
    final name = user.name ?? user.preferredUsername;
    if (name == null || name.trim().isEmpty) {
      // Fallback: show email or truncated ID
      if (user.email != null) return user.email!;
      final id = user.id;
      return id.length > 12 ? '${id.substring(0, 12)}...' : id;
    }

    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.length <= 2) return name.trim();

    // "Joao da Silva Pereira" -> "Joao S. Pereira"
    return '${parts.first} ${parts.last}';
  }

  String _roleLabel(AuthUser user) => switch (user.roles.firstOrNull) {
    AuthRole.superAdmin => 'Super Administrador',
    AuthRole.worker => 'Assistente Social',
    AuthRole.owner => 'Responsável',
    AuthRole.admin => 'Administrador',
    null => '',
  };
}
