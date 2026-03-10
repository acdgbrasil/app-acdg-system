import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('AcdgButton', () {
    testWidgets('renders the label', (tester) async {
      await tester.pumpWidget(
        wrap(AcdgButton(label: 'Click me', onPressed: () {})),
      );
      expect(find.text('Click me'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        wrap(AcdgButton(label: 'Tap', onPressed: () => pressed = true)),
      );
      await tester.tap(find.text('Tap'));
      expect(pressed, isTrue);
    });

    testWidgets('shows loading indicator when isLoading', (tester) async {
      await tester.pumpWidget(
        wrap(AcdgButton(label: 'Load', onPressed: () {}, isLoading: true)),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Load'), findsNothing);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgButton(label: 'Disabled')),
      );
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(
        wrap(AcdgButton(
          label: 'With icon',
          onPressed: () {},
          icon: Icons.add,
        )),
      );
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('With icon'), findsOneWidget);
    });

    testWidgets('expands to full width when isExpanded', (tester) async {
      await tester.pumpWidget(
        wrap(AcdgButton(
          label: 'Wide',
          onPressed: () {},
          isExpanded: true,
        )),
      );
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, double.infinity);
    });

    testWidgets('outlined variant renders OutlinedButton', (tester) async {
      await tester.pumpWidget(
        wrap(AcdgButton(
          label: 'Outlined',
          onPressed: () {},
          variant: AcdgButtonVariant.outlined,
        )),
      );
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('text variant renders TextButton', (tester) async {
      await tester.pumpWidget(
        wrap(AcdgButton(
          label: 'Text',
          onPressed: () {},
          variant: AcdgButtonVariant.text,
        )),
      );
      expect(find.byType(TextButton), findsOneWidget);
    });
  });
}
