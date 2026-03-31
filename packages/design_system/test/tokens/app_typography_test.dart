import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTypography Responsive Scaling', () {
    test('displayLarge should scale correctly across breakpoints', () {
      // Desktop
      expect(AppTypography.displayLarge(1200).fontSize, 96);
      expect(AppTypography.displayLarge(1200).letterSpacing, -2.88);

      // Tablet
      expect(AppTypography.displayLarge(810).fontSize, 64);
      expect(AppTypography.displayLarge(810).letterSpacing, -1.92);

      // Mobile
      expect(AppTypography.displayLarge(390).fontSize, 40);
      expect(AppTypography.displayLarge(390).letterSpacing, -1.2);
    });

    test('headingLarge should scale correctly across breakpoints', () {
      expect(AppTypography.headingLarge(1200).fontSize, 32);
      expect(AppTypography.headingLarge(810).fontSize, 20);
      expect(AppTypography.headingLarge(390).fontSize, 16);
    });

    test('buttonText should scale correctly across breakpoints', () {
      expect(AppTypography.buttonText(1200).fontSize, 20);
      expect(AppTypography.buttonText(810).fontSize, 16);
      expect(AppTypography.buttonText(390).fontSize, 14);
    });
  });
}
