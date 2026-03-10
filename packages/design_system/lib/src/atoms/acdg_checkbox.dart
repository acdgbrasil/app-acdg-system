import 'package:flutter/material.dart';

import '../tokens/acdg_colors.dart';
import '../tokens/acdg_spacing.dart';
import '../tokens/acdg_typography.dart';

/// Checkbox atom — from Figma _Base Checkbox / _Base Checkbox Group.
///
/// Supports checked, unchecked, indeterminate states.
/// Optional label (when [label] is provided, renders as a row).
class AcdgCheckbox extends StatelessWidget {
  const AcdgCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.tristate = false,
    this.enabled = true,
  });

  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final String? label;
  final bool tristate;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final checkbox = IgnorePointer(
      ignoring: label != null,
      child: Checkbox(
        value: value,
        onChanged: enabled ? onChanged : null,
        tristate: tristate,
        activeColor: AcdgColors.darkBrown,
        checkColor: AcdgColors.offWhite,
        side: BorderSide(
          color: enabled ? AcdgColors.darkBrown : AcdgColors.disabled,
          width: 1.5,
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );

    if (label == null) return checkbox;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? () => onChanged?.call(!(value ?? false)) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          checkbox,
          const SizedBox(width: AcdgSpacing.md),
          Flexible(
            child: Text(
              label!,
              style: AcdgTypography.groupLabel.copyWith(
                color: enabled
                    ? AcdgColors.textPrimary
                    : AcdgColors.onDisabled,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
