import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AcdgRadioButton Atoms', () {
    testWidgets('should render as a rounded square', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcdgRadioButton<String>(
              value: 'A',
              groupValue: 'B',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final containerFinder = find
          .descendant(
            of: find.byType(AcdgRadioButton<String>),
            matching: find.byType(Container),
          )
          .at(1); // Inner container with decoration

      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;

      // Should not be circular (BoxShape.rectangle is default)
      expect(decoration.shape, BoxShape.rectangle);
      expect(decoration.borderRadius, isNotNull);
    });

    testWidgets('should show selection indicator when value matches groupValue', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcdgRadioButton<String>(
              value: 'A',
              groupValue: 'A',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // In our design, selection is a filled central area or a smaller rounded square
      // We check for the presence of the inner indicator container color
      final indicatorFinder = find
          .descendant(
            of: find.byType(AcdgRadioButton<String>),
            matching: find.byType(AnimatedContainer),
          )
          .last; // The innermost AnimatedContainer is the indicator

      final container = tester.widget<AnimatedContainer>(indicatorFinder);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.color, AppColors.primary);
    });
  });
}
