import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:social_care/social_care.dart';
import 'package:social_care_desktop/social_care_desktop.dart';

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
      GoRoute(
        path: AppRoutes.socialCare,
        redirect: _requireAuth,
        builder: (context, state) {
          final listUseCase = context.read<ListPatientsUseCase>();
          final getUseCase = context.read<GetPatientUseCase>();
          final syncEngine = context.read<SyncEngine?>();
          final queueService = context.read<SyncQueueService>();
          final dbService = context.read<DriftDatabaseService>();
          return ChangeNotifierProvider(
            create: (_) => HomeViewModel(
              listPatientsUseCase: listUseCase,
              getPatientUseCase: getUseCase,
            ),
            child: SocialCareHomePage(
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
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.patientRegistration,
        redirect: _requireAuth,
        builder: (context, state) {
          final useCase = context.read<RegisterPatientUseCase>();
          final lookupRepo = context.read<LookupRepository>();
          return ChangeNotifierProvider(
            create: (_) => PatientRegistrationViewModel(
              useCase: useCase,
              lookupRepository: lookupRepo,
            ),
            child: const PatientRegistrationPage(),
          );
        },
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
