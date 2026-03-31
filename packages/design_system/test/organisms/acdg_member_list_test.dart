import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testMembers = [
    const FamilyMemberUIModel(
      id: '1',
      fullName: 'Davi Costa',
      age: 25,
      sex: 'Masculino',
      relationship: 'Pessoa de Referência',
      hasDisability: true,
      documents: {RequiredDoc.cn: true, RequiredDoc.rg: false},
    ),
  ];

  group('AcdgMemberList Organisms', () {
    testWidgets('should render table on Desktop', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AcdgMemberList(members: testMembers)),
        ),
      );

      expect(find.text('Nome'), findsOneWidget); // Header
      expect(find.text('Davi Costa'), findsOneWidget);
      expect(find.byType(AcdgMemberTableRow), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
    });

    testWidgets('should render cards on Mobile', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AcdgMemberList(members: testMembers)),
        ),
      );

      expect(find.text('Nome'), findsNWidgets(1)); // One for label inside card
      expect(find.text('Davi Costa'), findsOneWidget);
      expect(find.byType(AcdgMemberCard), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
    });
  });
}
