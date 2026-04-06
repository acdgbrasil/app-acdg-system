import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class WizardNavLink extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const WizardNavLink({
    super.key,
    required this.label,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      label,
      style: const TextStyle(
        fontFamily: 'Satoshi',
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ).copyWith(
        color: AppColors.textPrimary,
        decoration: isActive ? TextDecoration.underline : null,
      ),
    );

    if (onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: onTap, child: textWidget),
      );
    }
    return textWidget;
  }
}
