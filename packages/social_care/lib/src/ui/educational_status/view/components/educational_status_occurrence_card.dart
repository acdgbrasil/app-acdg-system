import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../../shared/models/member_option.dart';
import '../../constants/educational_status_l10n.dart';
import '../../models/program_occurrence_row.dart';
import 'educational_status_remove_button.dart';
import 'educational_status_toggle_row.dart';

class EducationalStatusOccurrenceCard extends StatelessWidget {
  const EducationalStatusOccurrenceCard({
    super.key,
    required this.occurrence,
    required this.familyMembers,
    required this.effectLookup,
    required this.onMemberChanged,
    required this.onDateChanged,
    required this.onEffectChanged,
    required this.onToggleSuspension,
    required this.onRemove,
  });

  final ProgramOccurrenceRow occurrence;
  final List<MemberOption> familyMembers;
  final List<LookupItem> effectLookup;
  final ValueChanged<String> onMemberChanged;
  final ValueChanged<String> onDateChanged;
  final ValueChanged<String> onEffectChanged;
  final VoidCallback onToggleSuspension;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final unique = familyMembers.where((m) => seen.add(m.id)).toList();
    final validMember =
        occurrence.memberId != null &&
            unique.any((m) => m.id == occurrence.memberId)
        ? occurrence.memberId
        : null;
    final validEffect =
        occurrence.effectId != null &&
            effectLookup.any((e) => e.id == occurrence.effectId)
        ? occurrence.effectId
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
              SizedBox(
                width: 180,
                child: TextField(
                  controller: TextEditingController(text: occurrence.date),
                  decoration: const InputDecoration(
                    labelText: EducationalStatusL10n.occurrenceDateLabel,
                  ),
                  onChanged: onDateChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: validEffect,
            decoration: const InputDecoration(
              labelText: EducationalStatusL10n.effectLabel,
            ),
            items: effectLookup
                .map(
                  (e) =>
                      DropdownMenuItem(value: e.id, child: Text(e.descricao)),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) {
                onEffectChanged(v);
              }
            },
          ),
          const SizedBox(height: 8),
          EducationalStatusToggleRow(
            label: EducationalStatusL10n.suspensionLabel,
            value: occurrence.isSuspensionRequested,
            onToggle: onToggleSuspension,
          ),
          EducationalStatusRemoveButton(onRemove: onRemove),
        ],
      ),
    );
  }
}
