import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../molecules/module_card.dart';
import '../molecules/stat_card.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key, required this.user});

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
              // 1) Personalized greeting
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
              const SizedBox(height: AppSpacing.space3),
              AcdgText(
                'Plataforma de cuidado e defesa de pacientes com doencas geneticas raras.',
                variant: AcdgTextVariant.bodyLarge,
                color: AppColors.textMuted,
              ),

              const SizedBox(height: AppSpacing.space7),

              // Stats row
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.people_outline,
                      label: 'Familias',
                      value: '--',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: StatCard(
                      icon: Icons.assignment_outlined,
                      label: 'Atendimentos',
                      value: '--',
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: StatCard(
                      icon: Icons.pending_actions_outlined,
                      label: 'Pendentes',
                      value: '--',
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.space7),

              // Section label
              AcdgText(
                'Modulos',
                variant: AcdgTextVariant.headingSmall,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppSpacing.space3),

              // Module card
              ModuleCard(
                icon: user.canWrite
                    ? Icons.people_outline
                    : Icons.visibility_outlined,
                title: user.canWrite
                    ? 'Social Care'
                    : 'Social Care (somente leitura)',
                subtitle: user.canWrite
                    ? 'Cadastro, avaliacao e acompanhamento de pacientes'
                    : 'Visualizacao de dados de pacientes',
                accentColor: AppColors.primary,
                onTap: () => context.push('/social-care'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
