import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import '../../constants/family_composition_ln10.dart';
import '../../models/family_member_model.dart';

/// Confirmation dialog for changing the primary caregiver.
/// Shows the current caregiver and the new candidate.
class ConfirmCaregiverDialog extends StatelessWidget {
  final FamilyMemberModel currentCaregiver;
  final FamilyMemberModel newCandidate;
  final VoidCallback onConfirm;

  const ConfirmCaregiverDialog({
    super.key,
    required this.currentCaregiver,
    required this.newCandidate,
    required this.onConfirm,
  });

  static Future<bool?> show(
    BuildContext context, {
    required FamilyMemberModel currentCaregiver,
    required FamilyMemberModel newCandidate,
    required VoidCallback onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: AppColors.barrierDark,
      builder: (_) => ConfirmCaregiverDialog(
        currentCaregiver: currentCaregiver,
        newCandidate: newCandidate,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: AppColors.inputLine,
                blurRadius: 80,
                offset: Offset(0, 24),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 28)),
              const SizedBox(height: 10),
              const Text(
                FamilyCompositionLn10.caregiverTitle,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontFamily: 'Playfair Display',
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(
                      text: currentCaregiver.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const TextSpan(
                      text: ' ${FamilyCompositionLn10.caregiverCurrentIs}\n',
                    ),
                    const TextSpan(text: 'Ao confirmar, '),
                    TextSpan(
                      text: newCandidate.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const TextSpan(
                      text:
                          ' ${FamilyCompositionLn10.caregiverWillBecome} ${FamilyCompositionLn10.caregiverLoseStatus}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ℹ', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        FamilyCompositionLn10.caregiverApiNote,
                        style: TextStyle(fontSize: 12, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      side: const BorderSide(color: AppColors.inputLine),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 10,
                      ),
                    ),
                    child: const Text(
                      FamilyCompositionLn10.btnCancel,
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontStyle: FontStyle.italic,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                      onConfirm();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 10,
                      ),
                    ),
                    child: const Text(
                      FamilyCompositionLn10.btnCaregiverConfirm,
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontStyle: FontStyle.italic,
                        color: AppColors.background,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
