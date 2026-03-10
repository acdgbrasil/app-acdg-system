import 'package:flutter/material.dart';

import 'acdg_colors.dart';
import 'acdg_radius.dart';
import 'acdg_typography.dart';

/// Builds the Material [ThemeData] from ACDG design tokens.
///
/// Colors, typography, radius — all mapped from Figma.
abstract final class AcdgTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: AcdgTypography.fontInter,
    colorScheme: const ColorScheme.light(
      primary: AcdgColors.primary,
      onPrimary: AcdgColors.onPrimary,
      secondary: AcdgColors.secondary,
      onSecondary: AcdgColors.onSecondary,
      error: AcdgColors.error,
      onError: AcdgColors.onError,
      surface: AcdgColors.surface,
      onSurface: AcdgColors.onSurface,
      surfaceContainerHighest: AcdgColors.surfaceVariant,
      onSurfaceVariant: AcdgColors.onSurfaceVariant,
      outline: AcdgColors.border,
      outlineVariant: AcdgColors.borderDivider,
    ),
    scaffoldBackgroundColor: AcdgColors.background,
    textTheme: const TextTheme(
      displayLarge: AcdgTypography.displayLarge,
      displayMedium: AcdgTypography.displayMedium,
      displaySmall: AcdgTypography.displaySmall,
      headlineLarge: AcdgTypography.headingLarge,
      headlineMedium: AcdgTypography.headingMedium,
      headlineSmall: AcdgTypography.headingSmall,
      bodyLarge: AcdgTypography.bodyLarge,
      bodyMedium: AcdgTypography.bodyMedium,
      bodySmall: AcdgTypography.bodySmall,
      labelLarge: AcdgTypography.labelLarge,
      labelMedium: AcdgTypography.labelMedium,
      labelSmall: AcdgTypography.labelSmall,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: false,
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: AcdgColors.border),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AcdgColors.darkBrown),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AcdgColors.primary, width: 2),
      ),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AcdgColors.error),
      ),
      focusedErrorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AcdgColors.error, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      hintStyle: TextStyle(
        color: AcdgColors.textPlaceholder,
        fontFamily: AcdgTypography.fontInter,
        fontWeight: FontWeight.w500,
      ),
      errorStyle: TextStyle(
        color: AcdgColors.error,
        fontFamily: AcdgTypography.fontInter,
        fontWeight: FontWeight.w500,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AcdgColors.primary,
        foregroundColor: AcdgColors.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: AcdgRadius.borderMd,
        ),
        textStyle: AcdgTypography.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AcdgColors.primary,
        side: const BorderSide(color: AcdgColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: AcdgRadius.borderMd,
        ),
        textStyle: AcdgTypography.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AcdgColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: AcdgTypography.labelLarge,
      ),
    ),
    cardTheme: CardThemeData(
      color: AcdgColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AcdgRadius.borderMd,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AcdgColors.surface,
      foregroundColor: AcdgColors.onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AcdgTypography.headingMedium,
    ),
    dividerTheme: const DividerThemeData(
      color: AcdgColors.borderDivider,
      thickness: 1,
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: AcdgRadius.borderSm,
      ),
      side: const BorderSide(color: AcdgColors.border, width: 1.5),
    ),
    radioTheme: const RadioThemeData(
      fillColor: WidgetStatePropertyAll(AcdgColors.darkBrown),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: AcdgTypography.fontInter,
    colorScheme: const ColorScheme.dark(
      primary: AcdgColors.primary,
      onPrimary: AcdgColors.onPrimary,
      secondary: AcdgColors.secondary,
      onSecondary: AcdgColors.darkBrown,
      error: AcdgColors.error,
      onError: AcdgColors.onError,
      surface: AcdgColors.navy,
      onSurface: AcdgColors.offWhite,
      surfaceContainerHighest: AcdgColors.surfaceOverlay,
      onSurfaceVariant: AcdgColors.antiFlash,
      outline: AcdgColors.offWhite,
      outlineVariant: AcdgColors.borderDivider,
    ),
    scaffoldBackgroundColor: AcdgColors.navy,
    textTheme: TextTheme(
      displayLarge: AcdgTypography.displayLarge.copyWith(color: AcdgColors.offWhite),
      displayMedium: AcdgTypography.displayMedium.copyWith(color: AcdgColors.offWhite),
      displaySmall: AcdgTypography.displaySmall.copyWith(color: AcdgColors.offWhite),
      headlineLarge: AcdgTypography.headingLarge.copyWith(color: AcdgColors.offWhite),
      headlineMedium: AcdgTypography.headingMedium.copyWith(color: AcdgColors.offWhite),
      headlineSmall: AcdgTypography.headingSmall.copyWith(color: AcdgColors.offWhite),
      bodyLarge: AcdgTypography.bodyLarge.copyWith(color: AcdgColors.offWhite),
      bodyMedium: AcdgTypography.bodyMedium.copyWith(color: AcdgColors.offWhite),
      bodySmall: AcdgTypography.bodySmall.copyWith(color: AcdgColors.antiFlash),
      labelLarge: AcdgTypography.labelLarge.copyWith(color: AcdgColors.offWhite),
      labelMedium: AcdgTypography.labelMedium.copyWith(color: AcdgColors.offWhite),
      labelSmall: AcdgTypography.labelSmall.copyWith(color: AcdgColors.antiFlash),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: false,
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: AcdgColors.offWhite),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AcdgColors.offWhite),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AcdgColors.primary, width: 2),
      ),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AcdgColors.error),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      hintStyle: TextStyle(color: AcdgColors.antiFlash),
    ),
    cardTheme: CardThemeData(
      color: AcdgColors.navy,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AcdgRadius.borderMd,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AcdgColors.borderDivider,
      thickness: 1,
    ),
  );
}
