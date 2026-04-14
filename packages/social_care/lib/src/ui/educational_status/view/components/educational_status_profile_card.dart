import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../../shared/models/member_option.dart';
import '../../constants/educational_status_l10n.dart';
import '../../models/member_profile_row.dart';
import 'educational_status_remove_button.dart';
import 'educational_status_toggle_row.dart';

class EducationalStatusProfileCard extends StatelessWidget {
  const EducationalStatusProfileCard({
    super.key,
    required this.profile,
    required this.familyMembers,
    required this.educationLevelLookup,
    required this.onMemberChanged,
    required this.onEducationLevelChanged,
    required this.onToggleCanReadWrite,
    required this.onToggleAttendsSchool,
    required this.onRemove,
  });

  final MemberProfileRow profile;
  final List<MemberOption> familyMembers;
  final List<LookupItem> educationLevelLookup;
  final ValueChanged<String> onMemberChanged;
  final ValueChanged<String> onEducationLevelChanged;
  final VoidCallback onToggleCanReadWrite;
  final VoidCallback onToggleAttendsSchool;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final unique = familyMembers.where((m) => seen.add(m.id)).toList();
    final validMember =
        profile.memberId != null && unique.any((m) => m.id == profile.memberId)
        ? profile.memberId
        : null;
    final validLevel =
        profile.educationLevelId != null &&
            educationLevelLookup.any((l) => l.id == profile.educationLevelId)
        ? profile.educationLevelId
        : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.inputLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: validMember,
                  decoration: const InputDecoration(
                    labelText: EducationalStatusL10n.memberLabel,
                  ),
                  items: unique
                      .map(
                        (m) =>
                            DropdownMenuItem(value: m.id, child: Text(m.label)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      onMemberChanged(v);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: validLevel,
                  decoration: const InputDecoration(
                    labelText: EducationalStatusL10n.educationLevelLabel,
                  ),
                  items: educationLevelLookup
                      .map(
                        (l) => DropdownMenuItem(
                          value: l.id,
                          child: Text(l.descricao),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      onEducationLevelChanged(v);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          EducationalStatusToggleRow(
            label: EducationalStatusL10n.canReadWriteLabel,
            value: profile.canReadWrite,
            onToggle: onToggleCanReadWrite,
          ),
          EducationalStatusToggleRow(
            label: EducationalStatusL10n.attendsSchoolLabel,
            value: profile.attendsSchool,
            onToggle: onToggleAttendsSchool,
          ),
          EducationalStatusRemoveButton(onRemove: onRemove),
        ],
      ),
    );
  }
}
