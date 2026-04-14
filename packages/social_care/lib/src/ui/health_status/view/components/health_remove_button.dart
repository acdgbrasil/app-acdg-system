import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class HealthRemoveButton extends StatelessWidget {
  const HealthRemoveButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(
          Icons.remove_circle_outline,
          size: 16,
          color: AppColors.danger,
        ),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 13,
            color: AppColors.danger,
          ),
        ),
      ),
    );
  }
}
