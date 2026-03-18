import 'package:auth/auth.dart';
import 'package:flutter/material.dart';

class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role});

  final AuthRole role;

  String get _label => switch (role) {
        AuthRole.socialWorker => 'Assistente Social',
        AuthRole.owner => 'Responsavel',
        AuthRole.admin => 'Administrador',
      };

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      AuthRole.socialWorker => Theme.of(context).colorScheme.primary,
      AuthRole.owner => Theme.of(context).colorScheme.secondary,
      AuthRole.admin => Theme.of(context).colorScheme.tertiary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
