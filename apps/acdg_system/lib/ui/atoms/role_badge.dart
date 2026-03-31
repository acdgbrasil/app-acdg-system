import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role});

  final AuthRole role;

  String get _label => switch (role) {
    AuthRole.socialWorker => 'Assistente Social',
    AuthRole.owner => 'Responsável',
    AuthRole.admin => 'Administrador',
  };

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      AuthRole.socialWorker => AppColors.primary,
      AuthRole.owner => const Color(
        0xFF0477BF,
      ), // Azul secundário (provisório até novo token)
      AuthRole.admin => AppColors.textPrimary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: AcdgText(_label, variant: AcdgTextVariant.caption, color: color),
    );
  }
}
