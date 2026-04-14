import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../../shared/models/member_option.dart';
import '../../constants/health_status_l10n.dart';
import '../../models/deficiency_row.dart';
import 'health_lookup_dropdown.dart';
import 'health_member_dropdown.dart';
import 'health_remove_button.dart';
import 'health_toggle_row.dart';

class HealthDeficiencyCard extends StatefulWidget {
  const HealthDeficiencyCard({
    super.key,
    required this.index,
    required this.row,
    required this.familyMembers,
    required this.deficiencyTypeLookup,
    required this.onUpdateMember,
    required this.onUpdateType,
    required this.onToggleConstantCare,
    required this.onUpdateResponsible,
    required this.onRemove,
  });

  final int index;
  final DeficiencyRow row;
  final List<MemberOption> familyMembers;
  final List<LookupItem> deficiencyTypeLookup;
  final void Function(int, String) onUpdateMember;
  final void Function(int, String) onUpdateType;
  final void Function(int) onToggleConstantCare;
  final void Function(int, String) onUpdateResponsible;
  final void Function(int) onRemove;

  @override
  State<HealthDeficiencyCard> createState() => _HealthDeficiencyCardState();
}

class _HealthDeficiencyCardState extends State<HealthDeficiencyCard> {
  late final TextEditingController _responsibleCtrl;

  @override
  void initState() {
    super.initState();
    _responsibleCtrl = TextEditingController(
      text: widget.row.responsibleCaregiverName,
    );
  }

  @override
  void dispose() {
    _responsibleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                child: HealthMemberDropdown(
                  label: HealthStatusL10n.deficiencyMemberLabel,
                  value: widget.row.memberId,
                  familyMembers: widget.familyMembers,
                  onChanged: (id) => widget.onUpdateMember(widget.index, id),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: HealthLookupDropdown(
                  label: HealthStatusL10n.deficiencyTypeLabel,
                  value: widget.row.deficiencyTypeId,
                  items: widget.deficiencyTypeLookup,
                  onChanged: (id) => widget.onUpdateType(widget.index, id),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          HealthToggleRow(
            label: HealthStatusL10n.deficiencyNeedsConstantCareLabel,
            value: widget.row.needsConstantCare,
            onToggle: () => widget.onToggleConstantCare(widget.index),
          ),
          if (widget.row.needsConstantCare) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _responsibleCtrl,
              decoration: const InputDecoration(
                labelText: HealthStatusL10n.deficiencyResponsibleLabel,
                hintText: HealthStatusL10n.deficiencyResponsibleHint,
              ),
              onChanged: (value) =>
                  widget.onUpdateResponsible(widget.index, value),
            ),
          ],
          const SizedBox(height: 8),
          HealthRemoveButton(
            label: HealthStatusL10n.removeDeficiency,
            onPressed: () => widget.onRemove(widget.index),
          ),
        ],
      ),
    );
  }
}
