import 'package:design_system/design_system.dart';
import 'package:design_system/src/atoms/acdg_checkbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AcdgCheckbox Atoms', () {
    testWidgets('should render with correct dimensions (24x24)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AcdgCheckbox(value: false, onChanged: (_) {})),
        ),
      );

      final checkboxFinder = find.byType(AcdgCheckbox);
      expect(tester.getSize(checkboxFinder), const Size(24, 24));
    });

    testWidgets('should show check icon when value is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AcdgCheckbox(value: true, onChanged: (_) {})),
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
