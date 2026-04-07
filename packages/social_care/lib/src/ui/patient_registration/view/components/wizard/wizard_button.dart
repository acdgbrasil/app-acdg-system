import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class WizardButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback? onPressed;

  const WizardButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isPrimary,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isPrimary ? AppColors.primary : Colors.transparent;
    final textColor = isPrimary ? AppColors.background : AppColors.textPrimary;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: isPrimary ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
          side: isPrimary
              ? BorderSide.none
              : const BorderSide(color: AppColors.inputLine, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isPrimary) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Playfair Display',
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              fontSize: 16,
            ),
          ),
          if (isPrimary) ...[const SizedBox(width: 8), Icon(icon, size: 18)],
        ],
      ),
    );
  }
}
