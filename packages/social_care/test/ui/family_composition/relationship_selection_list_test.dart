import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:social_care/src/ui/family_composition/view/components/hoverable_relationship_item.dart';
import 'package:social_care/src/ui/family_composition/view/components/relationship_selection_list.dart';

void main() {
  group('RelationshipSelectionList', () {
    final testLookup = <LookupItem>[
      const LookupItem(id: '1', codigo: 'MAE', descricao: 'Mãe'),
      const LookupItem(id: '2', codigo: 'PAI', descricao: 'Pai'),
      const LookupItem(id: '3', codigo: 'PESSOA_REFERENCIA', descricao: 'Pessoa de Referência'),
    ];

    testWidgets('renders items excluding PESSOA_REFERENCIA', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RelationshipSelectionList(
              parentescoLookup: testLookup,
              selectedRelationship: null,
              onChanged: (v) {},
              error: null,
              showErrors: false,
            ),
          ),
        ),
      );

      // Should find Mãe and Pai
      expect(find.text('Mãe'), findsOneWidget);
      expect(find.text('Pai'), findsOneWidget);

      // Should NOT find Pessoa Referência
      expect(find.text('Pessoa de Referência'), findsNothing);

      // Should have 2 HoverableRelationshipItem widgets
      expect(find.byType(HoverableRelationshipItem), findsNWidgets(2));
    });

    testWidgets('displays error when showErrors is true and error is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RelationshipSelectionList(
              parentescoLookup: testLookup,
              selectedRelationship: null,
              onChanged: (v) {},
              error: 'Campo obrigatório',
              showErrors: true,
            ),
          ),
        ),
      );

      expect(find.text('Campo obrigatório'), findsOneWidget);
    });

    testWidgets('does not display error when showErrors is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RelationshipSelectionList(
              parentescoLookup: testLookup,
              selectedRelationship: null,
              onChanged: (v) {},
              error: 'Campo obrigatório',
              showErrors: false,
            ),
          ),
        ),
      );

      expect(find.text('Campo obrigatório'), findsNothing);
    });

    testWidgets('emits onChanged when an item is tapped', (tester) async {
      String? selectedVal;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RelationshipSelectionList(
              parentescoLookup: testLookup,
              selectedRelationship: null,
              onChanged: (v) {
                selectedVal = v;
              },
              error: null,
              showErrors: false,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pai'));
      await tester.pumpAndSettle();

      expect(selectedVal, 'PAI');
    });
  });
}
