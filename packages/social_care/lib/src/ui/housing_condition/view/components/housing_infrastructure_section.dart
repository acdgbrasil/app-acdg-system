import 'package:flutter/material.dart';

import '../../constants/housing_condition_l10n.dart';
import 'housing_chip_group.dart';
import 'housing_section_title.dart';
import 'housing_subsection_title.dart';
import 'housing_toggle_row.dart';

class HousingInfrastructureSection extends StatelessWidget {
  const HousingInfrastructureSection({
    super.key,
    required this.waterSupply,
    required this.hasPipedWater,
    required this.electricityAccess,
    required this.sewageDisposal,
    required this.wasteCollection,
    required this.onWaterSupplySelected,
    required this.onToggleHasPipedWater,
    required this.onElectricitySelected,
    required this.onSewageSelected,
    required this.onWasteSelected,
  });

  final String? waterSupply;
  final bool hasPipedWater;
  final String? electricityAccess;
  final String? sewageDisposal;
  final String? wasteCollection;
  final void Function(String) onWaterSupplySelected;
  final VoidCallback onToggleHasPipedWater;
  final void Function(String) onElectricitySelected;
  final void Function(String) onSewageSelected;
  final void Function(String) onWasteSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HousingSectionTitle(
          text: HousingConditionL10n.sectionInfrastructure,
        ),
        const SizedBox(height: 16),
        const HousingSubsectionTitle(
          text: HousingConditionL10n.waterSupplyLabel,
        ),
        const SizedBox(height: 10),
        HousingChipGroup(
          options: const {
            'publicNetwork': HousingConditionL10n.waterPublicNetwork,
            'wellOrSpring': HousingConditionL10n.waterWellOrSpring,
            'rainwaterHarvest': HousingConditionL10n.waterRainwater,
            'waterTruck': HousingConditionL10n.waterTruck,
            'other': HousingConditionL10n.waterOther,
          },
          selected: waterSupply,
          onSelected: onWaterSupplySelected,
        ),
        const SizedBox(height: 12),
        HousingToggleRow(
          label: HousingConditionL10n.hasPipedWaterLabel,
          value: hasPipedWater,
          onToggle: onToggleHasPipedWater,
        ),
        const SizedBox(height: 20),
        const HousingSubsectionTitle(
          text: HousingConditionL10n.electricityLabel,
        ),
        const SizedBox(height: 10),
        HousingChipGroup(
          options: const {
            'meteredConnection': HousingConditionL10n.electricityMetered,
            'irregularConnection': HousingConditionL10n.electricityIrregular,
            'noAccess': HousingConditionL10n.electricityNone,
          },
          selected: electricityAccess,
          onSelected: onElectricitySelected,
        ),
        const SizedBox(height: 20),
        const HousingSubsectionTitle(text: HousingConditionL10n.sewageLabel),
        const SizedBox(height: 10),
        HousingChipGroup(
          options: const {
            'publicSewer': HousingConditionL10n.sewagePublic,
            'septicTank': HousingConditionL10n.sewageSepticTank,
            'rudimentaryPit': HousingConditionL10n.sewageRudimentary,
            'openSewage': HousingConditionL10n.sewageOpen,
            'noBathroom': HousingConditionL10n.sewageNoBathroom,
          },
          selected: sewageDisposal,
          onSelected: onSewageSelected,
        ),
        const SizedBox(height: 20),
        const HousingSubsectionTitle(text: HousingConditionL10n.wasteLabel),
        const SizedBox(height: 10),
        HousingChipGroup(
          options: const {
            'directCollection': HousingConditionL10n.wasteDirectCollection,
            'indirectCollection': HousingConditionL10n.wasteIndirectCollection,
            'noCollection': HousingConditionL10n.wasteNoCollection,
          },
          selected: wasteCollection,
          onSelected: onWasteSelected,
        ),
      ],
    );
  }
}
