import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_care/src/ui/shared/components/modal_side_menu.dart';

void main() {
  group('ModalSideMenu Widget Tests (Architectural Compliance)', () {
    testWidgets(
      'Deve ser um StatelessWidget puro renderizando as abas do modal',
      (WidgetTester tester) async {
        int selectedIndex = 0;

        final widget = ModalSideMenu(
          currentTabIndex: selectedIndex,
          tabs: const ['Informações', 'Documentos', 'Histórico'],
          onTabSelected: (index) {
            selectedIndex = index;
          },
        );

        await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

        expect(widget, isA<StatelessWidget>());
        expect(find.text('Informações'), findsOneWidget);
        expect(find.text('Documentos'), findsOneWidget);
        expect(find.text('Histórico'), findsOneWidget);
      },
    );

    testWidgets(
      'A View deve repassar a intenção de mudança de aba via callback (onTabSelected)',
      (WidgetTester tester) async {
        int? tappedIndex;
        final widget = ModalSideMenu(
          currentTabIndex: 0,
          tabs: const ['Informações', 'Documentos'],
          onTabSelected: (index) {
            tappedIndex = index;
          },
        );

        await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

        await tester.tap(find.text('Documentos'));
        await tester.pumpAndSettle();

        expect(tappedIndex, equals(1));
      },
    );
  });
}
