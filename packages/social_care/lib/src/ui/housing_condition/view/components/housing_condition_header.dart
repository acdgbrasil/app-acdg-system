import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../constants/housing_condition_l10n.dart';

class HousingConditionHeader extends StatelessWidget {
  const HousingConditionHeader({super.key, required this.patientName});

  final String patientName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 4, 48, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            HousingConditionL10n.pageTitle,
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
