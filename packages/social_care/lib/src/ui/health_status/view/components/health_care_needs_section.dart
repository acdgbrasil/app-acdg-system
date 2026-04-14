import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../shared/models/member_option.dart';
import '../../constants/health_status_l10n.dart';
import 'health_add_button.dart';
import 'health_empty_state.dart';
import 'health_member_dropdown.dart';
import 'health_section_title.dart';

class HealthCareNeedsSection extends StatelessWidget {
  const HealthCareNeedsSection({
    super.key,
    required this.constantCareNeeds,
    required this.familyMembers,
    required this.maxItems,
    required this.onAddCareNeed,
    required this.onUpdateCareNeedMember,
    required this.onRemoveCareNeed,
  });

  final List<String> constantCareNeeds;
  final List<MemberOption> familyMembers;
  final int maxItems;
  final VoidCallback onAddCareNeed;
  final void Function(int, String) onUpdateCareNeedMember;
  final void Function(int) onRemoveCareNeed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HealthSectionTitle(text: HealthStatusL10n.sectionCareNeeds),
        const SizedBox(height: 16),
        if (constantCareNeeds.isEmpty)
          const HealthEmptyState(text: HealthStatusL10n.noCareNeeds),
        for (int i = 0; i < constantCareNeeds.length; i++) ...[
          Row(
            children: [
              Expanded(
                child: HealthMemberDropdown(
                  label: HealthStatusL10n.careNeedsMemberLabel,
                  value: constantCareNeeds[i].isEmpty
                      ? null
                      : constantCareNeeds[i],
                  familyMembers: familyMembers,
                  onChanged: (id) => onUpdateCareNeedMember(i, id),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => onRemoveCareNeed(i),
                icon: const Icon(
                  Icons.remove_circle_outline,
                  size: 20,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        if (constantCareNeeds.length < maxItems)
          HealthAddButton(
            label: HealthStatusL10n.addCareNeed,
            onTap: onAddCareNeed,
          ),
      ],
    );
  }
}
