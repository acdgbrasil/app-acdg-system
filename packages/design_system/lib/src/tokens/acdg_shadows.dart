import 'package:flutter/material.dart';

/// Design tokens for shadows — extracted from Figma ACDG Design System.
abstract final class AcdgShadows {
  /// Shadows/xs — subtle elevation
  static const List<BoxShadow> xs = [
    BoxShadow(
      color: Color(0x0D121217),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  /// Focus ring — used on checkbox/radio focus state
  /// Inner white ring + outer purple ring
  static const List<BoxShadow> focusRing = [
    BoxShadow(
      color: Color(0xFFFFFFFF),
      spreadRadius: 2,
    ),
    BoxShadow(
      color: Color(0xFF7047EB),
      spreadRadius: 4,
    ),
  ];

  /// Button glow — used on popup save button
  static const List<BoxShadow> buttonGlow = [
    BoxShadow(
      color: Color(0x33F2E2C4),
      offset: Offset(-1, -1),
      blurRadius: 5,
      spreadRadius: 4,
    ),
    BoxShadow(
      color: Color(0x33F2E2C4),
      offset: Offset(1, 1),
      blurRadius: 5,
      spreadRadius: 4,
    ),
  ];

  /// Overlay/Light — dropdown menu shadow (light theme)
  static const List<BoxShadow> overlayLight = [
    BoxShadow(
      color: Color(0x1A121217),
      spreadRadius: 1,
    ),
    BoxShadow(
      color: Color(0x0A121217),
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
    BoxShadow(
      color: Color(0x0A121217),
      offset: Offset(0, 5),
      blurRadius: 8,
    ),
    BoxShadow(
      color: Color(0x08121217),
      offset: Offset(0, 10),
      blurRadius: 18,
    ),
    BoxShadow(
      color: Color(0x08121217),
      offset: Offset(0, 24),
      blurRadius: 48,
    ),
  ];

  /// Overlay/Dark — dropdown menu shadow (dark theme)
  static const List<BoxShadow> overlayDark = [
    BoxShadow(
      color: Color(0x3DFFFFFF),
      spreadRadius: 1,
    ),
    BoxShadow(
      color: Color(0x0A121217),
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
    BoxShadow(
      color: Color(0x0A121217),
      offset: Offset(0, 5),
      blurRadius: 8,
    ),
    BoxShadow(
      color: Color(0x08121217),
      offset: Offset(0, 10),
      blurRadius: 18,
    ),
    BoxShadow(
      color: Color(0x08121217),
      offset: Offset(0, 24),
      blurRadius: 48,
    ),
  ];

  /// Popup/card — heavy elevation shadow
  static const List<BoxShadow> popup = [
    BoxShadow(
      color: Color(0x0AA5A5A5),
      spreadRadius: 1,
    ),
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(-9, 9),
      blurRadius: 9,
      spreadRadius: -0.5,
    ),
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(-18, 18),
      blurRadius: 18,
      spreadRadius: -1.5,
    ),
    BoxShadow(
      color: Color(0x29000000),
      offset: Offset(-37, 37),
      blurRadius: 37,
      spreadRadius: -3,
    ),
    BoxShadow(
      color: Color(0x3D000000),
      offset: Offset(-75, 75),
      blurRadius: 75,
      spreadRadius: -6,
    ),
    BoxShadow(
      color: Color(0x7A000000),
      offset: Offset(-150, 150),
      blurRadius: 150,
      spreadRadius: -12,
    ),
  ];
}
