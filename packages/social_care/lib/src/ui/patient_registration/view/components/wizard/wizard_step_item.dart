import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class WizardStepItem extends StatelessWidget {
  final int number;
  final String label;
  final bool isActive;
  final bool isCompleted;

  const WizardStepItem({
    super.key,
    required this.number,
    required this.label,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = AppBreakpoints.isMobile(screenWidth);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? AppColors.primary
                : (isActive ? AppColors.textPrimary : Colors.transparent),
            border: Border.all(
              color: isCompleted
                  ? AppColors.primary
                  : (isActive ? AppColors.textPrimary : AppColors.inputLine),
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: AppColors.background)
                : Text(
                    '$number',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isActive
                          ? AppColors.background
                          : AppColors.textMuted,
                    ),
                  ),
          ),
        ),
        if (!isMobile) ...[
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}
