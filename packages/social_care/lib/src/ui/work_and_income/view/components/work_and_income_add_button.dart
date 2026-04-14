import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class WorkAndIncomeAddButton extends StatelessWidget {
  const WorkAndIncomeAddButton({
    super.key,
    required this.label,
    required this.onTap,
  });
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 14,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
