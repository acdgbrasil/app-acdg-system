import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/housing_condition_l10n.dart';
import '../../view_models/housing_condition_view_model.dart';

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
                _buildTypeSection(),
                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 24),
                _buildStructureSection(isWide),
                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 24),
                _buildInfrastructureSection(),
                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 24),
                _buildAccessibilitySection(),
                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 24),
                _buildRiskFactorsSection(),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Section: Tipo de moradia ────────────────────────────────

  Widget _buildTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(HousingConditionL10n.sectionType),
        const SizedBox(height: 16),
        _chipGroup(
          options: const {
            'owned': HousingConditionL10n.typeOwned,
            'rented': HousingConditionL10n.typeRented,
            'ceded': HousingConditionL10n.typeCeded,
            'squatted': HousingConditionL10n.typeSquatted,
          },
          selected: viewModel.type,
          onSelected: viewModel.updateType,
        ),
        const SizedBox(height: 20),
        _sectionTitle(HousingConditionL10n.wallMaterialLabel),
        const SizedBox(height: 12),
        _chipGroup(
          options: const {
            'masonry': HousingConditionL10n.wallMasonry,
            'finishedWood': HousingConditionL10n.wallFinishedWood,
            'makeshiftMaterials': HousingConditionL10n.wallMakeshift,
          },
          selected: viewModel.wallMaterial,
          onSelected: viewModel.updateWallMaterial,
        ),
      ],
    );
  }

  // ── Section: Estrutura do domicilio ─────────────────────────

  Widget _buildStructureSection(bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(HousingConditionL10n.sectionStructure),
        const SizedBox(height: 16),
        if (isWide)
          Row(
            children: [
              Expanded(
                child: _numberField(
                  label: HousingConditionL10n.numberOfRoomsLabel,
                  value: viewModel.numberOfRooms,
                  onChanged: viewModel.updateNumberOfRooms,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _numberField(
                  label: HousingConditionL10n.numberOfBedroomsLabel,
                  value: viewModel.numberOfBedrooms,
                  onChanged: viewModel.updateNumberOfBedrooms,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _numberField(
                  label: HousingConditionL10n.numberOfBathroomsLabel,
                  value: viewModel.numberOfBathrooms,
                  onChanged: viewModel.updateNumberOfBathrooms,
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              _numberField(
                label: HousingConditionL10n.numberOfRoomsLabel,
                value: viewModel.numberOfRooms,
                onChanged: viewModel.updateNumberOfRooms,
              ),
              const SizedBox(height: 16),
              _numberField(
                label: HousingConditionL10n.numberOfBedroomsLabel,
                value: viewModel.numberOfBedrooms,
                onChanged: viewModel.updateNumberOfBedrooms,
              ),
              const SizedBox(height: 16),
              _numberField(
                label: HousingConditionL10n.numberOfBathroomsLabel,
                value: viewModel.numberOfBathrooms,
                onChanged: viewModel.updateNumberOfBathrooms,
              ),
            ],
          ),
      ],
    );
  }

  // ── Section: Infraestrutura ─────────────────────────────────

  Widget _buildInfrastructureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(HousingConditionL10n.sectionInfrastructure),
        const SizedBox(height: 16),

        // Water supply
        _subsectionTitle(HousingConditionL10n.waterSupplyLabel),
        const SizedBox(height: 10),
        _chipGroup(
          options: const {
            'publicNetwork': HousingConditionL10n.waterPublicNetwork,
            'wellOrSpring': HousingConditionL10n.waterWellOrSpring,
            'rainwaterHarvest': HousingConditionL10n.waterRainwater,
            'waterTruck': HousingConditionL10n.waterTruck,
            'other': HousingConditionL10n.waterOther,
          },
          selected: viewModel.waterSupply,
          onSelected: viewModel.updateWaterSupply,
        ),
        const SizedBox(height: 12),
        _toggleRow(
          label: HousingConditionL10n.hasPipedWaterLabel,
          value: viewModel.hasPipedWater,
          onToggle: viewModel.toggleHasPipedWater,
        ),

        const SizedBox(height: 20),

        // Electricity
        _subsectionTitle(HousingConditionL10n.electricityLabel),
        const SizedBox(height: 10),
        _chipGroup(
          options: const {
            'meteredConnection': HousingConditionL10n.electricityMetered,
            'irregularConnection': HousingConditionL10n.electricityIrregular,
            'noAccess': HousingConditionL10n.electricityNone,
          },
          selected: viewModel.electricityAccess,
          onSelected: viewModel.updateElectricityAccess,
        ),

        const SizedBox(height: 20),

        // Sewage
        _subsectionTitle(HousingConditionL10n.sewageLabel),
        const SizedBox(height: 10),
        _chipGroup(
          options: const {
            'publicSewer': HousingConditionL10n.sewagePublic,
            'septicTank': HousingConditionL10n.sewageSepticTank,
            'rudimentaryPit': HousingConditionL10n.sewageRudimentary,
            'openSewage': HousingConditionL10n.sewageOpen,
            'noBathroom': HousingConditionL10n.sewageNoBathroom,
          },
          selected: viewModel.sewageDisposal,
          onSelected: viewModel.updateSewageDisposal,
        ),

        const SizedBox(height: 20),

        // Waste collection
        _subsectionTitle(HousingConditionL10n.wasteLabel),
        const SizedBox(height: 10),
        _chipGroup(
          options: const {
            'directCollection': HousingConditionL10n.wasteDirectCollection,
            'indirectCollection': HousingConditionL10n.wasteIndirectCollection,
            'noCollection': HousingConditionL10n.wasteNoCollection,
          },
          selected: viewModel.wasteCollection,
          onSelected: viewModel.updateWasteCollection,
        ),
      ],
    );
  }

  // ── Section: Acessibilidade ─────────────────────────────────

  Widget _buildAccessibilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(HousingConditionL10n.sectionAccessibility),
        const SizedBox(height: 16),
        _chipGroup(
          options: const {
            'fullyAccessible': HousingConditionL10n.accessFull,
            'partiallyAccessible': HousingConditionL10n.accessPartial,
            'notAccessible': HousingConditionL10n.accessNone,
          },
          selected: viewModel.accessibilityLevel,
          onSelected: viewModel.updateAccessibilityLevel,
        ),
      ],
    );
  }

  // ── Section: Fatores de risco ───────────────────────────────

  Widget _buildRiskFactorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(HousingConditionL10n.sectionRiskFactors),
        const SizedBox(height: 16),
        _toggleRow(
          label: HousingConditionL10n.geographicRiskLabel,
          value: viewModel.isInGeographicRiskArea,
          onToggle: viewModel.toggleGeographicRisk,
        ),
        const SizedBox(height: 8),
        _toggleRow(
          label: HousingConditionL10n.difficultAccessLabel,
          value: viewModel.hasDifficultAccess,
          onToggle: viewModel.toggleDifficultAccess,
        ),
        const SizedBox(height: 8),
        _toggleRow(
          label: HousingConditionL10n.socialConflictLabel,
          value: viewModel.isInSocialConflictArea,
          onToggle: viewModel.toggleSocialConflict,
        ),
        const SizedBox(height: 8),
        _toggleRow(
          label: HousingConditionL10n.diagnosticObsLabel,
          value: viewModel.hasDiagnosticObservations,
          onToggle: viewModel.toggleDiagnosticObservations,
        ),
      ],
    );
  }

  // ── Shared widgets ─────────────────────────────────────────

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
      fontFamily: 'Satoshi',
      fontWeight: FontWeight.w700,
      fontSize: 16,
      color: AppColors.textPrimary,
    ),
  );

  Widget _subsectionTitle(String text) => Text(
    text,
    style: TextStyle(
      fontFamily: 'Satoshi',
      fontWeight: FontWeight.w600,
      fontSize: 14,
      color: AppColors.textPrimary.withValues(alpha: 0.7),
    ),
  );

  Widget _chipGroup({
    required Map<String, String> options,
    required String? selected,
    required void Function(String) onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((entry) {
        final isSelected = selected == entry.key;
        return ChoiceChip(
          label: Text(entry.value),
          selected: isSelected,
          onSelected: (_) => onSelected(entry.key),
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        );
      }).toList(),
    );
  }

  Widget _numberField({
    required String label,
    required int value,
    required void Function(int) onChanged,
  }) {
    return TextField(
      controller: TextEditingController(text: value.toString()),
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (text) {
        final parsed = int.tryParse(text);
        if (parsed != null) onChanged(parsed);
      },
    );
  }

  Widget _toggleRow({
    required String label,
    required bool value,
    required VoidCallback onToggle,
  }) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: (_) => onToggle(),
                activeColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
