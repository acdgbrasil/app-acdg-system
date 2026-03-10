import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)));
  }

  final items = [
    const AcdgDropdownItem(value: 'a', label: 'Option A'),
    const AcdgDropdownItem(value: 'b', label: 'Option B'),
    const AcdgDropdownItem(value: 'c', label: 'Option C'),
  ];

  group('AcdgDropdown', () {
    testWidgets('renders with hint text', (tester) async {
      await tester.pumpWidget(
        wrap(AcdgDropdown<String>(
          items: items,
          onChanged: (_) {},
          hint: 'Selecione',
        )),
      );
      expect(find.text('Selecione'), findsOneWidget);
    });

    testWidgets('renders label when provided', (tester) async {
      await tester.pumpWidget(
        wrap(AcdgDropdown<String>(
          items: items,
          onChanged: (_) {},
          label: 'Parentesco',
        )),
      );
      expect(find.text('Parentesco'), findsOneWidget);
    });

    testWidgets('displays selected value', (tester) async {
      await tester.pumpWidget(
        wrap(AcdgDropdown<String>(
          items: items,
          value: 'b',
          onChanged: (_) {},
        )),
      );
      expect(find.text('Option B'), findsOneWidget);
    });

    testWidgets('calls onChanged when item is selected', (tester) async {
      String? selected;
      await tester.pumpWidget(
        wrap(AcdgDropdown<String>(
          items: items,
          onChanged: (v) => selected = v,
          hint: 'Pick',
        )),
      );
      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Option A').last);
      await tester.pumpAndSettle();
      expect(selected, 'a');
    });

    testWidgets('shows error text', (tester) async {
      await tester.pumpWidget(
        wrap(AcdgDropdown<String>(
          items: items,
          onChanged: (_) {},
          errorText: 'Campo obrigatório',
        )),
      );
      await tester.pump();
      expect(find.text('Campo obrigatório'), findsOneWidget);
    });

    testWidgets('renders dropdown icon', (tester) async {
      await tester.pumpWidget(
        wrap(AcdgDropdown<String>(
          items: items,
          onChanged: (_) {},
        )),
      );
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });
  });
}
