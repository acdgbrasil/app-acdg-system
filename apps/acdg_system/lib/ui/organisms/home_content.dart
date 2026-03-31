import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../molecules/module_card.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space6, // 40px
            vertical: AppSpacing.space9, // 64px
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AcdgText(
                'Bem-vindo ao ACDG System',
                variant: AcdgTextVariant.displayLarge,
                color: AppColors.textPrimary,
              ),
              const SizedBox(height: AppSpacing.space3),
              AcdgText(
                'Plataforma de cuidado e defesa de pacientes com doenças genéticas raras.',
                variant: AcdgTextVariant.bodyLarge,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppSpacing.space10), // 72px gap
              ModuleCard(
                icon: user.canWrite
                    ? Icons.people_outline
                    : Icons.visibility_outlined,
                title: user.canWrite
                    ? 'Social Care'
                    : 'Social Care (somente leitura)',
                subtitle: user.canWrite
                    ? 'Cadastro, avaliação e acompanhamento de pacientes'
                    : 'Visualização de dados de pacientes',
                onTap: () => context.push('/social-care'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
