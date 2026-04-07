import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import '../../constants/family_composition_ln10.dart';

/// Displays the age profile table with 8 ranges.
/// Rows with count > 0 are highlighted with green background.
class AgeProfilePanel extends StatelessWidget {
  final Map<String, int> ageProfile;

  const AgeProfilePanel({super.key, required this.ageProfile});

  static const _ranges = [
    ('0-6', FamilyCompositionLn10.age0to6),
    ('7-14', FamilyCompositionLn10.age7to14),
    ('15-17', FamilyCompositionLn10.age15to17),
    ('18-29', FamilyCompositionLn10.age18to29),
    ('30-59', FamilyCompositionLn10.age30to59),
    ('60-64', FamilyCompositionLn10.age60to64),
    ('65-69', FamilyCompositionLn10.age65to69),
    ('70+', FamilyCompositionLn10.age70plus),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          FamilyCompositionLn10.ageProfileTitle,
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
        const SizedBox(height: 12),
        Table(
          columnWidths: const {0: FlexColumnWidth(), 1: IntrinsicColumnWidth()},
          children: [
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 7,
                    horizontal: 14,
                  ),
                  child: Text(
                    FamilyCompositionLn10.ageColRange,
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 7,
                    horizontal: 14,
                  ),
                  child: Text(
                    FamilyCompositionLn10.ageColCount,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
            for (final (key, label) in _ranges) _buildRow(key, label),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          FamilyCompositionLn10.ageProfileAuto,
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontStyle: FontStyle.italic,
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  TableRow _buildRow(String key, String label) {
    final count = ageProfile[key] ?? 0;
    final isHighlighted = count > 0;
    final bgColor = isHighlighted
        ? AppColors.primary.withValues(alpha: 0.07)
        : Colors.transparent;

    return TableRow(
      decoration: BoxDecoration(color: bgColor),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 13,
              fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w400,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isHighlighted
                  ? AppColors.textPrimary
                  : AppColors.inputLine,
            ),
          ),
        ),
      ],
    );
  }
}
