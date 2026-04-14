import 'package:flutter/material.dart';

import '../../constants/housing_condition_l10n.dart';
import 'housing_chip_group.dart';
import 'housing_section_title.dart';

class HousingTypeSection extends StatelessWidget {
  const HousingTypeSection({
    super.key,
    required this.type,
    required this.wallMaterial,
    required this.onTypeSelected,
    required this.onWallMaterialSelected,
  });

  final String? type;
  final String? wallMaterial;
  final void Function(String) onTypeSelected;
  final void Function(String) onWallMaterialSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HousingSectionTitle(text: HousingConditionL10n.sectionType),
        const SizedBox(height: 16),
        HousingChipGroup(
          options: const {
            'owned': HousingConditionL10n.typeOwned,
            'rented': HousingConditionL10n.typeRented,
            'ceded': HousingConditionL10n.typeCeded,
            'squatted': HousingConditionL10n.typeSquatted,
          },
          selected: type,
          onSelected: onTypeSelected,
        ),
        const SizedBox(height: 20),
        const HousingSectionTitle(text: HousingConditionL10n.wallMaterialLabel),
        const SizedBox(height: 12),
        HousingChipGroup(
          options: const {
            'masonry': HousingConditionL10n.wallMasonry,
            'finishedWood': HousingConditionL10n.wallFinishedWood,
            'makeshiftMaterials': HousingConditionL10n.wallMakeshift,
          },
          selected: wallMaterial,
          onSelected: onWallMaterialSelected,
        ),
      ],
    );
  }
}
