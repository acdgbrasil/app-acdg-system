import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../constants/intake_info_l10n.dart';

class ProgramsSection extends StatelessWidget {
  const ProgramsSection({
    super.key,
    required this.lookups,
    required this.selectedProgramIds,
    required this.onToggle,
  });

  final List<LookupItem> lookups;
  final Set<String> selectedProgramIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          IntakeInfoL10n.sectionPrograms,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        if (lookups.isEmpty)
          const SizedBox.shrink()
        else
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: lookups.map((item) {
              final isSelected = selectedProgramIds.contains(item.id);
              return FilterChip(
                label: Text(item.descricao),
                selected: isSelected,
                onSelected: (_) => onToggle(item.id),
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 13,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
