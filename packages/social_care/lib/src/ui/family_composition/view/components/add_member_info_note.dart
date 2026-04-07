import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../constants/family_composition_ln10.dart';

/// Informational note displayed at the top of the add member modal.
class AddMemberInfoNote extends StatelessWidget {
  const AddMemberInfoNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.07),
        border: Border.all(color: AppColors.background.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Text(
            '\u2139',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.background.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              FamilyCompositionLn10.modalNote,
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 10,
                color: AppColors.background.withValues(alpha: 0.55),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
