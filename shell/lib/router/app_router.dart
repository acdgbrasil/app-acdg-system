import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_view_model.dart';
import '../pages/home_page.dart';
import '../pages/login_page.dart';
import '../pages/splash_page.dart';

/// Route path constants to avoid magic strings.
abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
}

/// Application router with layered auth guards.
///
/// Guard architecture (from AUTH_RESEARCH + ARCHITECTURE.md):
/// - **Global redirect**: auth check — unauthenticated users go to /login
/// - **Local redirect**: RBAC per role on protected routes
/// - **refreshListenable**: AuthViewModel notifies GoRouter on status changes
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
      // Future: role-guarded routes for social-care, admin, etc.
      // GoRoute(
      //   path: '/social-care',
      //   redirect: (context, state) => _requireRole(
      //     {AuthRole.socialWorker, AuthRole.owner, AuthRole.admin},
      //   ),
      //   ...
      // ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Pagina nao encontrada: ${state.uri}'),
      ),
    ),
  );

  /// Global redirect — runs on every navigation.
  ///
  /// Handles the three main states:
  /// 1. Loading → stay on splash
  /// 2. Unauthenticated → go to login (unless already there)
  /// 3. Authenticated → leave splash/login, go to home
  String? _globalRedirect(BuildContext context, GoRouterState state) {
    final status = authViewModel.status.value;
    final currentPath = state.uri.path;
    final isOnSplash = currentPath == AppRoutes.splash;
    final isOnLogin = currentPath == AppRoutes.login;

    return switch (status) {
      AuthLoading() => isOnSplash ? null : AppRoutes.splash,
      Unauthenticated() => isOnLogin ? null : AppRoutes.login,
      AuthError() => isOnLogin ? null : AppRoutes.login,
      Authenticated() =>
        (isOnSplash || isOnLogin) ? AppRoutes.home : null,
    };
  }

  /// Local redirect — requires authentication for a specific route.
  String? _requireAuth(BuildContext context, GoRouterState state) {
    final status = authViewModel.status.value;
    if (status is! Authenticated) return AppRoutes.login;
    return null;
  }

  /// Local redirect factory — requires one of the given [roles].
  ///
  /// Usage in route definition:
  /// ```dart
  /// GoRoute(
  ///   path: '/admin',
  ///   redirect: (ctx, state) => _requireRole({AuthRole.admin})(ctx, state),
  /// )
  /// ```
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
