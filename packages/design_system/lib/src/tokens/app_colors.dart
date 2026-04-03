import 'package:flutter/painting.dart';

/// Design tokens for the application's color palette.
abstract final class AppColors {
  // Main Backgrounds
  static const Color background = Color(0xFFF2E2C4); // Off White
  static const Color backgroundDark = Color(
    0xFF172D48,
  ); // Deep Blue (popup/modal)
  static const Color cardAlternate = Color(
    0xFFC8BBA4,
  ); // Card background (alternated on mobile)

  // Typography & Borders
  static const Color textPrimary = Color(0xFF261D11); // Dark Brown
  static const Color textOnDark = Color(
    0xFFF2E2C4,
  ); // Off White (text on dark backgrounds)
  static const Color textMuted = Color(
    0x80261D11,
  ); // Dark Brown with 50% opacity
  static const Color textAntiFlash = Color(
    0xFFEBEBEB,
  ); // Anti Flash (labels inside desktop popup)
  static const Color textBlack = Color(
    0xFF000000,
  ); // Absolute black (documents needed labels)

  // Semantic Colors
  static const Color primary = Color(0xFF4F8448); // Green (Success/Next)
  static const Color danger = Color(0xFFA6290D); // Red (Cancel/Clear)
  static const Color warning = Color(0xFFC9960A); // Gold/Amber (caregiver star)
  static const Color surface = Color(0xFFFAF0E0); // Light cream (FAB, dialogs)
  static const Color surfaceLight = Color(0xFFFFFBF4); // Lightest cream (icons on dark, toast text)

  // Overlays
  static const Color barrierDark = Color(
    0x59261D11,
  ); // Dialog barrier overlay

  // Interactions & Elements
  static const Color border = Color(0xFF261D11); // Dark Brown
  static const Color borderOnDark = Color(0xFFF2E2C4); // Off White
  static const Color inputLine = Color(
    0x33261D11,
  ); // Dark Brown with ~20% opacity (underlines)
  static const Color shadow = Color(
    0x0D121217,
  ); // rgba(18,18,23,0.05) - used in checkboxes
  static const Color buttonShadow = Color(
    0x1F000000,
  ); // rgba(0,0,0,0.12) - button shadow
}
