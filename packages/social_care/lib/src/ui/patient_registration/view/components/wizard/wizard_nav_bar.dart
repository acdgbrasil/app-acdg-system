import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';
import 'wizard_nav_link.dart';

class WizardNavBar extends StatelessWidget {
  final double padding;

  const WizardNavBar({super.key, required this.padding});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 24, padding, 8),
      child: Row(
        children: [
          const Icon(Icons.menu, color: AppColors.textPrimary, size: 28),
          const SizedBox(width: 24),
          WizardNavLink(
            label: ReferencePersonLn10.navFamilies,
            isActive: false,
            onTap: () => context.go('/social-care'),
          ),
          const SizedBox(width: 24),
          const WizardNavLink(
            label: ReferencePersonLn10.navRegistration,
            isActive: true,
          ),
        ],
      ),
    );
  }
}
