import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../constants/health_status_l10n.dart';

class HealthStatusHeader extends StatelessWidget {
  const HealthStatusHeader({super.key, required this.patientName});

  final String patientName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 4, 48, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            HealthStatusL10n.pageTitle,
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w700,
              fontSize: 38,
              letterSpacing: -1,
              color: AppColors.textPrimary,
            ),
          ),
          if (patientName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              patientName,
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
