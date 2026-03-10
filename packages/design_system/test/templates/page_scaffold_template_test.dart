import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child, {Size size = const Size(800, 600)}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: child,
      ),
    );
  }

  group('PageScaffoldTemplate', () {
    testWidgets('renders title in appBar', (tester) async {
      await tester.pumpWidget(
        wrap(const PageScaffoldTemplate(
          title: 'Pacientes',
          body: Center(child: Text('Body')),
        )),
      );
      expect(find.text('Pacientes'), findsOneWidget);
    });

    testWidgets('renders body', (tester) async {
      await tester.pumpWidget(
        wrap(const PageScaffoldTemplate(
          title: 'Page',
          body: Text('Body content'),
        )),
      );
      expect(find.text('Body content'), findsOneWidget);
    });

    testWidgets('shows back button when showBackButton is true', (tester) async {
      await tester.pumpWidget(
        wrap(const PageScaffoldTemplate(
          title: 'Detail',
          body: Text('Detail'),
          showBackButton: true,
        )),
      );
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('does not show back button by default', (tester) async {
      await tester.pumpWidget(
        wrap(const PageScaffoldTemplate(
          title: 'Home',
          body: Text('Home'),
        )),
      );
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('renders appBar actions', (tester) async {
      await tester.pumpWidget(
        wrap(PageScaffoldTemplate(
          title: 'Page',
          body: const Text('Body'),
          actions: [
            IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
          ],
        )),
      );
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('hides sidebar on narrow screens', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrap(
          const PageScaffoldTemplate(
            title: 'Page',
            body: Text('Main'),
            sidebar: Text('Sidebar'),
          ),
          size: const Size(800, 600),
        ),
      );
      expect(find.text('Sidebar'), findsNothing);
    });
  });
}
