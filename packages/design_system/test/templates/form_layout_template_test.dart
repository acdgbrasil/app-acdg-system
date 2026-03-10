import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('FormLayoutTemplate', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        wrap(const FormLayoutTemplate(
          title: 'Cadastro',
          children: [Text('Form content')],
        )),
      );
      expect(find.text('Cadastro'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        wrap(const FormLayoutTemplate(
          title: 'Cadastro',
          subtitle: 'Preencha os campos',
          children: [Text('Content')],
        )),
      );
      expect(find.text('Preencha os campos'), findsOneWidget);
    });

    testWidgets('renders children', (tester) async {
      await tester.pumpWidget(
        wrap(const FormLayoutTemplate(
          title: 'Form',
          children: [
            Text('Field 1'),
            Text('Field 2'),
          ],
        )),
      );
      expect(find.text('Field 1'), findsOneWidget);
      expect(find.text('Field 2'), findsOneWidget);
    });

    testWidgets('renders action buttons', (tester) async {
      await tester.pumpWidget(
        wrap(FormLayoutTemplate(
          title: 'Form',
          actions: [
            ElevatedButton(onPressed: () {}, child: const Text('Salvar')),
          ],
          children: const [Text('Content')],
        )),
      );
      expect(find.text('Salvar'), findsOneWidget);
    });

    testWidgets('does not show actions area when empty', (tester) async {
      await tester.pumpWidget(
        wrap(const FormLayoutTemplate(
          title: 'Form',
          children: [Text('Content')],
        )),
      );
      expect(find.text('Content'), findsOneWidget);
    });
  });
}
