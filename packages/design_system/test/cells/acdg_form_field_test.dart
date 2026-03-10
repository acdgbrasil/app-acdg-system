import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)));
  }

  group('AcdgFormField', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgFormField(label: 'Nome', child: TextField())),
      );
      expect(find.text('Nome'), findsOneWidget);
    });

    testWidgets('shows required indicator', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgFormField(
          label: 'CPF',
          isRequired: true,
          child: TextField(),
        )),
      );
      expect(find.text(' *'), findsOneWidget);
    });

    testWidgets('does not show required indicator by default', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgFormField(label: 'Nome', child: TextField())),
      );
      expect(find.text(' *'), findsNothing);
    });

    testWidgets('shows error text with icon', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgFormField(
          label: 'Email',
          errorText: 'Campo obrigatório',
          child: TextField(),
        )),
      );
      expect(find.text('Campo obrigatório'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows helper text when no error', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgFormField(
          label: 'Senha',
          helperText: 'Mínimo 8 caracteres',
          child: TextField(),
        )),
      );
      expect(find.text('Mínimo 8 caracteres'), findsOneWidget);
    });

    testWidgets('error takes precedence over helper', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgFormField(
          label: 'Senha',
          helperText: 'Mínimo 8 caracteres',
          errorText: 'Senha muito curta',
          child: TextField(),
        )),
      );
      expect(find.text('Senha muito curta'), findsOneWidget);
      expect(find.text('Mínimo 8 caracteres'), findsNothing);
    });

    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgFormField(
          label: 'Teste',
          child: Text('Child widget'),
        )),
      );
      expect(find.text('Child widget'), findsOneWidget);
    });
  });
}
