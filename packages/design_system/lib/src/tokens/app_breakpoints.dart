/// Design tokens for layout breakpoints and device classification.
abstract final class AppBreakpoints {
  /// < 600px - Small mobile devices
  static const double mobile = 0;

  /// 600px — 1199px - Tablets and split-screen desktop
  static const double tablet = 600;

  /// ≥ 1200px - Monitors and large laptop screens
  static const double desktop = 1200;

  /// Identifies if the current width corresponds to a mobile device.
  static bool isMobile(double width) => width < tablet;

  /// Identifies if the current width corresponds to a tablet device.
  static bool isTablet(double width) => width >= tablet && width < desktop;

  /// Identifies if the current width corresponds to a desktop device.
  static bool isDesktop(double width) => width >= desktop;
}
