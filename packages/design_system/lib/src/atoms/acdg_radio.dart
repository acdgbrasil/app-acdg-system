import 'package:flutter/material.dart';

import '../tokens/acdg_colors.dart';
import '../tokens/acdg_spacing.dart';
import '../tokens/acdg_typography.dart';

/// Radio group atom — from Figma _Base Radio / _Base Radio Group.
///
/// Uses Flutter 3.41+ [RadioGroup] API.
class AcdgRadioGroup<T> extends StatelessWidget {
  const AcdgRadioGroup({
    super.key,
    required this.groupValue,
    required this.onChanged,
    required this.items,
    this.enabled = true,
  });

  final T? groupValue;
  final ValueChanged<T?> onChanged;
  final List<AcdgRadioItem<T>> items;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<T>(
      groupValue: groupValue,
      onChanged: enabled ? onChanged : (_) {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AcdgSpacing.xs),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: enabled ? () => onChanged(item.value) : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IgnorePointer(
                    child: Radio<T>(
                      value: item.value,
                      activeColor: AcdgColors.darkBrown,
                      fillColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.disabled)) {
                          return AcdgColors.disabled;
                        }
                        return AcdgColors.darkBrown;
                      }),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  if (item.label != null) ...[
                    const SizedBox(width: AcdgSpacing.md),
                    Flexible(
                      child: Text(
                        item.label!,
                        style: AcdgTypography.groupLabel.copyWith(
                          color: enabled
                              ? AcdgColors.textPrimary
                              : AcdgColors.onDisabled,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// A single item in an [AcdgRadioGroup].
class AcdgRadioItem<T> {
  const AcdgRadioItem({
    required this.value,
    this.label,
  });

  final T value;
  final String? label;
}
