import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_view_model.dart';

/// Home page — entry point after authentication.
///
/// Displays user info, role badge, and navigation to modules.
/// Consumes [AuthViewModel] from Provider (injected in main.dart).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conecta Raros'),
        actions: [
          ValueListenableBuilder<AuthUser?>(
            valueListenable: viewModel.user,
            builder: (context, user, _) {
              if (user == null) return const SizedBox.shrink();
              return _UserMenuButton(user: user, viewModel: viewModel);
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<AuthUser?>(
        valueListenable: viewModel.user,
        builder: (context, user, _) {
          if (user == null) return const SizedBox.shrink();
          return _HomeContent(user: user);
        },
      ),
    );
  }
}

class _UserMenuButton extends StatelessWidget {
  const _UserMenuButton({required this.user, required this.viewModel});

  final AuthUser user;
  final AuthViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      onSelected: (value) {
        if (value == 'logout') viewModel.logout();
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName,
                style: AcdgTypography.labelLarge.copyWith(
                  color: AcdgColors.onSurface,
                ),
              ),
              if (user.email != null)
                Text(
                  user.email!,
                  style: AcdgTypography.bodySmall.copyWith(
                    color: AcdgColors.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: AcdgSpacing.xs),
              Wrap(
                spacing: AcdgSpacing.xs,
                children: user.roles.map((role) => _RoleBadge(role)).toList(),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: AcdgColors.error),
              SizedBox(width: AcdgSpacing.sm),
              Text('Sair'),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AcdgSpacing.md),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AcdgColors.primary,
              child: Text(
                _initials(user),
                style: AcdgTypography.labelSmall.copyWith(
                  color: AcdgColors.onPrimary,
                ),
              ),
            ),
            const SizedBox(width: AcdgSpacing.sm),
            Text(
              user.displayName,
              style: AcdgTypography.labelMedium,
            ),
            const SizedBox(width: AcdgSpacing.xs),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }

  String _initials(AuthUser user) {
    final name = user.name ?? user.preferredUsername ?? '';
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge(this.role);

  final AuthRole role;

  String get _label => switch (role) {
        AuthRole.socialWorker => 'Assistente Social',
        AuthRole.owner => 'Responsavel',
        AuthRole.admin => 'Administrador',
      };

  Color get _color => switch (role) {
        AuthRole.socialWorker => AcdgColors.primary,
        AuthRole.owner => AcdgColors.secondary,
        AuthRole.admin => AcdgColors.navy,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AcdgSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: AcdgRadius.borderSm,
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _label,
        style: AcdgTypography.caption.copyWith(
          color: _color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AcdgSpacing.lg),
      decoration: BoxDecoration(
        color: AcdgColors.surface,
        borderRadius: AcdgRadius.borderMd,
        border: Border.all(color: AcdgColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AcdgColors.primary),
          const SizedBox(width: AcdgSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AcdgTypography.headingSmall.copyWith(
                    color: AcdgColors.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: AcdgTypography.bodySmall.copyWith(
                    color: AcdgColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AcdgColors.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(AcdgSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bem-vindo ao Conecta Raros',
                style: AcdgTypography.headingLarge.copyWith(
                  color: AcdgColors.onSurface,
                ),
              ),
              const SizedBox(height: AcdgSpacing.md),
              Text(
                'Plataforma de cuidado e defesa de pacientes com doencas geneticas raras.',
                style: AcdgTypography.bodyMedium.copyWith(
                  color: AcdgColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AcdgSpacing.xxl),
              _ModuleCard(
                icon: user.canWrite ? Icons.people : Icons.visibility,
                title: user.canWrite
                    ? 'Social Care'
                    : 'Social Care (somente leitura)',
                subtitle: user.canWrite
                    ? 'Cadastro, avaliacao e acompanhamento de pacientes'
                    : 'Visualizacao de dados de pacientes',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
