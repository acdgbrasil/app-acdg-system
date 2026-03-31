import 'package:flutter/painting.dart';
import 'app_breakpoints.dart';

/// Design tokens for responsive typography based on 3 breakpoints.
abstract final class AppTypography {
  /// Display Large: Page main title.
  /// 96px (Desktop) / 64px (Tablet) / 40px (Mobile)
  static TextStyle displayLarge(double screenWidth) {
    if (AppBreakpoints.isDesktop(screenWidth)) {
      return const TextStyle(
        fontFamily: 'Satoshi',
        fontWeight: FontWeight.w700,
        fontSize: 96,
        height: 1.0,
        letterSpacing: -2.88,
      );
    } else if (AppBreakpoints.isTablet(screenWidth)) {
      return const TextStyle(
        fontFamily: 'Satoshi',
        fontWeight: FontWeight.w700,
        fontSize: 64,
        height: 1.0,
        letterSpacing: -1.92,
      );
    } else {
      return const TextStyle(
        fontFamily: 'Satoshi',
        fontWeight: FontWeight.w700,
        fontSize: 40,
        height: 1.0,
        letterSpacing: -1.2,
      );
    }
  }

  /// Heading Large: Section subtitle.
  /// 32px (Desktop) / 20px (Tablet) / 16px (Mobile)
  static TextStyle headingLarge(double screenWidth) {
    final size = AppBreakpoints.isDesktop(screenWidth)
        ? 32.0
        : AppBreakpoints.isTablet(screenWidth)
        ? 20.0
        : 16.0;
    return TextStyle(
      fontFamily: 'Satoshi',
      fontWeight: FontWeight.w700,
      fontSize: size,
    );
  }

  /// Heading Medium: Form field labels.
  /// 24px (Desktop) / 20px (Tablet) / 16px (Mobile)
  static TextStyle headingMedium(double screenWidth) {
    final size = AppBreakpoints.isDesktop(screenWidth)
        ? 24.0
        : 20.0; // Tablet and Mobile share 20px in Figma description or extrapolated 16px

    // Extrapolating for smaller mobile as per decision
    final finalSize = screenWidth < AppBreakpoints.tablet ? 16.0 : size;

    return TextStyle(
      fontFamily: 'Satoshi',
      fontWeight: FontWeight.w700,
      fontSize: finalSize,
    );
  }

  /// Heading Small: Table headers, breadcrumbs.
  /// 20px (Desktop) / 16px (Tablet) / 14px (Mobile)
  static TextStyle headingSmall(double screenWidth) {
    final size = AppBreakpoints.isDesktop(screenWidth)
        ? 20.0
        : AppBreakpoints.isTablet(screenWidth)
        ? 16.0
        : 14.0;
    return TextStyle(
      fontFamily: 'Satoshi',
      fontWeight: FontWeight.w700,
      fontSize: size,
    );
  }

  /// Body Large: Table data, field values.
  /// 20px (Desktop) / 16px (Tablet) / 14px (Mobile)
  static TextStyle bodyLarge(double screenWidth) {
    final size = AppBreakpoints.isDesktop(screenWidth)
        ? 20.0
        : AppBreakpoints.isTablet(screenWidth)
        ? 16.0
        : 14.0;
    return TextStyle(
      fontFamily: 'Satoshi',
      fontWeight: FontWeight.w400,
      fontSize: size,
    );
  }

  /// Input Placeholder: Erode Light Italic.
  /// 20px (Desktop) / 16px (Tablet) / 14px (Mobile)
  static TextStyle inputPlaceholder(double screenWidth) {
    final size = AppBreakpoints.isDesktop(screenWidth)
        ? 20.0
        : AppBreakpoints.isTablet(screenWidth)
        ? 16.0
        : 14.0;
    return TextStyle(
      fontFamily: 'Erode',
      fontWeight: FontWeight.w300,
      fontStyle: FontStyle.italic,
      fontSize: size,
    );
  }

  /// Selection Label: Text for checkbox/radio options.
  /// 20px (Desktop/Tablet) / 16px (Mobile)
  static TextStyle selectionLabel(double screenWidth) {
    final size = screenWidth < AppBreakpoints.tablet ? 16.0 : 20.0;
    return TextStyle(
      fontFamily: 'Erode',
      fontWeight: FontWeight.w400,
      fontSize: size,
    );
  }

  /// Button Text: Erode Medium Italic.
  /// 20px (Desktop) / 16px (Tablet) / 14px (Mobile)
  static TextStyle buttonText(double screenWidth) {
    final isDesktop = AppBreakpoints.isDesktop(screenWidth);
    final isTablet = AppBreakpoints.isTablet(screenWidth);
    return TextStyle(
      fontFamily: 'Erode',
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.italic,
      fontSize: isDesktop
          ? 20
          : isTablet
          ? 16
          : 14,
      letterSpacing: isDesktop
          ? 1.0
          : isTablet
          ? 0.8
          : 0.7,
    );
  }

  /// Caption: Small labels inside popup.
  static TextStyle caption(double screenWidth) {
    final size = screenWidth < AppBreakpoints.tablet ? 14.0 : 16.0;
    return TextStyle(
      fontFamily: 'Erode',
      fontWeight: FontWeight.w300,
      fontStyle: FontStyle.italic,
      fontSize: size,
    );
  }
}
