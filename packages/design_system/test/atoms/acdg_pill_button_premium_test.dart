import 'package:design_system/design_system.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AcdgPillButton Premium UI Specs', () {
    testWidgets('Desktop button should have multi-layered shadows', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcdgPillButton(onPressed: () {}, label: 'Premium Button'),
          ),
        ),
      );

      final containerFinder = find
          .descendant(
            of: find.byType(AcdgPillButton),
            matching: find.byType(Container),
          )
          .first;

      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;

      // Spec: Premium look requires at least 2 layers of shadows for depth
      expect(decoration.boxShadow, isNotNull);
      expect(
        decoration.boxShadow!.length,
        greaterThanOrEqualTo(2),
        reason: 'Premium buttons must have multi-layered shadows for depth',
      );

      addTearDown(tester.view.resetPhysicalSize);
    });

    testWidgets('Button should show glow effect on Hover (Desktop)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AcdgPillButton(
                onPressed: () {},
                label: 'Interactive Button',
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      // Hover over the button
      final buttonFinder = find.byType(AcdgPillButton);
      await gesture.moveTo(tester.getCenter(buttonFinder));
      await tester.pump();

      final containerFinder = find
          .descendant(of: buttonFinder, matching: find.byType(Container))
          .first;

      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;

      // Spec: Interactive elements must have a "glow" effect on hover
      // We check if the shadows include the glow color or increased blur
      final hasGlow = decoration.boxShadow!.any(
        (s) => s.color.a < 0.3 && s.blurRadius >= 5,
      );
      expect(
        hasGlow,
        isTrue,
        reason: 'Button must show a glow effect when hovered',
      );

      addTearDown(tester.view.resetPhysicalSize);
    });
  });
}
