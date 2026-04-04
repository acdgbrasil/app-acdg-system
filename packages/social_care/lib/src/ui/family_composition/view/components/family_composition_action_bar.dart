import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../constants/family_composition_ln10.dart';

/// Bottom action bar with Cancel, Observations, and Save buttons.
class FamilyCompositionActionBar extends StatelessWidget {
  const FamilyCompositionActionBar({
    super.key,
    required this.onCancel,
    required this.onSave,
    this.canSave = true,
  });

  /// Called when the user taps "Cancelar".
  final VoidCallback onCancel;

  /// Called when the user taps "Salvar Cadastro".
  final VoidCallback onSave;

  /// Whether the save button should be enabled.
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.close, size: 16),
                SizedBox(width: 7),
                Text(
                  FamilyCompositionLn10.btnCancel,
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                  side: const BorderSide(color: AppColors.inputLine),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  FamilyCompositionLn10.btnObservations,
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
                      FamilyCompositionLn10.btnSave,
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
        ],
      ),
    );
  }
}
