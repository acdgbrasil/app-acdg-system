import 'package:flutter/material.dart';

import '../../constants/housing_condition_l10n.dart';
import 'housing_chip_group.dart';
import 'housing_section_title.dart';

class HousingAccessibilitySection extends StatelessWidget {
  const HousingAccessibilitySection({
    super.key,
    required this.accessibilityLevel,
    required this.onSelected,
  });

  final String? accessibilityLevel;
  final void Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HousingSectionTitle(
          text: HousingConditionL10n.sectionAccessibility,
        ),
        const SizedBox(height: 16),
        HousingChipGroup(
          options: const {
            'fullyAccessible': HousingConditionL10n.accessFull,
            'partiallyAccessible': HousingConditionL10n.accessPartial,
            'notAccessible': HousingConditionL10n.accessNone,
          },
          selected: accessibilityLevel,
          onSelected: onSelected,
        ),
      ],
    );
  }
}
