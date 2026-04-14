import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized theme definition for ACDG System.
///
/// Uses Material 3 and custom [ThemeExtension] for ACDG specific tokens.
/// Color palette aligned with the Conecta Raros site: warm beige + coral accent.
abstract final class AcdgTheme {
  /// Light theme definition.
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      surface: AppColors.background,
      primary: AppColors.primary,
      error: AppColors.danger,
    ),
    scaffoldBackgroundColor: AppColors.background,
    extensions: const <ThemeExtension<dynamic>>[
      AcdgDesignTokens(
        backgroundDark: AppColors.backgroundDark,
        cardAlternate: AppColors.cardAlternate,
        textAntiFlash: AppColors.textAntiFlash,
      ),
    ],
  );

  /// Helper to access custom tokens from context.
  static AcdgDesignTokens of(BuildContext context) {
    return Theme.of(context).extension<AcdgDesignTokens>()!;
  }
}

/// Custom design tokens that don't map directly to [ColorScheme].
@immutable
class AcdgDesignTokens extends ThemeExtension<AcdgDesignTokens> {
  final Color backgroundDark;
  final Color cardAlternate;
  final Color textAntiFlash;

  const AcdgDesignTokens({
    required this.backgroundDark,
    required this.cardAlternate,
    required this.textAntiFlash,
  });

  @override
  AcdgDesignTokens copyWith({
    Color? backgroundDark,
    Color? cardAlternate,
    Color? textAntiFlash,
  }) {
    return AcdgDesignTokens(
      backgroundDark: backgroundDark ?? this.backgroundDark,
      cardAlternate: cardAlternate ?? this.cardAlternate,
      textAntiFlash: textAntiFlash ?? this.textAntiFlash,
    );
  }

  @override
  AcdgDesignTokens lerp(ThemeExtension<AcdgDesignTokens>? other, double t) {
    if (other is! AcdgDesignTokens) return this;
    return AcdgDesignTokens(
      backgroundDark: Color.lerp(backgroundDark, other.backgroundDark, t)!,
      cardAlternate: Color.lerp(cardAlternate, other.cardAlternate, t)!,
      textAntiFlash: Color.lerp(textAntiFlash, other.textAntiFlash, t)!,
    );
  }
}
