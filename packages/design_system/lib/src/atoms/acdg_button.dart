import 'package:flutter/material.dart';

import '../tokens/acdg_colors.dart';
import '../tokens/acdg_radius.dart';
import '../tokens/acdg_spacing.dart';
import '../tokens/acdg_typography.dart';

/// Visual variant for [AcdgButton].
enum AcdgButtonVariant { primary, secondary, outlined, text }

/// Size preset for [AcdgButton].
enum AcdgButtonSize { small, medium, large }

/// Button atom — primary interaction element.
///
/// Supports 4 variants, 3 sizes, loading state, leading icon,
/// and expanded (full-width) mode. Mapped from Figma button styles.
class AcdgButton extends StatelessWidget {
  const AcdgButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AcdgButtonVariant.primary,
    this.size = AcdgButtonSize.medium,
    this.isLoading = false,
    this.isExpanded = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AcdgButtonVariant variant;
  final AcdgButtonSize size;
  final bool isLoading;
  final bool isExpanded;
  final IconData? icon;

  bool get _isDisabled => onPressed == null || isLoading;

  EdgeInsets get _padding => switch (size) {
    AcdgButtonSize.small =>
      const EdgeInsets.symmetric(horizontal: AcdgSpacing.sm, vertical: AcdgSpacing.xs),
    AcdgButtonSize.medium =>
      const EdgeInsets.symmetric(horizontal: AcdgSpacing.md, vertical: AcdgSpacing.sm),
    AcdgButtonSize.large =>
      const EdgeInsets.symmetric(horizontal: AcdgSpacing.lg, vertical: AcdgSpacing.md),
  };

  double get _fontSize => switch (size) {
    AcdgButtonSize.small => 12,
    AcdgButtonSize.medium => 14,
    AcdgButtonSize.large => 16,
  };

  @override
  Widget build(BuildContext context) {
    final child = _AcdgButtonContent(
      label: label,
      isLoading: isLoading,
      icon: icon,
      variant: variant,
      fontSize: _fontSize,
    );

    final button = switch (variant) {
      AcdgButtonVariant.primary => ElevatedButton(
          onPressed: _isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AcdgColors.primary,
            foregroundColor: AcdgColors.onPrimary,
            disabledBackgroundColor: AcdgColors.disabled,
            disabledForegroundColor: AcdgColors.onDisabled,
            padding: _padding,
            shape: RoundedRectangleBorder(borderRadius: AcdgRadius.borderMd),
            textStyle: AcdgTypography.labelLarge.copyWith(fontSize: _fontSize),
          ),
          child: child,
        ),
      AcdgButtonVariant.secondary => ElevatedButton(
          onPressed: _isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AcdgColors.secondary,
            foregroundColor: AcdgColors.darkBrown,
            disabledBackgroundColor: AcdgColors.disabled,
            disabledForegroundColor: AcdgColors.onDisabled,
            padding: _padding,
            shape: RoundedRectangleBorder(borderRadius: AcdgRadius.borderMd),
            textStyle: AcdgTypography.labelLarge.copyWith(fontSize: _fontSize),
          ),
          child: child,
        ),
      AcdgButtonVariant.outlined => OutlinedButton(
          onPressed: _isDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AcdgColors.primary,
            disabledForegroundColor: AcdgColors.onDisabled,
            side: BorderSide(
              color: _isDisabled ? AcdgColors.disabled : AcdgColors.primary,
            ),
            padding: _padding,
            shape: RoundedRectangleBorder(borderRadius: AcdgRadius.borderMd),
            textStyle: AcdgTypography.labelLarge.copyWith(fontSize: _fontSize),
          ),
          child: child,
        ),
      AcdgButtonVariant.text => TextButton(
          onPressed: _isDisabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AcdgColors.primary,
            disabledForegroundColor: AcdgColors.onDisabled,
            padding: _padding,
            textStyle: AcdgTypography.labelLarge.copyWith(fontSize: _fontSize),
          ),
          child: child,
        ),
    };

    if (isExpanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

class _AcdgButtonContent extends StatelessWidget {
  const _AcdgButtonContent({
    required this.label,
    required this.isLoading,
    required this.icon,
    required this.variant,
    required this.fontSize,
  });

  final String label;
  final bool isLoading;
  final IconData? icon;
  final AcdgButtonVariant variant;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: fontSize,
        height: fontSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == AcdgButtonVariant.primary ||
                    variant == AcdgButtonVariant.secondary
                ? AcdgColors.onPrimary
                : AcdgColors.primary,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 2),
          const SizedBox(width: AcdgSpacing.xs),
          Text(label),
        ],
      );
    }

    return Text(label);
  }
}
