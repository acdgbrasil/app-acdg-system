import 'app_breakpoints.dart';

/// Configuration for the responsive grid system.
class GridConfig {
  final int columns;
  final double gutter;
  final double margin;

  const GridConfig({
    required this.columns,
    required this.gutter,
    required this.margin,
  });

  /// Calculates the width of an individual column given the container width.
  double columnWidth(double containerWidth) {
    final usableWidth = containerWidth - (margin * 2);
    final totalGutters = gutter * (columns - 1);
    return (usableWidth - totalGutters) / columns;
  }

  /// Calculates the width of N columns with internal gutters.
  double spanWidth(double containerWidth, int span) {
    final col = columnWidth(containerWidth);
    return (col * span) + (gutter * (span - 1));
  }
}

/// Design tokens for the grid system based on 3 breakpoints.
abstract final class AppGrid {
  // Desktop
  static const int desktopColumns = 12;
  static const double desktopGutter = 24;
  static const double desktopMargin = 72;

  // Tablet
  static const int tabletColumns = 6;
  static const double tabletGutter = 16;
  static const double tabletMargin = 40;

  // Mobile
  static const int mobileColumns = 4;
  static const double mobileGutter = 8;
  static const double mobileMargin = 16;

  /// Returns the grid configuration based on the screen width.
  static GridConfig forWidth(double width) {
    if (AppBreakpoints.isDesktop(width)) {
      return const GridConfig(
        columns: desktopColumns,
        gutter: desktopGutter,
        margin: desktopMargin,
      );
    } else if (AppBreakpoints.isTablet(width)) {
      return const GridConfig(
        columns: tabletColumns,
        gutter: tabletGutter,
        margin: tabletMargin,
      );
    } else {
      return const GridConfig(
        columns: mobileColumns,
        gutter: mobileGutter,
        margin: mobileMargin,
      );
    }
  }
}
