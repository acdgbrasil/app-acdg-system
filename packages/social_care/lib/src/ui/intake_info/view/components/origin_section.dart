import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../constants/intake_info_l10n.dart';

class OriginSection extends StatelessWidget {
  const OriginSection({
    super.key,
    required this.isWide,
    required this.originNameController,
    required this.originContactController,
  });

  final bool isWide;
  final TextEditingController originNameController;
  final TextEditingController originContactController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          IntakeInfoL10n.sectionOrigin,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        if (isWide)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: originNameController,
                  decoration: const InputDecoration(
                    labelText: IntakeInfoL10n.originNameLabel,
                    hintText: IntakeInfoL10n.originNameHint,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: TextField(
                  controller: originContactController,
                  decoration: const InputDecoration(
                    labelText: IntakeInfoL10n.originContactLabel,
                    hintText: IntakeInfoL10n.originContactHint,
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: AppMasks.phone,
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              TextField(
                controller: originNameController,
                decoration: const InputDecoration(
                  labelText: IntakeInfoL10n.originNameLabel,
                  hintText: IntakeInfoL10n.originNameHint,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: originContactController,
                decoration: const InputDecoration(
                  labelText: IntakeInfoL10n.originContactLabel,
                  hintText: IntakeInfoL10n.originContactHint,
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: AppMasks.phone,
              ),
            ],
          ),
      ],
    );
  }
}
