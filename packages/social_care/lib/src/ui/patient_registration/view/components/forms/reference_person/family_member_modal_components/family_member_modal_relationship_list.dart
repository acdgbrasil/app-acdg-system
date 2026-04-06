import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

class FamilyMemberModalRelationshipList extends StatelessWidget {
  final List<(String, String)> options;
  final ValueNotifier<String?> relationshipNotifier;
  final String? errorText;

  const FamilyMemberModalRelationshipList({
    super.key,
    required this.options,
    required this.relationshipNotifier,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        alignment: Alignment.center,
        child: Text(
          ReferencePersonLn10.loadingRelationship,
          style: TextStyle(
            color: AppColors.textOnDark.withValues(alpha: 0.6),
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return ValueListenableBuilder<String?>(
      valueListenable: relationshipNotifier,
      builder: (context, selected, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.textOnDark),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (code, label) in options)
                    InkWell(
                      onTap: () => relationshipNotifier.value = code,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        color: selected == code
                            ? AppColors.textOnDark.withValues(alpha: 0.1)
                            : Colors.transparent,
                        child: Text(
                          label,
                          style: TextStyle(
                            color: AppColors.textOnDark,
                            fontSize: 14,
                            fontWeight: selected == code
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (errorText != null) ...[
              const SizedBox(height: 4),
              Text(
                errorText!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ],
          ],
        );
      },
    );
  }
}
