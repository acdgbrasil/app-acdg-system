import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:conecta_raros/auth/auth_view_model.dart';
import 'package:conecta_raros/router/app_router.dart';
import '../auth/fake_auth_service.dart';

void main() {
  late FakeAuthService fakeService;
  late AuthViewModel authViewModel;
  late AppRouter appRouter;

  setUp(() {
    fakeService = FakeAuthService();
    authViewModel = AuthViewModel(authService: fakeService);
    appRouter = AppRouter(authViewModel: authViewModel);
  });

  tearDown(() {
    authViewModel.dispose();
    fakeService.dispose();
  });

  Widget buildApp() {
    return ChangeNotifierProvider.value(
      value: authViewModel,
      child: MaterialApp.router(
        routerConfig: appRouter.router,
        theme: AcdgTheme.light,
      ),
    );
  }

  group('AppRouter global redirect', () {
    testWidgets('shows splash while AuthLoading', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.text('Conecta Raros'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('redirects to login when Unauthenticated', (tester) async {
      await authViewModel.init();
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Entrar com ACDG'), findsOneWidget);
    });

    testWidgets('redirects to home when Authenticated', (tester) async {
      fakeService.hasExistingSession = true;
      await authViewModel.init();
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Bem-vindo ao Conecta Raros'), findsOneWidget);
    });

    testWidgets('redirects to login on AuthError', (tester) async {
      fakeService.loginShouldFail = true;
      await authViewModel.init();
      await authViewModel.login();
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Entrar com ACDG'), findsOneWidget);
    });
  });

  group('AppRouter navigation flow', () {
    testWidgets('login -> authenticated -> navigates to home', (tester) async {
      await authViewModel.init();
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Entrar com ACDG'), findsOneWidget);

      await authViewModel.login();
      await tester.pumpAndSettle();

      expect(find.text('Bem-vindo ao Conecta Raros'), findsOneWidget);
    });

    testWidgets('authenticated -> logout -> navigates to login',
        (tester) async {
      fakeService.hasExistingSession = true;
      await authViewModel.init();
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Bem-vindo ao Conecta Raros'), findsOneWidget);

      await authViewModel.logout();
      await tester.pumpAndSettle();

      expect(find.text('Entrar com ACDG'), findsOneWidget);
    });
  });

  group('AppRouter requireRole (unit)', () {
    // These test the guard function in isolation using a fake GoRouterState.
    // The guard only reads authViewModel.status — not the GoRouterState.

    GoRouterState fakeState() => _FakeGoRouterState();

    test('returns null when user has required role', () {
      const user = AuthUser(id: '1', roles: {AuthRole.admin});
      authViewModel.status.value = const Authenticated(user);

      final guard = appRouter.requireRole({AuthRole.admin});
      expect(guard(_FakeBuildContext(), fakeState()), isNull);
    });

    test('redirects to /home when user lacks required role', () {
      const user = AuthUser(id: '1', roles: {AuthRole.owner});
      authViewModel.status.value = const Authenticated(user);

      final guard = appRouter.requireRole({AuthRole.admin});
      expect(guard(_FakeBuildContext(), fakeState()), AppRoutes.home);
    });

    test('redirects to /login when not authenticated', () {
      authViewModel.status.value = const Unauthenticated();

      final guard = appRouter.requireRole({AuthRole.admin});
      expect(guard(_FakeBuildContext(), fakeState()), AppRoutes.login);
    });
  });

  group('AppRoutes constants', () {
    test('paths are correct', () {
      expect(AppRoutes.splash, '/');
      expect(AppRoutes.login, '/login');
      expect(AppRoutes.home, '/home');
    });
  });
}

class _FakeBuildContext extends Fake implements BuildContext {}

class _FakeGoRouterState extends Fake implements GoRouterState {}
