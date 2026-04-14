import 'package:flutter/painting.dart';

/// Design tokens for the application's color palette.
///
/// Aligned with the Conecta Raros site design system: warm beige background,
/// coral/terracotta accent, dark charcoal text — organic and welcoming.
/// Derived from site CSS vars: --bg, --accent, --text, --dark, --muted, --border.
abstract final class AppColors {
  // Main Backgrounds
  static const Color background = Color(0xFFF4F2EC); // Warm beige (--bg)
  static const Color backgroundDark = Color(
    0xFF0D0D0B,
  ); // Near-black charcoal (--dark)
  static const Color cardAlternate = Color(
    0xFFEDEAE2,
  ); // Warm beige darker (--bg-warm)

  // Typography & Borders
  static const Color textPrimary = Color(0xFF1C1B18); // Dark charcoal (--text)
  static const Color textOnDark = Color(
    0xFFF4F2EC,
  ); // Warm beige (text on dark backgrounds)
  static const Color textMuted = Color(
    0xFF7A7872,
  ); // Warm gray (--muted)
  static const Color textAntiFlash = Color(
    0xFFEBEBEB,
  ); // Anti Flash (labels inside desktop popup)
  static const Color textBlack = Color(
    0xFF000000,
  ); // Absolute black (documents needed labels)

  // Semantic Colors
  static const Color primary = Color(0xFFC94D2A); // Deep coral (--accent-hover, main action)
  static const Color accent = Color(0xFFE65C3B); // Coral/terracotta (--accent, brand accent)
  static const Color danger = Color(0xFFA6290D); // Red (Cancel/Clear)
  static const Color warning = Color(0xFFC9960A); // Gold/Amber (caregiver star)
  static const Color surface = Color(0xFFFAF8F4); // Lightest warm white (FAB, dialogs)
  static const Color surfaceLight = Color(
    0xFFFCFBF8,
  ); // Almost white with warm tint (icons on dark, toast text)

  // Overlays
  static const Color barrierDark = Color(0x590D0D0B); // Charcoal barrier overlay

  // Interactions & Elements
  static const Color border = Color(0xFFD6D2CA); // Warm gray border (--border)
  static const Color borderOnDark = Color(0xFFF4F2EC); // Warm beige
  static const Color inputLine = Color(
    0x331C1B18,
  ); // Charcoal with ~20% opacity (underlines)
  static const Color shadow = Color(
    0x0D121217,
  ); // rgba(18,18,23,0.05) - used in checkboxes
  static const Color buttonShadow = Color(
    0x1F000000,
  ); // rgba(0,0,0,0.12) - button shadow

  // Elevation & Glow Shadows
  static const Color shadowSubtle = Color(
    0x0F000000,
  ); // rgba(0,0,0,0.06) - secondary button shadow layer
  static const Color popupGlow = Color(
    0x33F4F2EC,
  ); // rgba(244,242,236,0.2) - popup save button glow
  static const Color elevationXs = Color(
    0x0A000000,
  ); // rgba(0,0,0,0.04) - popup shadow layers 1-2
  static const Color elevationSm = Color(
    0x14000000,
  ); // rgba(0,0,0,0.08) - popup shadow layer 3
  static const Color elevationMd = Color(
    0x29000000,
  ); // rgba(0,0,0,0.16) - popup shadow layer 4
  static const Color elevationLg = Color(
    0x3D000000,
  ); // rgba(0,0,0,0.24) - popup shadow layer 5
  static const Color elevationXl = Color(
    0x7A000000,
  ); // rgba(0,0,0,0.48) - popup shadow layer 6
}
