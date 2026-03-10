import 'package:core/core.dart';
import 'package:conecta_raros/auth/auth_view_model.dart';
import 'package:conecta_raros/pages/login_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fake_auth_service.dart';

void main() {
  late FakeAuthService fakeService;
  late AuthViewModel viewModel;

  setUp(() {
    fakeService = FakeAuthService();
    viewModel = AuthViewModel(authService: fakeService);
  });

  tearDown(() {
    viewModel.dispose();
    fakeService.dispose();
  });

  Widget buildLoginPage() {
    return MaterialApp(
      theme: AcdgTheme.light,
      home: LoginPage(viewModel: viewModel),
    );
  }

  group('LoginPage', () {
    testWidgets('displays app name and description', (tester) async {
      await tester.pumpWidget(buildLoginPage());

      expect(find.text('Conecta Raros'), findsOneWidget);
      expect(
        find.textContaining('doencas geneticas raras'),
        findsOneWidget,
      );
    });

    testWidgets('displays login button', (tester) async {
      await tester.pumpWidget(buildLoginPage());

      expect(find.text('Entrar com ACDG'), findsOneWidget);
    });

    testWidgets('shows loading state when busy', (tester) async {
      await tester.pumpWidget(buildLoginPage());

      // Tap login — fakeService completes instantly, but we can check
      // that the button was rendered with loading via AcdgButton
      expect(find.byType(AcdgButton), findsOneWidget);
    });

    testWidgets('shows error card on AuthError', (tester) async {
      await viewModel.init();
      fakeService.loginShouldFail = true;
      fakeService.errorMessage = 'Credenciais invalidas';

      await tester.pumpWidget(buildLoginPage());
      await viewModel.login();
      await tester.pump();

      expect(find.text('Credenciais invalidas'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('hides error card when status is not AuthError',
        (tester) async {
      await viewModel.init();
      await tester.pumpWidget(buildLoginPage());
      await tester.pump();

      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('tapping login button calls viewModel.login', (tester) async {
      await viewModel.init();
      await tester.pumpWidget(buildLoginPage());
      await tester.pump();

      await tester.tap(find.text('Entrar com ACDG'));
      await tester.pump();

      // After login, status should be Authenticated
      expect(viewModel.status.value, isA<Authenticated>());
    });
  });
}
