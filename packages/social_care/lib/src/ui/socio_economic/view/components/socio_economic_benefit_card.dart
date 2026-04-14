import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../shared/models/benefit_row.dart';
import '../../../shared/models/member_option.dart';
import '../../constants/socio_economic_l10n.dart';

class SocioEconomicBenefitCard extends StatelessWidget {
  const SocioEconomicBenefitCard({
    super.key,
    required this.benefit,
    required this.familyMembers,
    required this.onNameChanged,
    required this.onAmountChanged,
    required this.onBeneficiaryChanged,
    required this.onRemove,
  });

  final BenefitRow benefit;
  final List<MemberOption> familyMembers;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onAmountChanged;
  final ValueChanged<String?> onBeneficiaryChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final unique = familyMembers.where((m) => seen.add(m.id)).toList();
    final validBeneficiary =
        benefit.beneficiaryId != null &&
            unique.any((m) => m.id == benefit.beneficiaryId)
        ? benefit.beneficiaryId
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
                  controller: TextEditingController(text: benefit.benefitName),
                  decoration: const InputDecoration(
                    labelText: SocioEconomicL10n.benefitNameLabel,
                  ),
                  onChanged: onNameChanged,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 140,
                child: TextField(
                  controller: TextEditingController(
                    text: benefit.amount.toStringAsFixed(2),
                  ),
                  decoration: const InputDecoration(
                    labelText: SocioEconomicL10n.benefitAmountLabel,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: onAmountChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: validBeneficiary,
            decoration: const InputDecoration(
              labelText: SocioEconomicL10n.benefitBeneficiaryLabel,
            ),
            items: unique
                .map((m) => DropdownMenuItem(value: m.id, child: Text(m.label)))
                .toList(),
            onChanged: onBeneficiaryChanged,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRemove,
              icon: const Icon(
                Icons.remove_circle_outline,
                size: 16,
                color: AppColors.danger,
              ),
              label: const Text(
                SocioEconomicL10n.removeBenefit,
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
