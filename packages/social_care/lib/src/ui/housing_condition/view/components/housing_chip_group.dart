import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class HousingChipGroup extends StatelessWidget {
  const HousingChipGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final Map<String, String> options;
  final String? selected;
  final void Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((entry) {
        final isSelected = selected == entry.key;
        return ChoiceChip(
          label: Text(entry.value),
          selected: isSelected,
          onSelected: (_) => onSelected(entry.key),
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        );
      }).toList(),
    );
  }
}
