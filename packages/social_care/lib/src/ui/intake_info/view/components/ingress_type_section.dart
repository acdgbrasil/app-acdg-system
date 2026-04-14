import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../constants/intake_info_l10n.dart';

class IngressTypeSection extends StatelessWidget {
  const IngressTypeSection({
    super.key,
    required this.lookups,
    required this.selectedId,
    required this.onSelected,
  });

  final List<LookupItem> lookups;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          IntakeInfoL10n.sectionIngressType,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        if (lookups.isEmpty)
          const Center(child: CircularProgressIndicator())
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: lookups.map((item) {
              final isSelected = selectedId == item.id;
              return ChoiceChip(
                label: Text(item.descricao),
                selected: isSelected,
                onSelected: (_) => onSelected(item.id),
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
