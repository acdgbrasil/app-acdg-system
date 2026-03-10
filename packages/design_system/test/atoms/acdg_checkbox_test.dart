import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('AcdgCheckbox', () {
    testWidgets('renders unchecked', (tester) async {
      await tester.pumpWidget(
        wrap(AcdgCheckbox(value: false, onChanged: (_) {})),
      );
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('renders checked', (tester) async {
      await tester.pumpWidget(
        wrap(AcdgCheckbox(value: true, onChanged: (_) {})),
      );
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });

    testWidgets('calls onChanged when tapped', (tester) async {
      bool? changed;
      await tester.pumpWidget(
        wrap(AcdgCheckbox(value: false, onChanged: (v) => changed = v)),
      );
      await tester.tap(find.byType(Checkbox));
      expect(changed, isNotNull);
    });

    testWidgets('renders label when provided', (tester) async {
      await tester.pumpWidget(
        wrap(AcdgCheckbox(
          value: false,
          onChanged: (_) {},
          label: 'Accept terms',
        )),
      );
      expect(find.text('Accept terms'), findsOneWidget);
    });

    testWidgets('tapping label toggles checkbox', (tester) async {
      bool? changed;
      await tester.pumpWidget(
        wrap(AcdgCheckbox(
          value: false,
          onChanged: (v) => changed = v,
          label: 'Toggle me',
        )),
      );
      await tester.tap(find.text('Toggle me'));
      expect(changed, isTrue);
    });

    testWidgets('is disabled when enabled is false', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgCheckbox(
          value: false,
          onChanged: null,
          enabled: false,
        )),
      );
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.onChanged, isNull);
    });

    testWidgets('supports tristate (indeterminate)', (tester) async {
      await tester.pumpWidget(
        wrap(AcdgCheckbox(
          value: null,
          onChanged: (_) {},
          tristate: true,
        )),
      );
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isNull);
      expect(checkbox.tristate, isTrue);
    });
  });
}
