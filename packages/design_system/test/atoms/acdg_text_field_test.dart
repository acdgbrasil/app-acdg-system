import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)));
  }

  group('AcdgTextField', () {
    testWidgets('renders with hint text', (tester) async {
      await tester.pumpWidget(wrap(const AcdgTextField(hint: 'Enter name')));
      expect(find.text('Enter name'), findsOneWidget);
    });

    testWidgets('renders label when provided', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgTextField(label: 'Name', hint: 'Enter name')),
      );
      expect(find.text('Name'), findsOneWidget);
    });

    testWidgets('calls onChanged when text is entered', (tester) async {
      String? changed;
      await tester.pumpWidget(
        wrap(AcdgTextField(onChanged: (v) => changed = v)),
      );
      await tester.enterText(find.byType(TextField), 'Hello');
      expect(changed, 'Hello');
    });

    testWidgets('shows error text', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgTextField(errorText: 'Required field')),
      );
      await tester.pump();
      expect(find.text('Required field'), findsOneWidget);
    });

    testWidgets('shows helper text', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgTextField(helperText: 'Some help')),
      );
      expect(find.text('Some help'), findsOneWidget);
    });

    testWidgets('is disabled when enabled is false', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgTextField(enabled: false, hint: 'Disabled')),
      );
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('renders suffix icon', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgTextField(
          suffixIcon: Icon(Icons.visibility_off),
        )),
      );
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });
  });
}
