import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared/shared.dart';

import '../../../shared/models/member_option.dart';
import '../../constants/work_and_income_l10n.dart';
import '../../models/income_row.dart';
import 'work_and_income_toggle_row.dart';

class WorkAndIncomeIncomeCard extends StatelessWidget {
  const WorkAndIncomeIncomeCard({
    super.key,
    required this.income,
    required this.uniqueMembers,
    required this.occupationLookup,
    required this.onMemberChanged,
    required this.onOccupationChanged,
    required this.onWorkCardToggled,
    required this.onAmountChanged,
    required this.onRemoved,
  });
  final IncomeRow income;
  final List<MemberOption> uniqueMembers;
  final List<LookupItem> occupationLookup;
  final ValueChanged<String> onMemberChanged;
  final ValueChanged<String> onOccupationChanged;
  final VoidCallback onWorkCardToggled;
  final ValueChanged<double> onAmountChanged;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    final validMember =
        income.memberId != null &&
            uniqueMembers.any((m) => m.id == income.memberId)
        ? income.memberId
        : null;
    final validOcc =
        income.occupationId != null &&
            occupationLookup.any((o) => o.id == income.occupationId)
        ? income.occupationId
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
                    labelText: WorkAndIncomeL10n.memberLabel,
                  ),
                  items: uniqueMembers
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
                  initialValue: validOcc,
                  decoration: const InputDecoration(
                    labelText: WorkAndIncomeL10n.occupationLabel,
                  ),
                  items: occupationLookup
                      .map(
                        (o) => DropdownMenuItem(
                          value: o.id,
                          child: Text(o.descricao),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      onOccupationChanged(v);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: WorkAndIncomeToggleRow(
                  label: WorkAndIncomeL10n.hasWorkCardLabel,
                  value: income.hasWorkCard,
                  onToggle: onWorkCardToggled,
                ),
              ),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: TextEditingController(
                    text: income.monthlyAmount > 0
                        ? income.monthlyAmount.toStringAsFixed(2)
                        : '',
                  ),
                  decoration: const InputDecoration(
                    labelText: WorkAndIncomeL10n.monthlyAmountLabel,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: AppMasks.currency,
                  onChanged: (v) {
                    final cleaned = v
                        .replaceAll('R\$', '')
                        .replaceAll(' ', '')
                        .replaceAll('.', '')
                        .replaceAll(',', '.');
                    final p = double.tryParse(cleaned);
                    if (p != null) {
                      onAmountChanged(p);
                    }
                  },
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRemoved,
              icon: const Icon(
                Icons.remove_circle_outline,
                size: 16,
                color: AppColors.danger,
              ),
              label: const Text(
                WorkAndIncomeL10n.remove,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 13,
                  color: AppColors.danger,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
