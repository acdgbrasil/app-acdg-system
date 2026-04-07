import 'dart:ui';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:social_care/src/ui/family_composition/view/components/hoverable_relationship_item.dart';

void main() {
  group('HoverableRelationshipItem', () {
    const testItem = LookupItem(id: '1', codigo: 'MAE', descricao: 'Mãe');

    testWidgets('renders text with correct unselected style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoverableRelationshipItem(
              item: testItem,
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      final textFinder = find.text('Mãe');
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.fontWeight, FontWeight.w400);

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(GestureDetector),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, Colors.transparent);
    });

    testWidgets('renders text with correct selected style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoverableRelationshipItem(
              item: testItem,
              isSelected: true,
              onTap: () {},
            ),
          ),
        ),
      );

      final textFinder = find.text('Mãe');
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.fontWeight, FontWeight.w600);

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(GestureDetector),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, AppColors.background.withValues(alpha: 0.1));
    });

    testWidgets('changes background color on hover', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoverableRelationshipItem(
              item: testItem,
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      final mouseRegionFinder = find
          .descendant(
            of: find.byType(HoverableRelationshipItem),
            matching: find.byType(MouseRegion),
          )
          .first;

      // Simulate mouse enter
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(mouseRegionFinder));
      await tester.pumpAndSettle();

      var container = tester.widget<Container>(
        find.descendant(
          of: find.byType(GestureDetector),
          matching: find.byType(Container),
        ),
      );
      var decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, AppColors.background.withValues(alpha: 0.05));

      // Simulate mouse exit
      await gesture.moveTo(const Offset(1000, 1000));
      await tester.pumpAndSettle();

      container = tester.widget<Container>(
        find.descendant(
          of: find.byType(GestureDetector),
          matching: find.byType(Container),
        ),
      );
      decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, Colors.transparent);
    });

    testWidgets('emits onTap callback when clicked', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoverableRelationshipItem(
              item: testItem,
              isSelected: false,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(HoverableRelationshipItem));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('applies highlight style when isHighlighted is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoverableRelationshipItem(
              item: testItem,
              isSelected: false,
              isHighlighted: true,
              onTap: () {},
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(GestureDetector),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, AppColors.background.withValues(alpha: 0.02));
      expect(decoration?.border, isNotNull);
    });
  });
}
