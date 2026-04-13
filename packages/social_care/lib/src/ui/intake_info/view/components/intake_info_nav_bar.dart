import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../constants/intake_info_l10n.dart';

class IntakeInfoNavBar extends StatelessWidget {
  const IntakeInfoNavBar({super.key});

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
            IntakeInfoL10n.navFamilies,
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textPrimary.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(width: 24),
          const Text(
            IntakeInfoL10n.navRegistration,
            style: TextStyle(
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
