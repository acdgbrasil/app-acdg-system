import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

class FamilyMemberModalFooter extends StatelessWidget {
  final VoidCallback onSave;

  const FamilyMemberModalFooter({super.key, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: onSave,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textOnDark.withValues(alpha: 0.18),
                  blurRadius: 5,
                  spreadRadius: 4,
                  offset: const Offset(-1, -1),
                ),
                BoxShadow(
                  color: AppColors.textOnDark.withValues(alpha: 0.18),
                  blurRadius: 5,
                  spreadRadius: 4,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
            child: const Text(
              ReferencePersonLn10.memberModalSave,
              style: TextStyle(
                color: AppColors.textOnDark,
                fontSize: 14,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.7,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
