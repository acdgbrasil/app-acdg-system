import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';

/// A minimalist input field with only a bottom border.
class AcdgUnderlineInput extends StatelessWidget {
  final String? hintText;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final String? initialValue;
  final bool enabled;
  final String? errorText;
  final List<TextInputFormatter>? inputFormatters;

  const AcdgUnderlineInput({
    super.key,
    this.hintText,
    this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.initialValue,
    this.enabled = true,
    this.errorText,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: hasError ? AppColors.danger : AppColors.inputLine,
                width: hasError ? 2.0 : 1.0,
              ),
            ),
          ),
          child: TextFormField(
            controller: controller,
            initialValue: initialValue,
            obscureText: isPassword,
            keyboardType: keyboardType,
            onChanged: onChanged,
            enabled: enabled,
            inputFormatters: inputFormatters,
            style: AppTypography.bodyLarge(
              screenWidth,
            ).copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTypography.inputPlaceholder(
                screenWidth,
              ).copyWith(color: AppColors.textMuted),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              isDense: true,
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: AppTypography.caption(
              screenWidth,
            ).copyWith(color: AppColors.danger, fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );
  }
}
