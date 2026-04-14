import 'package:flutter/material.dart';

import '../../view_models/health_status_view_model.dart';
import 'health_care_needs_section.dart';
import 'health_deficiencies_section.dart';
import 'health_food_insecurity_section.dart';
import 'health_gestating_section.dart';

class HealthStatusContent extends StatelessWidget {
  const HealthStatusContent({super.key, required this.viewModel});

  final HealthStatusViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
      child: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HealthDeficienciesSection(
              deficiencies: viewModel.deficiencies,
              familyMembers: viewModel.familyMembers,
              deficiencyTypeLookup: viewModel.deficiencyTypeLookup,
              maxItems: viewModel.familyMembers.length,
              onAddDeficiency: viewModel.addDeficiency,
              onUpdateMember: viewModel.updateDeficiencyMember,
              onUpdateType: viewModel.updateDeficiencyType,
              onToggleConstantCare: viewModel.toggleDeficiencyConstantCare,
              onUpdateResponsible: viewModel.updateDeficiencyResponsible,
              onRemoveDeficiency: viewModel.removeDeficiency,
            ),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 24),
            HealthGestatingSection(
              gestatingMembers: viewModel.gestatingMembers,
              familyMembers: viewModel.femaleFamilyMembers,
              maxItems: viewModel.femaleFamilyMembers.length,
              onAddGestating: viewModel.addGestating,
              onUpdateMember: viewModel.updateGestatingMember,
              onUpdateMonths: viewModel.updateGestatingMonths,
              onTogglePrenatal: viewModel.toggleGestatingPrenatal,
              onRemoveGestating: viewModel.removeGestating,
            ),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 24),
            HealthCareNeedsSection(
              constantCareNeeds: viewModel.constantCareNeeds,
              familyMembers: viewModel.familyMembers,
              maxItems: viewModel.familyMembers.length,
              onAddCareNeed: viewModel.addCareNeed,
              onUpdateCareNeedMember: viewModel.updateCareNeedMember,
              onRemoveCareNeed: viewModel.removeCareNeed,
            ),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 24),
            HealthFoodInsecuritySection(
              foodInsecurity: viewModel.foodInsecurity,
              onToggle: viewModel.toggleFoodInsecurity,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
