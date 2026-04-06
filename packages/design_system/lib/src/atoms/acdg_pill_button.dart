import 'package:flutter/material.dart';

import '../tokens/app_breakpoints.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_shadows.dart';
import '../tokens/app_typography.dart';

/// Variant types for the [AcdgPillButton].
enum AcdgPillButtonVariant {
  /// Green background, used for advancing or success actions.
  primary,

  /// Red background, used for dangerous or clearing actions.
  danger,

  /// Transparent background with border, used for secondary actions.
  outlined,
}

/// A custom pill-shaped button that adapts to 3 breakpoints.
class AcdgPillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AcdgPillButtonVariant variant;
  final IconData? icon;

  const AcdgPillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AcdgPillButtonVariant.primary,
    this.icon,
  });

  const AcdgPillButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  }) : variant = AcdgPillButtonVariant.primary;

  const AcdgPillButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  }) : variant = AcdgPillButtonVariant.danger;

  const AcdgPillButton.outlined({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  }) : variant = AcdgPillButtonVariant.outlined;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = AppBreakpoints.isDesktop(screenWidth);
        final isTablet = AppBreakpoints.isTablet(screenWidth);

        final double height = isDesktop ? 72.0 : (isTablet ? 56.0 : 48.0);
        final textStyle = AppTypography.buttonText(
          screenWidth,
        ).copyWith(color: _getTextColor());

        final decoration = BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(100),
          border: variant == AcdgPillButtonVariant.outlined
              ? Border.all(color: AppColors.border, width: 1.0)
              : null,
          boxShadow: isDesktop ? AppShadows.buttonShadow : null,
        );

        return Semantics(
          button: true,
          enabled: onPressed != null,
          label: label,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(100),
              child: Container(
                height: height,
                constraints: BoxConstraints(
                  minWidth: isDesktop ? 248.0 : (isTablet ? 140.0 : 120.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: decoration,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        color: _getTextColor(),
                        size: isDesktop ? 32 : (isTablet ? 24 : 16),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        style: textStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getBackgroundColor() {
    return switch (variant) {
      AcdgPillButtonVariant.primary => AppColors.primary,
      AcdgPillButtonVariant.danger => AppColors.danger,
      AcdgPillButtonVariant.outlined => Colors.transparent,
    };
  }

  Color _getTextColor() {
    return switch (variant) {
      AcdgPillButtonVariant.primary ||
      AcdgPillButtonVariant.danger => AppColors.textOnDark,
      AcdgPillButtonVariant.outlined => AppColors.textPrimary,
    };
  }
}

/// A circular blue button with a "+" icon, used in the header for adding items.
class AcdgAddCircleButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const AcdgAddCircleButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = AppBreakpoints.isMobile(screenWidth);
    final size = isMobile ? 32.0 : 48.0;

    return Material(
      color: AppColors.backgroundDark,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.add,
            color: AppColors.textOnDark,
            size: isMobile ? 20.0 : 32.0,
          ),
        ),
      ),
    );
  }
}
