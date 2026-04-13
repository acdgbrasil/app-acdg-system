import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../constants/intake_info_l10n.dart';

class IntakeInfoActionBar extends StatelessWidget {
  const IntakeInfoActionBar({
    super.key,
    required this.onCancel,
    required this.onSave,
    this.canSave = true,
  });

  final VoidCallback onCancel;
  final VoidCallback onSave;
  final bool canSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.inputLine)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.close, size: 16),
                SizedBox(width: 7),
                Text(
                  IntakeInfoL10n.btnCancel,
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: canSave ? onSave : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  IntakeInfoL10n.btnSave,
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                    color: AppColors.background,
                  ),
                ),
                SizedBox(width: 7),
                Icon(Icons.check, size: 16, color: AppColors.background),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
