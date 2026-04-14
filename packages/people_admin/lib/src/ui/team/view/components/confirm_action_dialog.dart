import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../constants/team_l10n.dart';

class ConfirmActionDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;

  const ConfirmActionDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.backgroundDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      title: AcdgText(
        title,
        variant: AcdgTextVariant.headingSmall,
        color: AppColors.textOnDark,
      ),
      content: AcdgText(
        message,
        variant: AcdgTextVariant.bodyMedium,
        color: AppColors.textOnDark,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const AcdgText(
            TeamL10n.buttonCancel,
            variant: AcdgTextVariant.caption,
            color: AppColors.textMuted,
          ),
        ),
        AcdgPillButton.danger(
          label: TeamL10n.buttonConfirm,
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
        ),
      ],
    );
  }
}
