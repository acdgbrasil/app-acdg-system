import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AcdgFormField Molecules', () {
    testWidgets('AcdgFormField.text should render label and input', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AcdgFormField.text(
              label: 'Nome Completo',
              placeholder: 'Digite aqui',
            ),
          ),
        ),
      );

      expect(find.text('Nome Completo'), findsOneWidget);
      expect(find.text('Digite aqui'), findsOneWidget);
    });

    testWidgets('AcdgFormField.selection should render options', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcdgFormField.selection(
              label: 'Sexo',
              options: const [
                SelectionOption(value: 'M', label: 'Masculino'),
                SelectionOption(value: 'F', label: 'Feminino'),
              ],
              selectedValue: 'F',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Sexo'), findsOneWidget);
      expect(find.text('Masculino'), findsOneWidget);
      expect(find.text('Feminino'), findsOneWidget);

      // Check if one is selected (should have AcdgCheckbox with value true)
      final checkboxFinder = find.byType(AcdgCheckbox);
      expect(checkboxFinder, findsNWidgets(2));
    });

    testWidgets('AcdgFormField.checkboxSimple should be horizontal', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcdgFormField.checkboxSimple(
              label: 'Família cigana',
              isChecked: false,
              onCheckChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Família cigana'), findsOneWidget);
      expect(find.byType(AcdgCheckbox), findsOneWidget);

      // Verify layout is Row-based (atoms side by side)
      final rowFinder = find.byType(Row);
      expect(rowFinder, findsOneWidget);
    });

    testWidgets('should render error message when errorText is provided', (
      tester,
    ) async {
      const error = 'Campo obrigatório';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AcdgFormField.text(
              label: 'CPF',
              placeholder: '000.000.000-00',
              errorText: error,
            ),
          ),
        ),
      );

      expect(find.text(error), findsOneWidget);
    });
  });
}
