import 'package:design_system/design_system.dart';
import 'package:design_system/src/atoms/acdg_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AcdgText Atoms', () {
    testWidgets('should apply displayLarge style correctly', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AcdgText('Title', variant: AcdgTextVariant.displayLarge),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(textWidget.style?.fontSize, 96);
      expect(textWidget.style?.fontFamily, 'Satoshi');

      addTearDown(tester.view.resetPhysicalSize);
    });

    testWidgets('should adapt style on Mobile width', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AcdgText('Title', variant: AcdgTextVariant.displayLarge),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(textWidget.style?.fontSize, 40);

      addTearDown(tester.view.resetPhysicalSize);
    });
  });
}
