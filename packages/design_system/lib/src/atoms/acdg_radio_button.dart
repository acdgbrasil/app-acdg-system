import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';

/// A custom radio button with a rounded square design.
///
/// Unlike standard circular radio buttons, this matches the ACDG
/// checkbox style but with single-selection behavior.
class AcdgRadioButton<T> extends StatelessWidget {
  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final Color? activeColor;

  const AcdgRadioButton({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.activeColor,
  });

  bool get _isSelected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    final themeActiveColor = activeColor ?? AppColors.primary;

    return GestureDetector(
      onTap: () => onChanged?.call(value),
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        selected: _isSelected,
        enabled: onChanged != null,
        onTap: () => onChanged?.call(value),
        child: Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: Colors.transparent),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _isSelected ? themeActiveColor : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _isSelected ? 10 : 0,
                height: _isSelected ? 10 : 0,
                decoration: BoxDecoration(
                  color: themeActiveColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
