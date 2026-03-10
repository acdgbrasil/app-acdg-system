import 'package:core/core.dart';
import 'package:conecta_raros/auth/auth_view_model.dart';
import 'package:conecta_raros/pages/home_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../auth/fake_auth_service.dart';

void main() {
  late FakeAuthService fakeService;
  late AuthViewModel viewModel;

  setUp(() {
    fakeService = FakeAuthService();
    fakeService.hasExistingSession = true;
    viewModel = AuthViewModel(authService: fakeService);
  });

  tearDown(() {
    viewModel.dispose();
    fakeService.dispose();
  });

  Widget buildHomePage() {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: MaterialApp(
        theme: AcdgTheme.light,
        home: const HomePage(),
      ),
    );
  }

  group('HomePage', () {
    testWidgets('displays welcome message', (tester) async {
      await viewModel.init();
      await tester.pumpWidget(buildHomePage());
      await tester.pump();

      expect(find.text('Bem-vindo ao Conecta Raros'), findsOneWidget);
    });

    testWidgets('displays user name in app bar', (tester) async {
      await viewModel.init();
      await tester.pumpWidget(buildHomePage());
      await tester.pump();

      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('displays user initials in avatar', (tester) async {
      await viewModel.init();
      await tester.pumpWidget(buildHomePage());
      await tester.pump();

      expect(find.text('TU'), findsOneWidget);
    });

    testWidgets('shows Social Care card for socialWorker', (tester) async {
      await viewModel.init();
      await tester.pumpWidget(buildHomePage());
      await tester.pump();

      expect(find.text('Social Care'), findsOneWidget);
      expect(find.textContaining('Cadastro'), findsOneWidget);
    });

    testWidgets('shows read-only card for owner role', (tester) async {
      fakeService.loginUser = const AuthUser(
        id: '2',
        name: 'Owner User',
        roles: {AuthRole.owner},
      );
      await viewModel.init();
      await tester.pumpWidget(buildHomePage());
      await tester.pump();

      expect(find.text('Social Care (somente leitura)'), findsOneWidget);
    });

    testWidgets('shows user menu on tap', (tester) async {
      await viewModel.init();
      await tester.pumpWidget(buildHomePage());
      await tester.pump();

      // Tap the user menu area
      await tester.tap(find.text('Test User'));
      await tester.pumpAndSettle();

      // Menu should show email and role
      expect(find.text('test@acdg.com.br'), findsOneWidget);
      expect(find.text('Assistente Social'), findsOneWidget);
      expect(find.text('Sair'), findsOneWidget);
    });

    testWidgets('logout via menu triggers viewModel.logout', (tester) async {
      await viewModel.init();
      await tester.pumpWidget(buildHomePage());
      await tester.pump();

      // Open menu
      await tester.tap(find.text('Test User'));
      await tester.pumpAndSettle();

      // Tap logout
      await tester.tap(find.text('Sair'));
      await tester.pumpAndSettle();

      expect(viewModel.status.value, isA<Unauthenticated>());
    });
  });
}
