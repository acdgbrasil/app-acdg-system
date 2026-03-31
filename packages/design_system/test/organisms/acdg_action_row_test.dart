import 'package:design_system/design_system.dart';
import 'package:design_system/src/organisms/acdg_action_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AcdgActionRow Organisms', () {
    testWidgets('should render primary button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AcdgActionRow(
              primary: ActionButtonConfig(label: 'Avançar', onPressed: () {}),
            ),
          ),
        ),
      );

      expect(find.text('Avançar'), findsOneWidget);
    });

    testWidgets('should render all three buttons when provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AcdgActionRow(
              destructive: ActionButtonConfig(
                label: 'Limpar',
                onPressed: () {},
              ),
              secondary: ActionButtonConfig(
                label: 'Observações',
                onPressed: () {},
              ),
              primary: ActionButtonConfig(label: 'Salvar', onPressed: () {}),
            ),
          ),
        ),
      );

      expect(find.text('Limpar'), findsOneWidget);
      expect(find.text('Observações'), findsOneWidget);
      expect(find.text('Salvar'), findsOneWidget);
    });
  });
}
