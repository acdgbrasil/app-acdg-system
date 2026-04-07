import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import '../../constants/family_composition_ln10.dart';

/// Empty state shown when only the reference person exists (no additional members).
class FamilyEmptyState extends StatelessWidget {
  const FamilyEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.inputLine, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: <Widget>[
          Text(
            FamilyCompositionLn10.emptyTitle,
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontStyle: FontStyle.italic,
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: 4),
          Text(
            FamilyCompositionLn10.emptySubtitle,
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
