import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/socio_economic_l10n.dart';
import '../../view_models/socio_economic_view_model.dart';

class SocioEconomicContent extends StatefulWidget {
  const SocioEconomicContent({super.key, required this.viewModel});
  final SocioEconomicViewModel viewModel;
  @override
  State<SocioEconomicContent> createState() => _SocioEconomicContentState();
}

class _SocioEconomicContentState extends State<SocioEconomicContent> {
  late final TextEditingController _totalIncomeCtrl;
  late final TextEditingController _perCapitaCtrl;
  late final TextEditingController _mainSourceCtrl;
  SocioEconomicViewModel get vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _totalIncomeCtrl = TextEditingController(text: vm.totalFamilyIncome.toStringAsFixed(2))..addListener(() { final v = double.tryParse(_totalIncomeCtrl.text); if (v != null) vm.updateTotalIncome(v); });
    _perCapitaCtrl = TextEditingController(text: vm.incomePerCapita.toStringAsFixed(2))..addListener(() { final v = double.tryParse(_perCapitaCtrl.text); if (v != null) vm.updatePerCapita(v); });
    _mainSourceCtrl = TextEditingController(text: vm.mainSourceOfIncome)..addListener(() => vm.updateMainSource(_mainSourceCtrl.text));
    vm.addListener(_sync);
  }

  void _sync() {
    if (_mainSourceCtrl.text != vm.mainSourceOfIncome) _mainSourceCtrl.text = vm.mainSourceOfIncome;
  }

  @override
  void dispose() { vm.removeListener(_sync); _totalIncomeCtrl.dispose(); _perCapitaCtrl.dispose(); _mainSourceCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8), child: ListenableBuilder(listenable: vm, builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title(SocioEconomicL10n.sectionIncome), const SizedBox(height: 16),
      Row(children: [
        Expanded(child: TextField(controller: _totalIncomeCtrl, decoration: const InputDecoration(labelText: SocioEconomicL10n.totalIncomeLabel), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))])),
        const SizedBox(width: 24),
        Expanded(child: TextField(controller: _perCapitaCtrl, decoration: const InputDecoration(labelText: SocioEconomicL10n.perCapitaLabel), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))])),
      ]),
      const SizedBox(height: 28), const Divider(), const SizedBox(height: 24),

      _title(SocioEconomicL10n.sectionBenefits), const SizedBox(height: 16),
      _toggle(SocioEconomicL10n.receivesBenefitLabel, vm.receivesSocialBenefit, vm.toggleReceivesBenefit),
      if (vm.receivesSocialBenefit) ...[
        const SizedBox(height: 16),
        if (vm.socialBenefits.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(SocioEconomicL10n.noBenefits, style: TextStyle(fontFamily: 'Satoshi', fontSize: 14, color: AppColors.textPrimary.withValues(alpha: 0.5), fontStyle: FontStyle.italic))),
        for (int i = 0; i < vm.socialBenefits.length; i++) ...[_buildBenefitCard(i), const SizedBox(height: 12)],
        TextButton.icon(onPressed: vm.addBenefit, icon: const Icon(Icons.add, size: 18, color: AppColors.primary), label: const Text(SocioEconomicL10n.addBenefit, style: TextStyle(fontFamily: 'Satoshi', fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600))),
      ],
      const SizedBox(height: 28), const Divider(), const SizedBox(height: 24),

      _title(SocioEconomicL10n.sectionSource), const SizedBox(height: 16),
      TextField(controller: _mainSourceCtrl, decoration: const InputDecoration(labelText: SocioEconomicL10n.mainSourceLabel, hintText: SocioEconomicL10n.mainSourceHint)),
      const SizedBox(height: 28), const Divider(), const SizedBox(height: 24),

      _title(SocioEconomicL10n.sectionEmployment), const SizedBox(height: 16),
      _toggle(SocioEconomicL10n.hasUnemployedLabel, vm.hasUnemployed, vm.toggleHasUnemployed),
      const SizedBox(height: 40),
    ])));
  }

  Widget _buildBenefitCard(int i) {
    final b = vm.socialBenefits[i];
    final seen = <String>{};
    final unique = vm.familyMembers.where((m) => seen.add(m.id)).toList();
    final validBeneficiary = b.beneficiaryId != null && unique.any((m) => m.id == b.beneficiaryId) ? b.beneficiaryId : null;
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: AppColors.inputLine), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: TextField(controller: TextEditingController(text: b.benefitName), decoration: const InputDecoration(labelText: SocioEconomicL10n.benefitNameLabel), onChanged: (v) => vm.updateBenefitName(i, v))),
        const SizedBox(width: 16),
        SizedBox(width: 140, child: TextField(controller: TextEditingController(text: b.amount.toStringAsFixed(2)), decoration: const InputDecoration(labelText: SocioEconomicL10n.benefitAmountLabel), keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (v) { final p = double.tryParse(v); if (p != null) vm.updateBenefitAmount(i, p); })),
      ]),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: validBeneficiary, decoration: const InputDecoration(labelText: SocioEconomicL10n.benefitBeneficiaryLabel), items: unique.map((m) => DropdownMenuItem(value: m.id, child: Text(m.label))).toList(), onChanged: (v) { if (v != null) vm.updateBenefitBeneficiary(i, v); }),
      const SizedBox(height: 8),
      Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => vm.removeBenefit(i), icon: const Icon(Icons.remove_circle_outline, size: 16, color: AppColors.danger), label: const Text(SocioEconomicL10n.removeBenefit, style: TextStyle(fontFamily: 'Satoshi', fontSize: 13, color: AppColors.danger)))),
    ]));
  }

  Widget _title(String t) => Text(t, style: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary));
  Widget _toggle(String label, bool value, VoidCallback onToggle) => InkWell(onTap: onToggle, borderRadius: BorderRadius.circular(8), child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [SizedBox(width: 24, height: 24, child: Checkbox(value: value, onChanged: (_) => onToggle(), activeColor: AppColors.primary)), const SizedBox(width: 12), Expanded(child: Text(label, style: const TextStyle(fontFamily: 'Satoshi', fontSize: 14, color: AppColors.textPrimary)))])));
}
