import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  final items = [
    const AcdgRadioItem<String>(value: 'male', label: 'Masculino'),
    const AcdgRadioItem<String>(value: 'female', label: 'Feminino'),
  ];

  group('AcdgRadioGroup', () {
    testWidgets('renders radio buttons for each item', (tester) async {
      await tester.pumpWidget(
        wrap(AcdgRadioGroup<String>(
          groupValue: null,
          onChanged: (_) {},
          items: items,
        )),
      );
      expect(find.byType(Radio<String>), findsNWidgets(2));
    });

    testWidgets('renders labels', (tester) async {
      await tester.pumpWidget(
        wrap(AcdgRadioGroup<String>(
          groupValue: null,
          onChanged: (_) {},
          items: items,
        )),
      );
      expect(find.text('Masculino'), findsOneWidget);
      expect(find.text('Feminino'), findsOneWidget);
    });

    testWidgets('calls onChanged when label is tapped', (tester) async {
      String? changed;
      await tester.pumpWidget(
        wrap(AcdgRadioGroup<String>(
          groupValue: null,
          onChanged: (v) => changed = v,
          items: items,
        )),
      );
      await tester.tap(find.text('Feminino'));
      expect(changed, 'female');
    });

    testWidgets('renders items without labels', (tester) async {
      final noLabelItems = [
        const AcdgRadioItem<int>(value: 1),
        const AcdgRadioItem<int>(value: 2),
      ];
      await tester.pumpWidget(
        wrap(AcdgRadioGroup<int>(
          groupValue: null,
          onChanged: (_) {},
          items: noLabelItems,
        )),
      );
      expect(find.byType(Radio<int>), findsNWidgets(2));
    });

    testWidgets('does not call onChanged when disabled', (tester) async {
      String? changed;
      await tester.pumpWidget(
        wrap(AcdgRadioGroup<String>(
          groupValue: null,
          onChanged: (v) => changed = v,
          items: items,
          enabled: false,
        )),
      );
      await tester.tap(find.text('Masculino'));
      expect(changed, isNull);
    });
  });
}
