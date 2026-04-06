import 'package:flutter/painting.dart';
import 'app_colors.dart';

/// Design tokens for shadows and elevation.
abstract final class AppShadows {
  /// Standard button shadow (Desktop) - Multi-layered for depth.
  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      offset: Offset(2.5, 2.5),
      blurRadius: 5,
      spreadRadius: 2,
      color: AppColors.buttonShadow,
    ),
    BoxShadow(
      offset: Offset(-1, -1),
      blurRadius: 4,
      spreadRadius: 0,
      color: AppColors.shadowSubtle,
    ),
  ];

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
      color: AppColors.popupGlow,
    ),
    BoxShadow(
      offset: Offset(1, 1),
      blurRadius: 5,
      spreadRadius: 4,
      color: AppColors.popupGlow,
    ),
  ];

  /// Multi-layered shadow for popups/modals.
  static const List<BoxShadow> popupShadow = [
    BoxShadow(
      offset: Offset(0, 0),
      blurRadius: 0,
      spreadRadius: 1,
      color: AppColors.elevationXs,
    ),
    BoxShadow(
      offset: Offset(-9, 9),
      blurRadius: 9,
      spreadRadius: -0.5,
      color: AppColors.elevationXs,
    ),
    BoxShadow(
      offset: Offset(-18, 18),
      blurRadius: 18,
      spreadRadius: -1.5,
      color: AppColors.elevationSm,
    ),
    BoxShadow(
      offset: Offset(-37, 37),
      blurRadius: 37,
      spreadRadius: -3,
      color: AppColors.elevationMd,
    ),
    BoxShadow(
      offset: Offset(-75, 75),
      blurRadius: 75,
      spreadRadius: -6,
      color: AppColors.elevationLg,
    ),
    BoxShadow(
      offset: Offset(-150, 150),
      blurRadius: 150,
      spreadRadius: -12,
      color: AppColors.elevationXl,
    ),
  ];
}
