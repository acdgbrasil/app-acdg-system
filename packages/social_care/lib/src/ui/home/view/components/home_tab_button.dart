import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class HomeTabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const HomeTabButton({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.textPrimary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
