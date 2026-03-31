import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AcdgUnderlineInput Atoms', () {
    testWidgets('should render with correct placeholder style', (tester) async {
      const placeholder = 'Digite seu nome';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AcdgUnderlineInput(hintText: placeholder)),
        ),
      );

      final textFinder = find.text(placeholder);
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.fontFamily, 'Erode');
      expect(textWidget.style?.fontStyle, FontStyle.italic);
    });

    testWidgets('should render with a bottom border (underline style)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AcdgUnderlineInput(hintText: 'Test')),
        ),
      );

      final containerFinder = find
          .descendant(
            of: find.byType(AcdgUnderlineInput),
            matching: find.byType(Container),
          )
          .first;

      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.border, isNotNull);
      expect(decoration.border?.bottom, isNotNull);
      expect(decoration.border?.bottom.color, AppColors.inputLine);
    });
  });
}
