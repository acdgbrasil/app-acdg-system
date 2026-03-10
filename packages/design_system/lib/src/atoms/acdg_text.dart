import 'package:flutter/material.dart';

import '../tokens/acdg_typography.dart';

/// Typographic variant for [AcdgText].
enum AcdgTextVariant {
  displayLarge,
  displayMedium,
  displaySmall,
  headingLarge,
  headingMedium,
  headingSmall,
  bodyLarge,
  bodyMedium,
  bodySmall,
  labelLarge,
  labelMedium,
  labelSmall,
  caption,
}

/// Text atom — wraps [Text] with ACDG typographic variants.
class AcdgText extends StatelessWidget {
  const AcdgText(
    this.data, {
    super.key,
    this.variant = AcdgTextVariant.bodyMedium,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String data;
  final AcdgTextVariant variant;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  TextStyle get _baseStyle => switch (variant) {
    AcdgTextVariant.displayLarge => AcdgTypography.displayLarge,
    AcdgTextVariant.displayMedium => AcdgTypography.displayMedium,
    AcdgTextVariant.displaySmall => AcdgTypography.displaySmall,
    AcdgTextVariant.headingLarge => AcdgTypography.headingLarge,
    AcdgTextVariant.headingMedium => AcdgTypography.headingMedium,
    AcdgTextVariant.headingSmall => AcdgTypography.headingSmall,
    AcdgTextVariant.bodyLarge => AcdgTypography.bodyLarge,
    AcdgTextVariant.bodyMedium => AcdgTypography.bodyMedium,
    AcdgTextVariant.bodySmall => AcdgTypography.bodySmall,
    AcdgTextVariant.labelLarge => AcdgTypography.labelLarge,
    AcdgTextVariant.labelMedium => AcdgTypography.labelMedium,
    AcdgTextVariant.labelSmall => AcdgTypography.labelSmall,
    AcdgTextVariant.caption => AcdgTypography.caption,
  };

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      style: _baseStyle.copyWith(color: color),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
