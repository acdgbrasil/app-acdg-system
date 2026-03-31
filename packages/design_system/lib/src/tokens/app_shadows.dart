import 'package:flutter/painting.dart';
import 'app_colors.dart';

/// Design tokens for shadows and elevation.
abstract final class AppShadows {
  /// Standard button shadow (Desktop).
  static const BoxShadow buttonShadow = BoxShadow(
    offset: Offset(2.5, 2.5),
    blurRadius: 5,
    spreadRadius: 2,
    color: AppColors.buttonShadow,
  );

  /// Shadow for checkboxes.
  static const BoxShadow xsShadow = BoxShadow(
    offset: Offset(0, 1),
    blurRadius: 2,
    color: AppColors.shadow,
  );

  /// Glow effect for the "Save" button inside popups.
  static const List<BoxShadow> popupButtonGlow = [
    BoxShadow(
      offset: Offset(-1, -1),
      blurRadius: 5,
      spreadRadius: 4,
      color: Color(0x33F2E2C4), // rgba(242,226,196,0.2)
    ),
    BoxShadow(
      offset: Offset(1, 1),
      blurRadius: 5,
      spreadRadius: 4,
      color: Color(0x33F2E2C4),
    ),
  ];

  /// Multi-layered shadow for popups/modals.
  static const List<BoxShadow> popupShadow = [
    BoxShadow(
      offset: Offset(0, 0),
      blurRadius: 0,
      spreadRadius: 1,
      color: Color(0x0A000000),
    ),
    BoxShadow(
      offset: Offset(-9, 9),
      blurRadius: 9,
      spreadRadius: -0.5,
      color: Color(0x0A000000),
    ),
    BoxShadow(
      offset: Offset(-18, 18),
      blurRadius: 18,
      spreadRadius: -1.5,
      color: Color(0x14000000),
    ),
    BoxShadow(
      offset: Offset(-37, 37),
      blurRadius: 37,
      spreadRadius: -3,
      color: Color(0x29000000),
    ),
    BoxShadow(
      offset: Offset(-75, 75),
      blurRadius: 75,
      spreadRadius: -6,
      color: Color(0x3D000000),
    ),
    BoxShadow(
      offset: Offset(-150, 150),
      blurRadius: 150,
      spreadRadius: -12,
      color: Color(0x7A000000),
    ),
  ];
}
