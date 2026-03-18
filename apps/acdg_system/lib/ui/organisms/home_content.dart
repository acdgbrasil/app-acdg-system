import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../molecules/module_card.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bem-vindo ao ACDG System',
                style: textTheme.headlineLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Plataforma de cuidado e defesa de pacientes com doencas geneticas raras.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ModuleCard(
                icon: user.canWrite ? Icons.people : Icons.visibility,
                title: user.canWrite
                    ? 'Social Care'
                    : 'Social Care (somente leitura)',
                subtitle: user.canWrite
                    ? 'Cadastro, avaliacao e acompanhamento de pacientes'
                    : 'Visualizacao de dados de pacientes',
                onTap: () => context.push('/social-care'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
