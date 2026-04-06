import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class AddMemberModalDocCheckboxes extends StatelessWidget {
  final Set<String> selectedDocs;
  final List<String> options;
  final void Function(String) onToggle;

  const AddMemberModalDocCheckboxes({
    super.key,
    required this.selectedDocs,
    required this.options,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        for (final doc in options)
          GestureDetector(
            onTap: () => onToggle(doc),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.background.withValues(
                          alpha: selectedDocs.contains(doc) ? 1.0 : 0.3,
                        ),
                        width: 1.5,
                      ),
                      color: selectedDocs.contains(doc)
                          ? AppColors.background
                          : Colors.transparent,
                    ),
                    child: selectedDocs.contains(doc)
                        ? const Center(
                            child: Text(
                              '\u2713',
                              style: TextStyle(
                                color: AppColors.backgroundDark,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    doc,
                    style: TextStyle(
                      fontFamily: 'Playfair Display',
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                      color: selectedDocs.contains(doc)
                          ? AppColors.background
                          : AppColors.background.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
