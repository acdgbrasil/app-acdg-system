import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_shadows.dart';

/// A custom checkbox with ACDG design specifications.
///
/// Dimensions: 24x24px outer, 14.5x14.5px inner.
class AcdgCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final Color? activeColor;
  final Color? checkColor;

  const AcdgCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.checkColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged?.call(!value),
      child: Semantics(
        checked: value,
        enabled: onChanged != null,
        onTap: () => onChanged?.call(!value),
        child: Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: Colors.transparent),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 14.5,
            height: 14.5,
            decoration: BoxDecoration(
              color: value
                  ? (activeColor ?? AppColors.primary)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border, width: 1.5),
              boxShadow: const [AppShadows.xsShadow],
            ),
            child: value
                ? Icon(
                    Icons.check,
                    size: 14,
                    color: checkColor ?? AppColors.textOnDark,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
