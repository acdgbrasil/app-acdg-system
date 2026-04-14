import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../constants/educational_status_l10n.dart';

class EducationalStatusRemoveButton extends StatelessWidget {
  const EducationalStatusRemoveButton({super.key, required this.onRemove});

  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: onRemove,
        icon: const Icon(
          Icons.remove_circle_outline,
          size: 16,
          color: AppColors.danger,
        ),
        label: const Text(
          EducationalStatusL10n.remove,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 13,
            color: AppColors.danger,
          ),
        ),
      ),
    );
  }
}
