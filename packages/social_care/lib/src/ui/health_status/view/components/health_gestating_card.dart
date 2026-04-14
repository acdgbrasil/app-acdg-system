import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/models/member_option.dart';
import '../../constants/health_status_l10n.dart';
import '../../models/gestating_row.dart';
import 'health_remove_button.dart';
import 'health_toggle_row.dart';

class HealthGestatingCard extends StatefulWidget {
  const HealthGestatingCard({
    super.key,
    required this.index,
    required this.row,
    required this.femaleFamilyMembers,
    required this.onUpdateMember,
    required this.onUpdateMonths,
    required this.onTogglePrenatal,
    required this.onRemove,
  });

  final int index;
  final GestatingRow row;
  final List<MemberOption> femaleFamilyMembers;
  final void Function(int, String) onUpdateMember;
  final void Function(int, int) onUpdateMonths;
  final void Function(int) onTogglePrenatal;
  final void Function(int) onRemove;

  @override
  State<HealthGestatingCard> createState() => _HealthGestatingCardState();
}

class _HealthGestatingCardState extends State<HealthGestatingCard> {
  late final TextEditingController _monthsCtrl;

  @override
  void initState() {
    super.initState();
    _monthsCtrl = TextEditingController(
      text: widget.row.monthsGestation.toString(),
    );
  }

  @override
  void dispose() {
    _monthsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final validMember =
        widget.row.memberId != null &&
            widget.femaleFamilyMembers.any((m) => m.id == widget.row.memberId)
        ? widget.row.memberId
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
          if (widget.femaleFamilyMembers.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                HealthStatusL10n.gestatingOnlyFemaleError,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 13,
                  color: AppColors.danger,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: validMember,
                  decoration: const InputDecoration(
                    labelText: HealthStatusL10n.gestatingMemberLabel,
                  ),
                  items: widget.femaleFamilyMembers
                      .map(
                        (m) => DropdownMenuItem(
                          value: m.id,
                          child: Text(m.label),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      widget.onUpdateMember(widget.index, v);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 160,
                child: TextField(
                  controller: _monthsCtrl,
                  decoration: const InputDecoration(
                    labelText: HealthStatusL10n.gestatingMonthsLabel,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  onChanged: (text) {
                    final parsed = int.tryParse(text);
                    if (parsed != null) {
                      final clamped = parsed.clamp(1, 11);
                      widget.onUpdateMonths(widget.index, clamped);
                      if (clamped != parsed) {
                        _monthsCtrl.text = clamped.toString();
                        _monthsCtrl.selection = TextSelection.collapsed(
                          offset: _monthsCtrl.text.length,
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          HealthToggleRow(
            label: HealthStatusL10n.gestatingPrenatalLabel,
            value: widget.row.startedPrenatalCare,
            onToggle: () => widget.onTogglePrenatal(widget.index),
          ),
          const SizedBox(height: 8),
          HealthRemoveButton(
            label: HealthStatusL10n.removeGestating,
            onPressed: () => widget.onRemove(widget.index),
          ),
        ],
      ),
    );
  }
}
