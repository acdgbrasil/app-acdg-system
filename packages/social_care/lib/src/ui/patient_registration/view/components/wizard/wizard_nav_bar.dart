import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

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
          _navLink(
            ReferencePersonLn10.navFamilies,
            active: false,
            onTap: () => context.go('/social-care'),
          ),
          const SizedBox(width: 24),
          _navLink(
            ReferencePersonLn10.navRegistration,
            active: true,
          ),
        ],
      ),
    );
  }

  Widget _navLink(String label, {required bool active, VoidCallback? onTap}) {
    final widget = Text(
      label,
      style: const TextStyle(
        fontFamily: 'Satoshi',
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ).copyWith(
        color: AppColors.textPrimary,
        decoration: active ? TextDecoration.underline : null,
      ),
    );

    if (onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: onTap, child: widget),
      );
    }
    return widget;
  }
}
