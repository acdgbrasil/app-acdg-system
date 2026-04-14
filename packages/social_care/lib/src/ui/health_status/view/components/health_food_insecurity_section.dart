import 'package:flutter/material.dart';

import '../../constants/health_status_l10n.dart';
import 'health_section_title.dart';
import 'health_toggle_row.dart';

class HealthFoodInsecuritySection extends StatelessWidget {
  const HealthFoodInsecuritySection({
    super.key,
    required this.foodInsecurity,
    required this.onToggle,
  });

  final bool foodInsecurity;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HealthSectionTitle(text: HealthStatusL10n.sectionFoodInsecurity),
        const SizedBox(height: 16),
        HealthToggleRow(
          label: HealthStatusL10n.foodInsecurityLabel,
          value: foodInsecurity,
          onToggle: onToggle,
        ),
      ],
    );
  }
}
