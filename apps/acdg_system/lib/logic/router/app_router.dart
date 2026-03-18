import 'package:acdg_system/pages/home_page.dart';
import 'package:acdg_system/pages/login_page.dart';
import 'package:acdg_system/pages/splash_page.dart';
import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../ui/view_models/auth_view_model.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const patientRegistration = '/patient-registration';
}

class AppRouter {
  AppRouter({required this.authViewModel});

  final AuthViewModel authViewModel;

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authViewModel,
    redirect: _globalRedirect,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => LoginPage(viewModel: authViewModel),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
        redirect: _requireAuth,
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Pagina nao encontrada: ${state.uri}')),
    ),
  );

  String? _globalRedirect(BuildContext context, GoRouterState state) {
    final status = authViewModel.status.value;
    final currentPath = state.uri.path;
    final isOnSplash = currentPath == AppRoutes.splash;
    final isOnLogin = currentPath == AppRoutes.login;

    return switch (status) {
      AuthLoading() => isOnSplash ? null : AppRoutes.splash,
      Unauthenticated() => isOnLogin ? null : AppRoutes.login,
      AuthError() => isOnLogin ? null : AppRoutes.login,
      Authenticated() => (isOnSplash || isOnLogin) ? AppRoutes.home : null,
    };
  }

  String? _requireAuth(BuildContext context, GoRouterState state) {
    final status = authViewModel.status.value;
    if (status is! Authenticated) return AppRoutes.login;
    return null;
  }

  String? Function(BuildContext, GoRouterState) requireRole(
    Set<AuthRole> roles,
  ) {
    return (context, state) {
      final status = authViewModel.status.value;
      if (status is! Authenticated) return AppRoutes.login;
      if (!status.user.hasAnyRole(roles)) return AppRoutes.home;
      return null;
    };
  }
}
