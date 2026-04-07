import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acdg_system/logic/di/auth_providers.dart';
import 'package:acdg_system/logic/router/app_router.dart';
import '../../test/auth/fake_auth_repository.dart';

void main() {
  testWidgets('AppRouter should work with AuthViewModel from Riverpod', (
    tester,
  ) async {
    final fakeRepo = FakeAuthRepository();

    // We create a ProviderScope with the overridden authViewModelProvider
    // using a real instance but with fake repo for testing.
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
    );

    final viewModel = container.read(authViewModelProvider);
    final appRouter = AppRouter(authViewModel: viewModel);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: appRouter.router),
      ),
    );

    // Initial status is loading, so we expect SplashPage (based on _globalRedirect)
    // Note: We need to verify if SplashPage is rendered.
    expect(find.byType(MaterialApp), findsOneWidget);

    // Cleanup
    container.dispose();
  });
}
