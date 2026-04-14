import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/housing_condition_l10n.dart';

class HousingConditionNavBar extends StatelessWidget {
  const HousingConditionNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/social-care');
              }
            },
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            tooltip: 'Voltar',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          Text(
            HousingConditionL10n.navFamilies,
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textPrimary.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(width: 24),
          const Text(
            HousingConditionL10n.navRegistration,
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
