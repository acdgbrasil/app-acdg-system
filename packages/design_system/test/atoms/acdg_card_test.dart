import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('AcdgCard', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgCard(child: Text('Content'))),
      );
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(AcdgCard(onTap: () => tapped = true, child: const Text('Tap me'))),
      );
      await tester.tap(find.text('Tap me'));
      expect(tapped, isTrue);
    });

    testWidgets('does not wrap in GestureDetector when onTap is null', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgCard(child: Text('No tap'))),
      );
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('applies custom padding', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgCard(
          padding: EdgeInsets.all(32),
          child: Text('Padded'),
        )),
      );
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, AcdgColors.surface);
    });

    testWidgets('applies border color', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgCard(
          borderColor: Colors.red,
          child: Text('Bordered'),
        )),
      );
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    testWidgets('applies background color', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgCard(
          backgroundColor: AcdgColors.navy,
          child: Text('Dark'),
        )),
      );
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, AcdgColors.navy);
    });
  });
}
