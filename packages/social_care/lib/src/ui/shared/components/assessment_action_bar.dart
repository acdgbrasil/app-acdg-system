import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared action bar (Cancel + Save) for all assessment pages.
///
/// Pure Connector widget — receives only callbacks and state flags.
class AssessmentActionBar extends StatelessWidget {
  const AssessmentActionBar({
    super.key,
    required this.cancelLabel,
    required this.saveLabel,
    required this.canSave,
    required this.onSave,
  });

  final String cancelLabel;
  final String saveLabel;
  final bool canSave;
  final VoidCallback onSave;

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
          if (canSave)
            TextButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/social-care');
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.danger,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.close, size: 16),
                  const SizedBox(width: 7),
                  Text(
                    cancelLabel,
                    style: const TextStyle(
                      fontFamily: 'Playfair Display',
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox.shrink(),
          FilledButton(
            onPressed: canSave ? onSave : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor:
                  AppColors.primary.withValues(alpha: 0.4),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  saveLabel,
                  style: const TextStyle(
                    fontFamily: 'Playfair Display',
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                    color: AppColors.background,
                  ),
                ),
                const SizedBox(width: 7),
                const Icon(Icons.check, size: 16, color: AppColors.background),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
