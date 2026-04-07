import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../constants/family_composition_ln10.dart';

/// Save button footer for the add member modal.
class AddMemberFooter extends StatelessWidget {
  final VoidCallback onSave;

  const AddMemberFooter({super.key, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: onSave,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: AppColors.background.withValues(alpha: 0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.background.withValues(alpha: 0.12),
                  blurRadius: 6,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Text(
              FamilyCompositionLn10.modalSave,
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontStyle: FontStyle.italic,
                fontSize: 13,
                color: AppColors.background,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
