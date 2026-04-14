import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Shared header for all assessment pages.
///
/// Shows title + patient name subtitle.
/// Pure Selector widget.
class AssessmentHeader extends StatelessWidget {
  const AssessmentHeader({
    super.key,
    required this.title,
    this.patientName,
  });

  final String title;
  final String? patientName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 4, 48, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w700,
              fontSize: 38,
              letterSpacing: -1,
              color: AppColors.textPrimary,
            ),
          ),
          if (patientName != null && patientName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              patientName!,
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: AppColors.textPrimary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
