import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('AcdgText', () {
    testWidgets('renders the provided text', (tester) async {
      await tester.pumpWidget(wrap(const AcdgText('Hello')));
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('applies custom color', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgText('Colored', color: Colors.red)),
      );
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.color, Colors.red);
    });

    testWidgets('applies maxLines and overflow', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgText(
          'Long text',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        )),
      );
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('applies textAlign', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgText('Centered', textAlign: TextAlign.center)),
      );
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.textAlign, TextAlign.center);
    });

    testWidgets('default variant is bodyMedium', (tester) async {
      await tester.pumpWidget(wrap(const AcdgText('Default')));
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.fontSize, AcdgTypography.bodyMedium.fontSize);
    });

    testWidgets('headingLarge variant uses correct style', (tester) async {
      await tester.pumpWidget(
        wrap(const AcdgText('Title', variant: AcdgTextVariant.headingLarge)),
      );
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.fontSize, AcdgTypography.headingLarge.fontSize);
      expect(text.style?.fontWeight, AcdgTypography.headingLarge.fontWeight);
    });
  });
}
