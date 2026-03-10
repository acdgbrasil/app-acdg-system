import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/acdg_colors.dart';
import '../tokens/acdg_spacing.dart';
import '../tokens/acdg_typography.dart';

/// TextField atom — underline-styled input from Figma.
///
/// States: Empty, Filled, Error. Optional label, helper text, icon.
class AcdgTextField extends StatelessWidget {
  const AcdgTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.inputFormatters,
    this.keyboardType,
    this.textInputAction,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
    this.focusNode,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofillHints: autofillHints,
      style: AcdgTypography.bodyLarge.copyWith(
        color: AcdgColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AcdgTypography.bodyLarge.copyWith(
          color: AcdgColors.textPlaceholder,
        ),
        errorText: errorText,
        // Hide error text to avoid duplication with AcdgFormField,
        // but keep the error state for border styling.
        errorStyle: const TextStyle(height: 0, fontSize: 0),
        helperText: helperText,
        helperStyle: const TextStyle(height: 0, fontSize: 0),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AcdgSpacing.sm,
          vertical: AcdgSpacing.lg,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AcdgColors.darkBrown),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AcdgColors.primary, width: 2),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AcdgColors.error),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AcdgColors.error, width: 2),
        ),
        disabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AcdgColors.disabled),
        ),
      ),
    );
  }
}
