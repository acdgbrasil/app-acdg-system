import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AcdgPillButton Atoms', () {
    testWidgets('should render with 72px height on Desktop', (tester) async {
      // Set surface size to Desktop
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcdgPillButton(onPressed: () {}, label: 'Test'),
          ),
        ),
      );

      final buttonFinder = find.byType(AcdgPillButton);
      expect(tester.getSize(buttonFinder).height, 72.0);

      addTearDown(tester.view.resetPhysicalSize);
    });

    testWidgets('should render with 56px height on Tablet', (tester) async {
      tester.view.physicalSize = const Size(810, 1080);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcdgPillButton(onPressed: () {}, label: 'Test'),
          ),
        ),
      );

      final buttonFinder = find.byType(AcdgPillButton);
      expect(tester.getSize(buttonFinder).height, 56.0);

      addTearDown(tester.view.resetPhysicalSize);
    });

    testWidgets('should render with correct colors for primary variant', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcdgPillButton(
              onPressed: () {},
              label: 'Test',
              variant: AcdgPillButtonVariant.primary,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(AcdgPillButton),
              matching: find.byType(Container),
            )
            .first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.primary);
    });
  });
}
