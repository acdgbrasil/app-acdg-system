import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../shared/models/benefit_row.dart';
import '../../../shared/models/member_option.dart';
import '../../constants/work_and_income_l10n.dart';

class WorkAndIncomeBenefitCard extends StatefulWidget {
  const WorkAndIncomeBenefitCard({
    super.key,
    required this.benefit,
    required this.uniqueMembers,
    required this.onNameChanged,
    required this.onAmountChanged,
    required this.onBeneficiaryChanged,
    required this.onRemoved,
  });
  final BenefitRow benefit;
  final List<MemberOption> uniqueMembers;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<double> onAmountChanged;
  final ValueChanged<String> onBeneficiaryChanged;
  final VoidCallback onRemoved;

  @override
  State<WorkAndIncomeBenefitCard> createState() =>
      _WorkAndIncomeBenefitCardState();
}

class _WorkAndIncomeBenefitCardState extends State<WorkAndIncomeBenefitCard> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.benefit.benefitName);
    _amountCtrl = TextEditingController(
      text: widget.benefit.amount > 0
          ? widget.benefit.amount.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final validBen =
        widget.benefit.beneficiaryId != null &&
            widget.uniqueMembers.any((m) => m.id == widget.benefit.beneficiaryId)
        ? widget.benefit.beneficiaryId
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
                child: TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: WorkAndIncomeL10n.benefitNameLabel,
                  ),
                  onChanged: widget.onNameChanged,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 140,
                child: TextField(
                  controller: _amountCtrl,
                  decoration: const InputDecoration(
                    labelText: WorkAndIncomeL10n.benefitAmountLabel,
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
                      widget.onAmountChanged(p);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: validBen,
            decoration: const InputDecoration(
              labelText: WorkAndIncomeL10n.beneficiaryLabel,
            ),
            items: widget.uniqueMembers
                .map((m) => DropdownMenuItem(value: m.id, child: Text(m.label)))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                widget.onBeneficiaryChanged(v);
              }
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: widget.onRemoved,
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
