import 'package:flutter/material.dart';

/// Design tokens for colors — extracted from Figma ACDG Design System.
///
/// Base palette: 5 core colors from Figma color frames.
/// Extended palette: derived from component analysis.
abstract final class AcdgColors {
  // ─── Base Palette (Figma Color Frames) ───

  /// Primary Blue — #0477BF
  static const Color primary = Color(0xFF0477BF);

  /// Secondary Yellow/Gold — #F2B705
  static const Color secondary = Color(0xFFF2B705);

  /// Off White / Cream — #F2E2C4
  static const Color offWhite = Color(0xFFF2E2C4);

  /// Dark Brown — #261D11
  static const Color darkBrown = Color(0xFF261D11);

  /// Dark Red / Error — #A6290D
  static const Color darkRed = Color(0xFFA6290D);

  // ─── Extended Palette (from components) ───

  /// Navy Blue — #172D48 (popup/card backgrounds)
  static const Color navy = Color(0xFF172D48);

  /// Anti Flash — #EBEBEB (light neutral)
  static const Color antiFlash = Color(0xFFEBEBEB);

  /// Void — #0B0C10 (near black, checkbox checked border)
  static const Color void_ = Color(0xFF0B0C10);

  // ─── Semantic Aliases ───

  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // Neutral / Surface
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = offWhite;
  static const Color surfaceOverlay = Color(0xFF292929);
  static const Color onBackground = darkBrown;
  static const Color onSurface = darkBrown;
  static const Color onSurfaceVariant = Color(0xFF6C6C89);

  // Semantic
  static const Color error = darkRed;
  static const Color onError = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF28A745);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color warning = secondary;
  static const Color onWarning = darkBrown;
  static const Color info = primary;
  static const Color onInfo = Color(0xFFFFFFFF);

  // Border
  static const Color border = Color(0xFFD1D1DB);
  static const Color borderHover = Color(0xFFA9A9BC);
  static const Color borderFocused = primary;
  static const Color borderError = darkRed;
  static const Color borderDivider = Color(0xFFEBEBEF);

  // Focus
  static const Color focusRing = Color(0xFF7047EB);

  // Disabled
  static const Color disabled = Color(0xFFD1D1DB);
  static const Color onDisabled = Color(0xFF6C6C89);

  // Text
  static const Color textPrimary = darkBrown;
  static const Color textSecondary = Color(0xFF6C6C89);
  static const Color textPlaceholder = Color(0x80261D11); // darkBrown 50%
  static const Color textOnDark = offWhite;

  // Shadow base
  static const Color shadowBase = Color(0xFF121217);
}
