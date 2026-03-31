import 'package:design_system/design_system.dart';
import 'package:design_system/src/organisms/acdg_registration_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AcdgRegistrationHeader Organisms', () {
    testWidgets('should render title and breadcrumbs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AcdgRegistrationHeader(
              title: 'Pessoa de Referência',
              breadcrumbs: [
                BreadcrumbItem(label: 'Famílias'),
                BreadcrumbItem(label: 'Cadastro', isActive: true),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Pessoa de Referência'), findsOneWidget);
      expect(find.text('Famílias'), findsOneWidget);
      expect(find.text('Cadastro'), findsOneWidget);
    });

    testWidgets('should render trailing action when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AcdgRegistrationHeader(
              title: 'Test',
              breadcrumbs: [BreadcrumbItem(label: 'A')],
              trailingAction: Text('Action'),
            ),
          ),
        ),
      );

      expect(find.text('Action'), findsOneWidget);
    });
  });
}
