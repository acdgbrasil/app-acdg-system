import 'package:flutter/material.dart';

import '../../../shared/models/member_option.dart';
import '../../constants/health_status_l10n.dart';
import '../../models/gestating_row.dart';
import 'health_add_button.dart';
import 'health_empty_state.dart';
import 'health_gestating_card.dart';
import 'health_section_title.dart';

class HealthGestatingSection extends StatelessWidget {
  const HealthGestatingSection({
    super.key,
    required this.gestatingMembers,
    required this.familyMembers,
    required this.maxItems,
    required this.onAddGestating,
    required this.onUpdateMember,
    required this.onUpdateMonths,
    required this.onTogglePrenatal,
    required this.onRemoveGestating,
  });

  final List<GestatingRow> gestatingMembers;
  final List<MemberOption> familyMembers;
  final int maxItems;
  final VoidCallback onAddGestating;
  final void Function(int, String) onUpdateMember;
  final void Function(int, int) onUpdateMonths;
  final void Function(int) onTogglePrenatal;
  final void Function(int) onRemoveGestating;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HealthSectionTitle(text: HealthStatusL10n.sectionGestating),
        const SizedBox(height: 16),
        if (gestatingMembers.isEmpty)
          const HealthEmptyState(text: HealthStatusL10n.noGestating),
        for (int i = 0; i < gestatingMembers.length; i++) ...[
          HealthGestatingCard(
            index: i,
            row: gestatingMembers[i],
            femaleFamilyMembers: familyMembers,
            onUpdateMember: onUpdateMember,
            onUpdateMonths: onUpdateMonths,
            onTogglePrenatal: onTogglePrenatal,
            onRemove: onRemoveGestating,
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        if (gestatingMembers.length < maxItems)
          HealthAddButton(
            label: HealthStatusL10n.addGestating,
            onTap: onAddGestating,
          ),
      ],
    );
  }
}
