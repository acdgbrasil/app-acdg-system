import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:social_care/src/ui/home/constants/home_ln10.dart';
import 'package:social_care/src/ui/home/models/patient_summary.dart';

import 'family_item.dart';

class FamilyList extends StatelessWidget {
  final List<PatientSummary> families;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const FamilyList({
    super.key,
    required this.families,
    this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (families.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: AppColors.inputLine),
            SizedBox(height: 12),
            Text(
              HomeLn10.emptyStateTitle,
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontStyle: FontStyle.italic,
                fontSize: 18,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(right: 16),
      itemCount: families.length,
      itemBuilder: (context, index) {
        final family = families[index];
        return FamilyItem(
          family: family,
          isSelected: selectedId == family.patientId,
          isAnySelected: selectedId != null,
          onTap: () => onSelect(family.patientId),
        );
      },
    );
  }
}
