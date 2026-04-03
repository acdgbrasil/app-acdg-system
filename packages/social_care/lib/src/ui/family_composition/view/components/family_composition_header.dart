import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../constants/family_composition_ln10.dart';

/// Header row with page title and "add member" FAB.
class FamilyCompositionHeader extends StatelessWidget {
  const FamilyCompositionHeader({super.key, required this.onAddMember});

  /// Called when the user taps the "+" button.
  final VoidCallback onAddMember;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 4, 48, 24),
      child: Row(
        children: [
          const Text(
            FamilyCompositionLn10.pageTitle,
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w700,
              fontSize: 38,
              letterSpacing: -1,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: onAddMember,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.inputLine, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.buttonShadow,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  '+',
                  style: TextStyle(
                    fontSize: 20,
                    color: AppColors.backgroundDark,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            FamilyCompositionLn10.addMemberLabel,
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontStyle: FontStyle.italic,
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
