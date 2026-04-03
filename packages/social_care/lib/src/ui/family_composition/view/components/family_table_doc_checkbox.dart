import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Inline document checkbox used in [FamilyTable] rows.
class FamilyTableDocCheckbox extends StatelessWidget {
  final String label;
  final bool checked;
  final bool enabled;
  final void Function(bool) onChanged;

  const FamilyTableDocCheckbox({
    super.key,
    required this.label,
    required this.checked,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: enabled ? () => onChanged(!checked) : null,
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: Opacity(
            opacity: enabled ? 1.0 : 0.4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: checked
                          ? AppColors.textPrimary
                          : AppColors.inputLine,
                      width: 1.5,
                    ),
                    color: checked ? AppColors.textPrimary : Colors.transparent,
                  ),
                  child: checked
                      ? const Center(
                          child: Text(
                            '\u2713',
                            style: TextStyle(
                              color: AppColors.background,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: checked
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
