import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../constants/family_composition_ln10.dart';

/// Read-only "Especificidades" checklist derived from the patient's
/// social identity (cigana, quilombola, ribeirinha, homeless).
class FamilyCompositionSpecificities extends StatelessWidget {
  const FamilyCompositionSpecificities({super.key});

  static const _labels = [
    FamilyCompositionLn10.specCigana,
    FamilyCompositionLn10.specQuilombola,
    FamilyCompositionLn10.specRibeirinha,
    FamilyCompositionLn10.specHomeless,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          FamilyCompositionLn10.specificitiesTitle,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 1.5,
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 7),
        const Divider(height: 1, color: AppColors.inputLine),
        const SizedBox(height: 14),
        for (final label in _labels)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.inputLine, width: 1.5),
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
