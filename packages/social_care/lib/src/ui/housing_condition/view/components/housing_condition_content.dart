import 'package:flutter/material.dart';

import '../../view_models/housing_condition_view_model.dart';
import 'housing_accessibility_section.dart';
import 'housing_infrastructure_section.dart';
import 'housing_risk_factors_section.dart';
import 'housing_structure_section.dart';
import 'housing_type_section.dart';

class HousingConditionContent extends StatelessWidget {
  const HousingConditionContent({super.key, required this.viewModel});

  final HousingConditionViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          return ListenableBuilder(
            listenable: viewModel,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HousingTypeSection(
                  type: viewModel.type,
                  wallMaterial: viewModel.wallMaterial,
                  onTypeSelected: viewModel.updateType,
                  onWallMaterialSelected: viewModel.updateWallMaterial,
                ),
                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 24),
                HousingStructureSection(
                  isWide: isWide,
                  numberOfRooms: viewModel.numberOfRooms,
                  numberOfBedrooms: viewModel.numberOfBedrooms,
                  numberOfBathrooms: viewModel.numberOfBathrooms,
                  onRoomsChanged: viewModel.updateNumberOfRooms,
                  onBedroomsChanged: viewModel.updateNumberOfBedrooms,
                  onBathroomsChanged: viewModel.updateNumberOfBathrooms,
                ),
                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 24),
                HousingInfrastructureSection(
                  waterSupply: viewModel.waterSupply,
                  hasPipedWater: viewModel.hasPipedWater,
                  electricityAccess: viewModel.electricityAccess,
                  sewageDisposal: viewModel.sewageDisposal,
                  wasteCollection: viewModel.wasteCollection,
                  onWaterSupplySelected: viewModel.updateWaterSupply,
                  onToggleHasPipedWater: viewModel.toggleHasPipedWater,
                  onElectricitySelected: viewModel.updateElectricityAccess,
                  onSewageSelected: viewModel.updateSewageDisposal,
                  onWasteSelected: viewModel.updateWasteCollection,
                ),
                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 24),
                HousingAccessibilitySection(
                  accessibilityLevel: viewModel.accessibilityLevel,
                  onSelected: viewModel.updateAccessibilityLevel,
                ),
                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 24),
                HousingRiskFactorsSection(
                  isInGeographicRiskArea: viewModel.isInGeographicRiskArea,
                  hasDifficultAccess: viewModel.hasDifficultAccess,
                  isInSocialConflictArea: viewModel.isInSocialConflictArea,
                  hasDiagnosticObservations:
                      viewModel.hasDiagnosticObservations,
                  onToggleGeographicRisk: viewModel.toggleGeographicRisk,
                  onToggleDifficultAccess: viewModel.toggleDifficultAccess,
                  onToggleSocialConflict: viewModel.toggleSocialConflict,
                  onToggleDiagnosticObservations:
                      viewModel.toggleDiagnosticObservations,
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}
