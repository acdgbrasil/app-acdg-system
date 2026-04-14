import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Shared navigation bar for all assessment pages.
///
/// Shows breadcrumb: Famílias > [pageName]
/// Pure Selector widget — receives only display data.
class AssessmentNavBar extends StatelessWidget {
  const AssessmentNavBar({
    super.key,
    required this.familiesLabel,
    required this.currentPageLabel,
  });

  final String familiesLabel;
  final String currentPageLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      child: Row(
        children: [
          Column(
            children: [
              Container(height: 2, width: 24, color: AppColors.textPrimary),
              const SizedBox(height: 5),
              Container(height: 2, width: 24, color: AppColors.textPrimary),
              const SizedBox(height: 5),
              Container(height: 2, width: 24, color: AppColors.textPrimary),
            ],
          ),
          const SizedBox(width: 24),
          Text(
            familiesLabel,
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textPrimary.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(width: 24),
          Text(
            currentPageLabel,
            style: const TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textPrimary,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
