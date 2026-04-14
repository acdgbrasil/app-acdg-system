import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../constants/socio_economic_l10n.dart';
import '../../view_models/socio_economic_view_model.dart';
import 'socio_economic_benefit_card.dart';
import 'socio_economic_section_title.dart';
import 'socio_economic_toggle_row.dart';

String _formatBRL(double value) {
  final cents = (value * 100).round();
  final intPart = cents ~/ 100;
  final decPart = (cents % 100).toString().padLeft(2, '0');
  final intStr = intPart.toString();
  final buf = StringBuffer();
  for (var i = 0; i < intStr.length; i++) {
    if (i > 0 && (intStr.length - i) % 3 == 0) {
      buf.write('.');
    }
    buf.write(intStr[i]);
  }
  return 'R\$ $buf,$decPart';
}

double _parseBRL(String text) {
  final cleaned = text
      .replaceAll('R\$', '')
      .replaceAll(' ', '')
      .replaceAll('.', '')
      .replaceAll(',', '.');
  return double.tryParse(cleaned) ?? 0;
}

class SocioEconomicContent extends StatefulWidget {
  const SocioEconomicContent({super.key, required this.viewModel});
  final SocioEconomicViewModel viewModel;

  @override
  State<SocioEconomicContent> createState() => _SocioEconomicContentState();
}

class _SocioEconomicContentState extends State<SocioEconomicContent> {
  late final TextEditingController _totalIncomeCtrl;
  late final TextEditingController _mainSourceCtrl;
  SocioEconomicViewModel get vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    final fs = vm.formState;
    _totalIncomeCtrl = TextEditingController(
      text: _formatBRL(fs.totalFamilyIncome),
    )..addListener(() {
        fs.totalFamilyIncome = _parseBRL(_totalIncomeCtrl.text);
        vm.notifyListeners();
      });
    _mainSourceCtrl = TextEditingController(text: fs.mainSourceOfIncome)
      ..addListener(() {
        fs.mainSourceOfIncome = _mainSourceCtrl.text;
        vm.notifyListeners();
      });
  }

  @override
  void dispose() {
    _totalIncomeCtrl.dispose();
    _mainSourceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fs = vm.formState;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
      child: ListenableBuilder(
        listenable: vm,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SocioEconomicSectionTitle(
              title: SocioEconomicL10n.sectionIncome,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _totalIncomeCtrl,
                    decoration: const InputDecoration(
                      labelText: SocioEconomicL10n.totalIncomeLabel,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: AppMasks.currency,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(
                      text: _formatBRL(fs.incomePerCapita),
                    ),
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: SocioEconomicL10n.perCapitaLabel,
                      helperText: 'Calculado automaticamente',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 24),
            const SocioEconomicSectionTitle(
              title: SocioEconomicL10n.sectionBenefits,
            ),
            const SizedBox(height: 16),
            SocioEconomicToggleRow(
              label: SocioEconomicL10n.receivesBenefitLabel,
              value: fs.receivesSocialBenefit,
              onToggle: () {
                fs.receivesSocialBenefit = !fs.receivesSocialBenefit;
                vm.notifyListeners();
              },
            ),
            if (fs.receivesSocialBenefit) ...[
              const SizedBox(height: 16),
              if (fs.socialBenefits.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    SocioEconomicL10n.noBenefits,
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 14,
                      color: AppColors.textPrimary.withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              for (int i = 0; i < fs.socialBenefits.length; i++) ...[
                SocioEconomicBenefitCard(
                  benefit: fs.socialBenefits[i],
                  familyMembers: fs.familyMembers,
                  onNameChanged: (v) {
                    fs.updateBenefitName(i, v);
                    vm.notifyListeners();
                  },
                  onAmountChanged: (v) {
                    final p = double.tryParse(v);
                    if (p != null) {
                      fs.updateBenefitAmount(i, p);
                      vm.notifyListeners();
                    }
                  },
                  onBeneficiaryChanged: (v) {
                    if (v != null) {
                      fs.updateBenefitBeneficiary(i, v);
                      vm.notifyListeners();
                    }
                  },
                  onRemove: () {
                    fs.removeBenefit(i);
                    vm.notifyListeners();
                  },
                ),
                const SizedBox(height: 12),
              ],
              TextButton.icon(
                onPressed: () {
                  fs.addBenefit();
                  vm.notifyListeners();
                },
                icon: const Icon(
                  Icons.add,
                  size: 18,
                  color: AppColors.primary,
                ),
                label: const Text(
                  SocioEconomicL10n.addBenefit,
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 24),
            const SocioEconomicSectionTitle(
              title: SocioEconomicL10n.sectionSource,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _mainSourceCtrl,
              decoration: const InputDecoration(
                labelText: SocioEconomicL10n.mainSourceLabel,
                hintText: SocioEconomicL10n.mainSourceHint,
              ),
            ),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 24),
            const SocioEconomicSectionTitle(
              title: SocioEconomicL10n.sectionEmployment,
            ),
            const SizedBox(height: 16),
            SocioEconomicToggleRow(
              label: SocioEconomicL10n.hasUnemployedLabel,
              value: fs.hasUnemployed,
              onToggle: () {
                fs.hasUnemployed = !fs.hasUnemployed;
                vm.notifyListeners();
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
