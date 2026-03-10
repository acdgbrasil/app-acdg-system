import 'package:flutter/material.dart';

import '../tokens/acdg_colors.dart';
import '../tokens/acdg_radius.dart';
import '../tokens/acdg_spacing.dart';
import '../tokens/acdg_typography.dart';

/// Dropdown atom — from Figma Dropdown component.
///
/// Outlined button style with chevron, opens a dropdown menu.
class AcdgDropdown<T> extends StatelessWidget {
  const AcdgDropdown({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.hint,
    this.label,
    this.enabled = true,
    this.isExpanded = false,
    this.errorText,
  });

  final List<AcdgDropdownItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final String? label;
  final bool enabled;
  final bool isExpanded;
  final String? errorText;

  Text? _hint({String? hint}) {
    if (hint == null) return null;
    return Text(
      hint,
      style: AcdgTypography.bodyMedium.copyWith(
        color: AcdgColors.textPlaceholder,
      ),
    );
  }

  InputDecoration _inputDecoration({String? errorText}) => InputDecoration(
    contentPadding: EdgeInsets.symmetric(
      horizontal: AcdgSpacing.md,
      vertical: AcdgSpacing.sm,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: AcdgRadius.borderMd,
      borderSide: const BorderSide(color: AcdgColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: AcdgRadius.borderMd,
      borderSide: const BorderSide(color: AcdgColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: AcdgRadius.borderMd,
      borderSide: const BorderSide(color: AcdgColors.error),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: AcdgRadius.borderMd,
      borderSide: const BorderSide(color: AcdgColors.disabled),
    ),
    errorText: errorText,
    errorStyle: const TextStyle(height: 0, fontSize: 0),
  );

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      onChanged: enabled ? onChanged : null,
      isExpanded: isExpanded,
      decoration: _inputDecoration(errorText: errorText).copyWith(
        labelText: label,
        labelStyle: AcdgTypography.bodyMedium.copyWith(
          color: AcdgColors.textPrimary,
        ),
      ),
      hint: _hint(hint: hint),
      style: AcdgTypography.bodyMedium.copyWith(color: AcdgColors.textPrimary),
      icon: const Icon(Icons.keyboard_arrow_down, color: AcdgColors.onSurface),
      items: [
        for (final item in items)
          DropdownMenuItem<T>(value: item.value, child: Text(item.label)),
      ],
    );
  }
}

/// A single item in an [AcdgDropdown].
class AcdgDropdownItem<T> {
  const AcdgDropdownItem({required this.value, required this.label});

  final T value;
  final String label;
}
