import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../logic/di/auth_providers.dart';
import '../../logic/di/infrastructure_providers.dart';
import '../atoms/app_logo.dart';
import '../atoms/sync_indicator.dart';
import '../molecules/module_card.dart';
import '../molecules/user_menu_button.dart';

/// The home screen — Module Hub pattern.
///
/// Shows a greeting, the available modules as a grid of cards,
/// and future modules with "em breve" badges. No intermediate
/// data loading — just navigation entry points.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const _appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(authViewModelProvider);
    final syncEngine = ref.watch(syncEngineProvider);

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final user = viewModel.user;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            titleSpacing: 24,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(size: 32),
                const SizedBox(width: 12),
                const AcdgText(
                  'Conecta Raros',
                  variant: AcdgTextVariant.headingSmall,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
            actions: [
              if (syncEngine != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: SyncIndicator(status: syncEngine.status),
                ),
              if (user != null)
                UserMenuButton(user: user, onLogout: viewModel.logout.execute),
            ],
          ),
          body: user != null
              ? _HomeContent(user: user)
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.user});

  final AuthUser user;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  String get _firstName {
    final name = user.name ?? user.preferredUsername ?? '';
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '';
    return parts.first;
  }

  String get _roleLabel => switch (user.roles.firstOrNull) {
    AuthRole.superAdmin => 'Super Administrador',
    AuthRole.worker => 'Assistente Social',
    AuthRole.owner => 'Responsável',
    AuthRole.admin => 'Administrador',
    null => '',
  };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space6,
            vertical: AppSpacing.space7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Greeting ──
              AcdgText(
                '$_greeting${_firstName.isNotEmpty ? ', $_firstName' : ''}',
                variant: AcdgTextVariant.displayLarge,
                color: AppColors.textPrimary,
              ),
              const SizedBox(height: AppSpacing.space2),
              if (_roleLabel.isNotEmpty)
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AcdgText(
                      _roleLabel,
                      variant: AcdgTextVariant.bodyLarge,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),

              const SizedBox(height: AppSpacing.space7),

              // ── Module grid ──
              AcdgText(
                'Módulos',
                variant: AcdgTextVariant.headingSmall,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppSpacing.space3),

              _ModuleGrid(user: user),

              // ── Environment badge (non-production) ──
              if (HomePage._appEnv != 'production') ...[
                const SizedBox(height: AppSpacing.space7),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.4),
                      ),
                    ),
                    child: AcdgText(
                      HomePage._appEnv == 'staging' || HomePage._appEnv == 'hml'
                          ? 'HOMOLOGAÇÃO'
                          : 'DESENVOLVIMENTO',
                      variant: AcdgTextVariant.caption,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleGrid extends StatelessWidget {
  const _ModuleGrid({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      ModuleCard(
        icon: user.canWrite
            ? Icons.people_outline
            : Icons.visibility_outlined,
        title: 'Social Care',
        subtitle: user.canWrite
            ? 'Prontuário social e acompanhamento'
            : 'Visualização de dados (somente leitura)',
        accentColor: AppColors.accent,
        onTap: () => context.push('/social-care'),
      ),
      if (user.hasRole(AuthRole.admin) || user.isSuperAdmin)
        const _ComingSoonCard(
          icon: Icons.group_add_outlined,
          title: 'Equipe',
          subtitle: 'Cadastro e gestão de profissionais',
        ),
      const _ComingSoonCard(
        icon: Icons.queue_outlined,
        title: 'Fila de Atendimento',
        subtitle: 'Triagem e orquestração presencial',
      ),
      const _ComingSoonCard(
        icon: Icons.analytics_outlined,
        title: 'Painel de Gestão',
        subtitle: 'Indicadores e relatórios',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: AppSpacing.space3,
          crossAxisSpacing: AppSpacing.space3,
          childAspectRatio: crossAxisCount == 2 ? 2.8 : 4.0,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cards,
        );
      },
    );
  }
}

/// A module card styled as "coming soon" — same visual weight as
/// [ModuleCard] but with muted colors and a badge.
class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard({
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
      padding: const EdgeInsets.all(AppSpacing.space5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.inputLine),
        boxShadow: const [AppShadows.xsShadow],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.textMuted, size: 40),
          ),
          const SizedBox(width: AppSpacing.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: AcdgText(
                        title,
                        variant: AcdgTextVariant.headingMedium,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const AcdgText(
                        'em breve',
                        variant: AcdgTextVariant.caption,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                AcdgText(
                  subtitle,
                  variant: AcdgTextVariant.bodyLarge,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
