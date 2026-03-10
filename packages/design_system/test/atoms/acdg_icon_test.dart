import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('AcdgIcon', () {
    testWidgets('renders the icon', (tester) async {
      await tester.pumpWidget(wrap(const AcdgIcon(Icons.home)));
      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets('default size is medium (24)', (tester) async {
      await tester.pumpWidget(wrap(const AcdgIcon(Icons.home)));
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, 24);
    });

    testWidgets('small size is 16', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgIcon(Icons.info, size: AcdgIconSize.small)),
      );
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, 16);
    });

    testWidgets('large size is 32', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgIcon(Icons.close, size: AcdgIconSize.large)),
      );
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, 32);
    });

    testWidgets('applies custom color', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgIcon(Icons.star, color: Colors.amber)),
      );
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, Colors.amber);
    });

    testWidgets('applies semantic label', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgIcon(Icons.home, semanticLabel: 'Home icon')),
      );
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.semanticLabel, 'Home icon');
    });
  });
}
