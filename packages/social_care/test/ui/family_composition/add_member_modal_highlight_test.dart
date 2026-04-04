import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:social_care/src/ui/family_composition/view/components/add_member_modal.dart';

void main() {
  const prCode = 'PESSOA_REFERENCIA';
  const otherCode = 'FILHO';

  final lookups = [
    LookupItem(id: '1', codigo: prCode, descricao: 'Pessoa de Referência'),
    LookupItem(id: '2', codigo: otherCode, descricao: 'Filho(a)'),
  ];

  testWidgets('TDD: Reference Person relationship MUST NOT appear in the add member modal', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: AddMemberModal(
            parentescoLookup: lookups,
            onSave: (_) {},
          ),
        ),
      ),
    );

    // Pessoa de Referência must be filtered out — only one PR per family, created at registration
    expect(find.text('Pessoa de Referência'), findsNothing,
        reason: 'A "Pessoa de Referência" não deve aparecer no modal de adição de membros');

    // Other relationships should still be visible
    expect(find.text('Filho(a)'), findsOneWidget);
  });
}
