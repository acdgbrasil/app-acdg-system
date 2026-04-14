import 'package:flutter/material.dart';

import '../../constants/work_and_income_l10n.dart';
import '../../view_models/work_and_income_view_model.dart';
import 'work_and_income_add_button.dart';
import 'work_and_income_benefit_card.dart';
import 'work_and_income_empty_state.dart';
import 'work_and_income_income_card.dart';
import 'work_and_income_section_title.dart';
import 'work_and_income_toggle_row.dart';

class WorkAndIncomeContent extends StatelessWidget {
  const WorkAndIncomeContent({super.key, required this.viewModel});
  final WorkAndIncomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
      child: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          final seen = <String>{};
          final uniqueMembers = viewModel.familyMembers
              .where((m) => seen.add(m.id))
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WorkAndIncomeSectionTitle(
                text: WorkAndIncomeL10n.sectionIncomes,
              ),
              const SizedBox(height: 16),
              if (viewModel.individualIncomes.isEmpty) ...[
                const WorkAndIncomeEmptyState(
                  text: WorkAndIncomeL10n.noIncomes,
                ),
              ],
              for (int i = 0; i < viewModel.individualIncomes.length; i++) ...[
                WorkAndIncomeIncomeCard(
                  income: viewModel.individualIncomes[i],
                  uniqueMembers: uniqueMembers,
                  occupationLookup: viewModel.occupationLookup,
                  onMemberChanged: (v) => viewModel.updateIncomeMember(i, v),
                  onOccupationChanged: (v) =>
                      viewModel.updateIncomeOccupation(i, v),
                  onWorkCardToggled: () => viewModel.toggleIncomeWorkCard(i),
                  onAmountChanged: (v) => viewModel.updateIncomeAmount(i, v),
                  onRemoved: () => viewModel.removeIncome(i),
                ),
                const SizedBox(height: 12),
              ],
              WorkAndIncomeAddButton(
                label: WorkAndIncomeL10n.addIncome,
                onTap: viewModel.addIncome,
              ),
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 24),
              const WorkAndIncomeSectionTitle(
                text: WorkAndIncomeL10n.sectionBenefits,
              ),
              const SizedBox(height: 16),
              if (viewModel.socialBenefits.isEmpty) ...[
                const WorkAndIncomeEmptyState(
                  text: WorkAndIncomeL10n.noBenefits,
                ),
              ],
              for (int i = 0; i < viewModel.socialBenefits.length; i++) ...[
                WorkAndIncomeBenefitCard(
                  benefit: viewModel.socialBenefits[i],
                  uniqueMembers: uniqueMembers,
                  onNameChanged: (v) => viewModel.updateBenefitName(i, v),
                  onAmountChanged: (v) => viewModel.updateBenefitAmount(i, v),
                  onBeneficiaryChanged: (v) =>
                      viewModel.updateBenefitBeneficiary(i, v),
                  onRemoved: () => viewModel.removeBenefit(i),
                ),
                const SizedBox(height: 12),
              ],
              WorkAndIncomeAddButton(
                label: WorkAndIncomeL10n.addBenefit,
                onTap: viewModel.addBenefit,
              ),
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 24),
              const WorkAndIncomeSectionTitle(
                text: WorkAndIncomeL10n.sectionRetirement,
              ),
              const SizedBox(height: 16),
              WorkAndIncomeToggleRow(
                label: WorkAndIncomeL10n.hasRetiredLabel,
                value: viewModel.hasRetiredMembers,
                onToggle: viewModel.toggleRetired,
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}
