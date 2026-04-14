import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../constants/intake_info_l10n.dart';

class ServiceReasonSection extends StatelessWidget {
  const ServiceReasonSection({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          IntakeInfoL10n.sectionReason,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: IntakeInfoL10n.serviceReasonLabel,
            hintText: IntakeInfoL10n.serviceReasonHint,
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}
