import 'package:flutter/material.dart';

/// Design tokens for typography — extracted from Figma ACDG Design System.
///
/// Font families: Inter (primary UI), Space Grotesk (labels), Erode (accent).
/// Sizes from Figma: 12, 14, 16, 20, 24, 32.
abstract final class AcdgTypography {
  // ─── Font Families ───

  static const String fontInter = 'Inter';
  static const String fontSpaceGrotesk = 'Space Grotesk';
  static const String fontErode = 'Erode';

  // ─── Display (Inter Bold) ───

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontInter,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontInter,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.33,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontInter,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  // ─── Heading (Inter Bold) ───

  static const TextStyle headingLarge = TextStyle(
    fontFamily: fontInter,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: fontInter,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.5,
  );

  static const TextStyle headingSmall = TextStyle(
    fontFamily: fontInter,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.71,
  );

  // ─── Body (Inter Regular / Medium) ───

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontInter,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontInter,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.71,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontInter,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 2.0,
  );

  // ─── Label (Inter Medium) ───

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontInter,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.71,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontInter,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 2.0,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontInter,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 2.0,
  );

  // ─── Caption ───

  static const TextStyle caption = TextStyle(
    fontFamily: fontInter,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 2.0,
  );

  // ─── Input (Inter Medium — from TextField component) ───

  static const TextStyle inputLabel = TextStyle(
    fontFamily: fontInter,
    fontSize: 32,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle inputValue = TextStyle(
    fontFamily: fontInter,
    fontSize: 32,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle inputHelper = TextStyle(
    fontFamily: fontInter,
    fontSize: 24,
    fontWeight: FontWeight.w500,
  );

  // ─── Space Grotesk (label in checkbox/radio groups) ───

  static const TextStyle groupLabel = TextStyle(
    fontFamily: fontSpaceGrotesk,
    fontSize: 20,
    fontWeight: FontWeight.w400,
  );

  // ─── Erode (accent / italic — popup fields) ───

  static const TextStyle accentBody = TextStyle(
    fontFamily: fontErode,
    fontSize: 16,
    fontWeight: FontWeight.w300,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle accentButton = TextStyle(
    fontFamily: fontErode,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontStyle: FontStyle.italic,
    letterSpacing: 0.7,
  );
}
