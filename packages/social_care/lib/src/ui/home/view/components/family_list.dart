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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48, color: Color(0x33261D11)),
            const SizedBox(height: 12),
            Text(
              HomeLn10.emptyStateTitle,
              style: const TextStyle(
                fontFamily: 'Playfair Display',
                fontStyle: FontStyle.italic,
                fontSize: 18,
                color: Color(0x80261D11),
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
