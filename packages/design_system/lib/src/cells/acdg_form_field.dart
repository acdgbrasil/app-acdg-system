import 'package:flutter/material.dart';

import '../tokens/acdg_colors.dart';
import '../tokens/acdg_spacing.dart';
import '../tokens/acdg_typography.dart';

/// Form field cell — label + child input + error/helper text + required indicator.
///
/// Wraps any input widget (AcdgTextField, AcdgDropdown, etc.) with
/// consistent label and error display.
class AcdgFormField extends StatelessWidget {
  const AcdgFormField({
    super.key,
    required this.label,
    required this.child,
    this.errorText,
    this.helperText,
    this.isRequired = false,
  });

  final String label;
  final Widget child;
  final String? errorText;
  final String? helperText;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _AcdgFormFieldLabel(label: label, isRequired: isRequired),
        const SizedBox(height: AcdgSpacing.xs),
        child,
        if (errorText != null)
          _AcdgFormFieldError(errorText: errorText!)
        else if (helperText != null)
          _AcdgFormFieldHelper(helperText: helperText!),
      ],
    );
  }
}

class _AcdgFormFieldLabel extends StatelessWidget {
  const _AcdgFormFieldLabel({
    required this.label,
    required this.isRequired,
  });

  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: label,
        style: AcdgTypography.labelLarge.copyWith(
          color: AcdgColors.textPrimary,
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AcdgColors.error),
            ),
        ],
      ),
    );
  }
}

class _AcdgFormFieldError extends StatelessWidget {
  const _AcdgFormFieldError({required this.errorText});

  final String errorText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AcdgSpacing.xs),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            size: 16,
            color: AcdgColors.error,
          ),
          const SizedBox(width: AcdgSpacing.xs),
          Flexible(
            child: Text(
              errorText,
              style: AcdgTypography.caption.copyWith(
                color: AcdgColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AcdgFormFieldHelper extends StatelessWidget {
  const _AcdgFormFieldHelper({required this.helperText});

  final String helperText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AcdgSpacing.xs),
      child: Text(
        helperText,
        style: AcdgTypography.caption.copyWith(
          color: AcdgColors.textSecondary,
        ),
      ),
    );
  }
}
