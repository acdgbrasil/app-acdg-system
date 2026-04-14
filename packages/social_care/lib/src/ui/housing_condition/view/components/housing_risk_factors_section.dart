import 'package:flutter/material.dart';

import '../../constants/housing_condition_l10n.dart';
import 'housing_section_title.dart';
import 'housing_toggle_row.dart';

class HousingRiskFactorsSection extends StatelessWidget {
  const HousingRiskFactorsSection({
    super.key,
    required this.isInGeographicRiskArea,
    required this.hasDifficultAccess,
    required this.isInSocialConflictArea,
    required this.hasDiagnosticObservations,
    required this.onToggleGeographicRisk,
    required this.onToggleDifficultAccess,
    required this.onToggleSocialConflict,
    required this.onToggleDiagnosticObservations,
  });

  final bool isInGeographicRiskArea;
  final bool hasDifficultAccess;
  final bool isInSocialConflictArea;
  final bool hasDiagnosticObservations;
  final VoidCallback onToggleGeographicRisk;
  final VoidCallback onToggleDifficultAccess;
  final VoidCallback onToggleSocialConflict;
  final VoidCallback onToggleDiagnosticObservations;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HousingSectionTitle(
          text: HousingConditionL10n.sectionRiskFactors,
        ),
        const SizedBox(height: 16),
        HousingToggleRow(
          label: HousingConditionL10n.geographicRiskLabel,
          value: isInGeographicRiskArea,
          onToggle: onToggleGeographicRisk,
        ),
        const SizedBox(height: 8),
        HousingToggleRow(
          label: HousingConditionL10n.difficultAccessLabel,
          value: hasDifficultAccess,
          onToggle: onToggleDifficultAccess,
        ),
        const SizedBox(height: 8),
        HousingToggleRow(
          label: HousingConditionL10n.socialConflictLabel,
          value: isInSocialConflictArea,
          onToggle: onToggleSocialConflict,
        ),
        const SizedBox(height: 8),
        HousingToggleRow(
          label: HousingConditionL10n.diagnosticObsLabel,
          value: hasDiagnosticObservations,
          onToggle: onToggleDiagnosticObservations,
        ),
      ],
    );
  }
}
