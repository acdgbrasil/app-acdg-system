import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';

/// A custom dropdown component for ACDG.
///
/// Adapts its colors for normal (Off White) or inverted (Deep Blue) backgrounds.
class AcdgDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String hint;
  final bool inverted;

  const AcdgDropdown({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.hint = 'Selecione',
    this.inverted = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = inverted ? AppColors.textOnDark : AppColors.textPrimary;
    final borderColor = inverted ? AppColors.borderOnDark : AppColors.border;
    final backgroundColor = inverted
        ? AppColors.backgroundDark
        : AppColors.background;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          icon: Icon(Icons.keyboard_arrow_down, color: textColor, size: 20),
          hint: Text(
            hint,
            style: const TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ).copyWith(color: textColor),
          ),
          dropdownColor: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ).copyWith(color: textColor),
        ),
      ),
    );
  }
}
