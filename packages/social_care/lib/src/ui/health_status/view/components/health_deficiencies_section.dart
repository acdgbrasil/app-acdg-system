import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../../shared/models/member_option.dart';
import '../../constants/health_status_l10n.dart';
import '../../models/deficiency_row.dart';
import 'health_add_button.dart';
import 'health_deficiency_card.dart';
import 'health_empty_state.dart';
import 'health_section_title.dart';

class HealthDeficienciesSection extends StatelessWidget {
  const HealthDeficienciesSection({
    super.key,
    required this.deficiencies,
    required this.familyMembers,
    required this.deficiencyTypeLookup,
    required this.maxItems,
    required this.onAddDeficiency,
    required this.onUpdateMember,
    required this.onUpdateType,
    required this.onToggleConstantCare,
    required this.onUpdateResponsible,
    required this.onRemoveDeficiency,
  });

  final List<DeficiencyRow> deficiencies;
  final List<MemberOption> familyMembers;
  final List<LookupItem> deficiencyTypeLookup;
  final int maxItems;
  final VoidCallback onAddDeficiency;
  final void Function(int, String) onUpdateMember;
  final void Function(int, String) onUpdateType;
  final void Function(int) onToggleConstantCare;
  final void Function(int, String) onUpdateResponsible;
  final void Function(int) onRemoveDeficiency;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HealthSectionTitle(text: HealthStatusL10n.sectionDeficiencies),
        const SizedBox(height: 16),
        if (deficiencies.isEmpty)
          const HealthEmptyState(text: HealthStatusL10n.noDeficiencies),
        for (int i = 0; i < deficiencies.length; i++) ...[
          HealthDeficiencyCard(
            index: i,
            row: deficiencies[i],
            familyMembers: familyMembers,
            deficiencyTypeLookup: deficiencyTypeLookup,
            onUpdateMember: onUpdateMember,
            onUpdateType: onUpdateType,
            onToggleConstantCare: onToggleConstantCare,
            onUpdateResponsible: onUpdateResponsible,
            onRemove: onRemoveDeficiency,
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        if (deficiencies.length < maxItems)
          HealthAddButton(
            label: HealthStatusL10n.addDeficiency,
            onTap: onAddDeficiency,
          ),
      ],
    );
  }
}
