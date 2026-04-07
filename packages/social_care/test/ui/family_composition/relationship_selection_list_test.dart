import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:social_care/src/ui/family_composition/view/components/hoverable_relationship_item.dart';
import 'package:social_care/src/ui/family_composition/view/components/relationship_selection_list.dart';

void main() {
  group('RelationshipSelectionList', () {
    final testLookup = <LookupItem>[
      const LookupItem(id: '1', codigo: 'MAE', descricao: 'Mae'),
      const LookupItem(id: '2', codigo: 'PAI', descricao: 'Pai'),
      const LookupItem(
        id: '3',
        codigo: 'PESSOA_REFERENCIA',
        descricao: 'Pessoa de Referencia',
      ),
    ];

    testWidgets('renders items excluding PESSOA_REFERENCIA', (tester) async {
      final notifier = ValueNotifier<String?>(null);
      addTearDown(notifier.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RelationshipSelectionList(
              parentescoLookup: testLookup,
              relationshipNotifier: notifier,
              error: null,
              showErrors: false,
            ),
          ),
        ),
      );

      expect(find.text('Mae'), findsOneWidget);
      expect(find.text('Pai'), findsOneWidget);
      expect(find.text('Pessoa de Referencia'), findsNothing);
      expect(find.byType(HoverableRelationshipItem), findsNWidgets(2));
    });

    testWidgets('displays error when showErrors is true and error is provided',
        (tester) async {
      final notifier = ValueNotifier<String?>(null);
      addTearDown(notifier.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RelationshipSelectionList(
              parentescoLookup: testLookup,
              relationshipNotifier: notifier,
              error: 'Campo obrigatorio',
              showErrors: true,
            ),
          ),
        ),
      );

      expect(find.text('Campo obrigatorio'), findsOneWidget);
    });

    testWidgets('does not display error when showErrors is false',
        (tester) async {
      final notifier = ValueNotifier<String?>(null);
      addTearDown(notifier.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RelationshipSelectionList(
              parentescoLookup: testLookup,
              relationshipNotifier: notifier,
              error: 'Campo obrigatorio',
              showErrors: false,
            ),
          ),
        ),
      );

      expect(find.text('Campo obrigatorio'), findsNothing);
    });

    testWidgets('updates notifier when an item is tapped', (tester) async {
      final notifier = ValueNotifier<String?>(null);
      addTearDown(notifier.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RelationshipSelectionList(
              parentescoLookup: testLookup,
              relationshipNotifier: notifier,
              error: null,
              showErrors: false,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pai'));
      await tester.pumpAndSettle();

      expect(notifier.value, 'PAI');
    });
  });
}
