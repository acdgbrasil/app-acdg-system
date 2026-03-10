import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)));
  }

  group('AcdgInfoCard', () {
    testWidgets('renders message', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgInfoCard(message: 'Some info')),
      );
      expect(find.text('Some info'), findsOneWidget);
    });

    testWidgets('renders title when provided', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgInfoCard(title: 'Atenção', message: 'Detalhes')),
      );
      expect(find.text('Atenção'), findsOneWidget);
      expect(find.text('Detalhes'), findsOneWidget);
    });

    testWidgets('shows info icon by default', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgInfoCard(message: 'Info')),
      );
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('shows error icon for error type', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgInfoCard(
          message: 'Erro',
          type: AcdgInfoCardType.error,
        )),
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows success icon for success type', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgInfoCard(
          message: 'OK',
          type: AcdgInfoCardType.success,
        )),
      );
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('shows warning icon for warning type', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgInfoCard(
          message: 'Cuidado',
          type: AcdgInfoCardType.warning,
        )),
      );
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    });

    testWidgets('shows dismiss button when onDismiss provided', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(
        wrap(AcdgInfoCard(
          message: 'Dismiss me',
          onDismiss: () => dismissed = true,
        )),
      );
      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      expect(dismissed, isTrue);
    });

    testWidgets('does not show dismiss button by default', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgInfoCard(message: 'No dismiss')),
      );
      expect(find.byIcon(Icons.close), findsNothing);
    });
  });
}
