import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';

/// Variant types for [AcdgText] mapping to [AppTypography].
enum AcdgTextVariant {
  displayLarge,
  headingLarge,
  headingMedium,
  headingSmall,
  bodyLarge,
  bodyMedium,
  inputPlaceholder,
  selectionLabel,
  buttonText,
  caption,
}

/// A responsive text widget that automatically scales based on screen width.
///
/// Uses the [AppTypography] tokens to ensure consistent hierarchy across 3 breakpoints.
class AcdgText extends StatelessWidget {
  final String data;
  final AcdgTextVariant variant;
  final Color? color;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  const AcdgText(
    this.data, {
    super.key,
    this.variant = AcdgTextVariant.bodyLarge,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final defaultColor = _getDefaultColor();

    final baseStyle = _getStyle(screenWidth);
    final finalStyle = baseStyle.copyWith(color: color ?? defaultColor);

    return Text(
      data,
      style: finalStyle,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }

  TextStyle _getStyle(double width) {
    return switch (variant) {
      AcdgTextVariant.displayLarge => AppTypography.displayLarge(width),
      AcdgTextVariant.headingLarge => AppTypography.headingLarge(width),
      AcdgTextVariant.headingMedium => AppTypography.headingMedium(width),
      AcdgTextVariant.headingSmall => AppTypography.headingSmall(width),
      AcdgTextVariant.bodyLarge => AppTypography.bodyLarge(width),
      AcdgTextVariant.bodyMedium => const TextStyle(
        fontFamily: 'Satoshi',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 24 / 14,
      ),
      AcdgTextVariant.inputPlaceholder => AppTypography.inputPlaceholder(width),
      AcdgTextVariant.selectionLabel => AppTypography.selectionLabel(width),
      AcdgTextVariant.buttonText => AppTypography.buttonText(width),
      AcdgTextVariant.caption => AppTypography.caption(width),
    };
  }

  Color _getDefaultColor() {
    return switch (variant) {
      AcdgTextVariant.inputPlaceholder => AppColors.textMuted,
      _ => AppColors.textPrimary,
    };
  }
}
