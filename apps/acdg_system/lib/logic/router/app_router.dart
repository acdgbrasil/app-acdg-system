import 'package:auth/auth.dart';
import 'package:core/core_offline.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' hide Consumer;
import 'package:social_care/social_care.dart';

import '../di/infrastructure_providers.dart';
import '../../ui/atoms/sync_indicator.dart';
import '../../ui/organisms/sync_detail_panel.dart';
import '../../ui/pages/home_page.dart';
import '../../ui/pages/login_page.dart';
import '../../ui/pages/splash_page.dart';
import '../../ui/view_models/auth_view_model.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const socialCare = '/social-care';
  static const patientRegistration = '/patient-registration';
  static const registrationStep1 = '/patient-registration/reference-person';
  static const registrationStep2 = '/patient-registration/family-composition';
  static const registrationStep3 = '/patient-registration/specificities';
  static const familyComposition = '/family-composition';
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
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
        redirect: _requireAuth,
      ),
      GoRoute(
        path: AppRoutes.socialCare,
        redirect: _requireAuth,
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            if (kIsWeb) {
              return const SocialCareHomePage();
            }
            final syncEngine = ref.watch(syncEngineProvider);
            final queueService = context.read<SyncQueueService>();
            final dbService = context.read<DriftDatabaseService>();
            return SocialCareHomePage(
              syncIndicator: syncEngine != null
                  ? Builder(
                      builder: (ctx) => SyncIndicator(
                        status: syncEngine.status,
                        onTap: () => SyncDetailPanel.show(
                          ctx,
                          queueService: queueService,
                          syncEngine: syncEngine,
                          dbService: dbService,
                        ),
                      ),
                    )
                  : null,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.patientRegistration,
        redirect: _requireAuth,
        builder: (context, state) => const PatientRegistrationPage(),
      ),
      GoRoute(
        path: '${AppRoutes.familyComposition}/:patientId',
        redirect: _requireAuth,
        builder: (context, state) {
          final patientId = state.pathParameters['patientId']!;
          return FamilyCompositionPage(patientId: patientId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Pagina nao encontrada: ${state.uri}')),
    ),
  );

  String? _globalRedirect(BuildContext context, GoRouterState state) {
    final status = authViewModel.status;
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
    final status = authViewModel.status;
    if (status is! Authenticated) return AppRoutes.login;
    return null;
  }

  String? Function(BuildContext, GoRouterState) requireRole(
    Set<AuthRole> roles,
  ) {
    return (context, state) {
      final status = authViewModel.status;
      if (status is! Authenticated) return AppRoutes.login;
      if (!status.user.hasAnyRole(roles)) return AppRoutes.home;
      return null;
    };
  }
}
