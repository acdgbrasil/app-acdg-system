import 'package:flutter/material.dart';

/// Design tokens for border radius — extracted from Figma ACDG Design System.
///
/// Figma vars: --radius/sm = 4, --radius/md = 8, pill = 100.
abstract final class AcdgRadius {
  static const double none = 0;
  static const double sm = 4;    // --radius/sm (checkbox)
  static const double md = 8;    // --radius/md (dropdown, buttons)
  static const double lg = 12;
  static const double xl = 16;
  static const double pill = 100; // pill / full round (save button)
  static const double full = 999;

  static const BorderRadius borderNone = BorderRadius.zero;
  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderPill =
      BorderRadius.all(Radius.circular(pill));
  static const BorderRadius borderFull =
      BorderRadius.all(Radius.circular(full));
}
