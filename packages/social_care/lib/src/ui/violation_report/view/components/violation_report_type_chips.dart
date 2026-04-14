import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import '../../constants/violation_report_l10n.dart';

class ViolationReportTypeChips extends StatelessWidget {
  const ViolationReportTypeChips({
    super.key,
    required this.selectedType,
    required this.onSelected,
  });

  final String? selectedType;
  final void Function(String) onSelected;

  static const _violationTypes = {
    'neglect': ViolationReportL10n.typeNeglect,
    'psychologicalViolence': ViolationReportL10n.typePsychological,
    'physicalViolence': ViolationReportL10n.typePhysical,
    'sexualAbuse': ViolationReportL10n.typeSexualAbuse,
    'sexualExploitation': ViolationReportL10n.typeSexualExploitation,
    'childLabor': ViolationReportL10n.typeChildLabor,
    'financialExploitation': ViolationReportL10n.typeFinancial,
    'discrimination': ViolationReportL10n.typeDiscrimination,
    'other': ViolationReportL10n.typeOther,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _violationTypes.entries.map((e) {
        final selected = selectedType == e.key;
        return ChoiceChip(
          label: Text(e.value),
          selected: selected,
          onSelected: (_) => onSelected(e.key),
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.primary : AppColors.textPrimary,
          ),
        );
      }).toList(),
    );
  }
}
