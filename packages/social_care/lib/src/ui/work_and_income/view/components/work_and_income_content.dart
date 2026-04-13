import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/work_and_income_l10n.dart';
import '../../view_models/work_and_income_view_model.dart';

class WorkAndIncomeContent extends StatelessWidget {
  const WorkAndIncomeContent({super.key, required this.viewModel});
  final WorkAndIncomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8), child: ListenableBuilder(listenable: viewModel, builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title(WorkAndIncomeL10n.sectionIncomes), const SizedBox(height: 16),
      if (viewModel.individualIncomes.isEmpty) _empty(WorkAndIncomeL10n.noIncomes),
      for (int i = 0; i < viewModel.individualIncomes.length; i++) ...[_buildIncomeCard(i), const SizedBox(height: 12)],
      _addBtn(WorkAndIncomeL10n.addIncome, viewModel.addIncome),
      const SizedBox(height: 28), const Divider(), const SizedBox(height: 24),
      _title(WorkAndIncomeL10n.sectionBenefits), const SizedBox(height: 16),
      if (viewModel.socialBenefits.isEmpty) _empty(WorkAndIncomeL10n.noBenefits),
      for (int i = 0; i < viewModel.socialBenefits.length; i++) ...[_buildBenefitCard(i), const SizedBox(height: 12)],
      _addBtn(WorkAndIncomeL10n.addBenefit, viewModel.addBenefit),
      const SizedBox(height: 28), const Divider(), const SizedBox(height: 24),
      _title(WorkAndIncomeL10n.sectionRetirement), const SizedBox(height: 16),
      _toggle(WorkAndIncomeL10n.hasRetiredLabel, viewModel.hasRetiredMembers, viewModel.toggleRetired),
      const SizedBox(height: 40),
    ])));
  }

  Widget _buildIncomeCard(int i) {
    final inc = viewModel.individualIncomes[i];
    final seen = <String>{}; final unique = viewModel.familyMembers.where((m) => seen.add(m.id)).toList();
    final validMember = inc.memberId != null && unique.any((m) => m.id == inc.memberId) ? inc.memberId : null;
    final validOcc = inc.occupationId != null && viewModel.occupationLookup.any((o) => o.id == inc.occupationId) ? inc.occupationId : null;
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: AppColors.inputLine), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: DropdownButtonFormField<String>(value: validMember, decoration: const InputDecoration(labelText: WorkAndIncomeL10n.memberLabel), items: unique.map((m) => DropdownMenuItem(value: m.id, child: Text(m.label))).toList(), onChanged: (v) { if (v != null) viewModel.updateIncomeMember(i, v); })),
        const SizedBox(width: 16),
        Expanded(child: DropdownButtonFormField<String>(value: validOcc, decoration: const InputDecoration(labelText: WorkAndIncomeL10n.occupationLabel), items: viewModel.occupationLookup.map((o) => DropdownMenuItem(value: o.id, child: Text(o.descricao))).toList(), onChanged: (v) { if (v != null) viewModel.updateIncomeOccupation(i, v); })),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _toggle(WorkAndIncomeL10n.hasWorkCardLabel, inc.hasWorkCard, () => viewModel.toggleIncomeWorkCard(i))),
        SizedBox(width: 200, child: TextField(controller: TextEditingController(text: inc.monthlyAmount.toStringAsFixed(2)), decoration: const InputDecoration(labelText: WorkAndIncomeL10n.monthlyAmountLabel), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))], onChanged: (v) { final p = double.tryParse(v); if (p != null) viewModel.updateIncomeAmount(i, p); })),
      ]),
      Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => viewModel.removeIncome(i), icon: const Icon(Icons.remove_circle_outline, size: 16, color: AppColors.danger), label: const Text(WorkAndIncomeL10n.remove, style: TextStyle(fontFamily: 'Satoshi', fontSize: 13, color: AppColors.danger)))),
    ]));
  }

  Widget _buildBenefitCard(int i) {
    final b = viewModel.socialBenefits[i];
    final seen = <String>{}; final unique = viewModel.familyMembers.where((m) => seen.add(m.id)).toList();
    final validBen = b.beneficiaryId != null && unique.any((m) => m.id == b.beneficiaryId) ? b.beneficiaryId : null;
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: AppColors.inputLine), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: TextField(controller: TextEditingController(text: b.benefitName), decoration: const InputDecoration(labelText: WorkAndIncomeL10n.benefitNameLabel), onChanged: (v) => viewModel.updateBenefitName(i, v))),
        const SizedBox(width: 16),
        SizedBox(width: 140, child: TextField(controller: TextEditingController(text: b.amount.toStringAsFixed(2)), decoration: const InputDecoration(labelText: WorkAndIncomeL10n.benefitAmountLabel), keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (v) { final p = double.tryParse(v); if (p != null) viewModel.updateBenefitAmount(i, p); })),
      ]),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: validBen, decoration: const InputDecoration(labelText: WorkAndIncomeL10n.beneficiaryLabel), items: unique.map((m) => DropdownMenuItem(value: m.id, child: Text(m.label))).toList(), onChanged: (v) { if (v != null) viewModel.updateBenefitBeneficiary(i, v); }),
      Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => viewModel.removeBenefit(i), icon: const Icon(Icons.remove_circle_outline, size: 16, color: AppColors.danger), label: const Text(WorkAndIncomeL10n.remove, style: TextStyle(fontFamily: 'Satoshi', fontSize: 13, color: AppColors.danger)))),
    ]));
  }

  Widget _title(String t) => Text(t, style: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary));
  Widget _empty(String t) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(t, style: TextStyle(fontFamily: 'Satoshi', fontSize: 14, color: AppColors.textPrimary.withValues(alpha: 0.5), fontStyle: FontStyle.italic)));
  Widget _addBtn(String label, VoidCallback onTap) => TextButton.icon(onPressed: onTap, icon: const Icon(Icons.add, size: 18, color: AppColors.primary), label: Text(label, style: const TextStyle(fontFamily: 'Satoshi', fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600)));
  Widget _toggle(String label, bool value, VoidCallback onToggle) => InkWell(onTap: onToggle, borderRadius: BorderRadius.circular(8), child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [SizedBox(width: 24, height: 24, child: Checkbox(value: value, onChanged: (_) => onToggle(), activeColor: AppColors.primary)), const SizedBox(width: 12), Expanded(child: Text(label, style: const TextStyle(fontFamily: 'Satoshi', fontSize: 14, color: AppColors.textPrimary)))])));
}
