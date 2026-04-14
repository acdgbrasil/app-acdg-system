import 'package:flutter/material.dart';

import '../../constants/housing_condition_l10n.dart';
import 'housing_number_field.dart';
import 'housing_section_title.dart';

class HousingStructureSection extends StatelessWidget {
  const HousingStructureSection({
    super.key,
    required this.isWide,
    required this.numberOfRooms,
    required this.numberOfBedrooms,
    required this.numberOfBathrooms,
    required this.onRoomsChanged,
    required this.onBedroomsChanged,
    required this.onBathroomsChanged,
  });

  final bool isWide;
  final int numberOfRooms;
  final int numberOfBedrooms;
  final int numberOfBathrooms;
  final void Function(int) onRoomsChanged;
  final void Function(int) onBedroomsChanged;
  final void Function(int) onBathroomsChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HousingSectionTitle(text: HousingConditionL10n.sectionStructure),
        const SizedBox(height: 16),
        if (isWide)
          Row(
            children: [
              Expanded(
                child: HousingNumberField(
                  label: HousingConditionL10n.numberOfRoomsLabel,
                  value: numberOfRooms,
                  onChanged: onRoomsChanged,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: HousingNumberField(
                  label: HousingConditionL10n.numberOfBedroomsLabel,
                  value: numberOfBedrooms,
                  onChanged: onBedroomsChanged,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: HousingNumberField(
                  label: HousingConditionL10n.numberOfBathroomsLabel,
                  value: numberOfBathrooms,
                  onChanged: onBathroomsChanged,
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              HousingNumberField(
                label: HousingConditionL10n.numberOfRoomsLabel,
                value: numberOfRooms,
                onChanged: onRoomsChanged,
              ),
              const SizedBox(height: 16),
              HousingNumberField(
                label: HousingConditionL10n.numberOfBedroomsLabel,
                value: numberOfBedrooms,
                onChanged: onBedroomsChanged,
              ),
              const SizedBox(height: 16),
              HousingNumberField(
                label: HousingConditionL10n.numberOfBathroomsLabel,
                value: numberOfBathrooms,
                onChanged: onBathroomsChanged,
              ),
            ],
          ),
      ],
    );
  }
}
