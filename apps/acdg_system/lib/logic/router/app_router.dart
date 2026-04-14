import 'package:auth/auth.dart';
import 'package:core/core_offline.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' hide Consumer;
import 'package:people_admin/people_admin.dart';
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
  static const intakeInfo = '/intake-info';
  static const housingCondition = '/housing-condition';
  static const healthStatus = '/health-status';
  static const communitySupport = '/community-support';
  static const socioEconomic = '/socio-economic';
  static const educationalStatus = '/educational-status';
  static const workAndIncome = '/work-and-income';
  static const violationReport = '/violation-report';
  static const socialIdentity = '/social-identity';
  static const team = '/team';
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
      GoRoute(
        path: '${AppRoutes.intakeInfo}/:patientId',
        redirect: _requireAuth,
        builder: (context, state) {
          final patientId = state.pathParameters['patientId']!;
          return IntakeInfoPage(patientId: patientId);
        },
      ),
      GoRoute(
        path: '${AppRoutes.housingCondition}/:patientId',
        redirect: _requireAuth,
        builder: (context, state) {
          final patientId = state.pathParameters['patientId']!;
          return HousingConditionPage(patientId: patientId);
        },
      ),
      GoRoute(
        path: '${AppRoutes.healthStatus}/:patientId',
        redirect: _requireAuth,
        builder: (context, state) {
          final patientId = state.pathParameters['patientId']!;
          return HealthStatusPage(patientId: patientId);
        },
      ),
      GoRoute(
        path: '${AppRoutes.communitySupport}/:patientId',
        redirect: _requireAuth,
        builder: (context, state) {
          final patientId = state.pathParameters['patientId']!;
          return CommunitySupportPage(patientId: patientId);
        },
      ),
      // TODO: Hidden — benefitTypeId dropdown missing (see GitHub issue #43)
      // GoRoute(
      //   path: '${AppRoutes.socioEconomic}/:patientId',
      //   redirect: _requireAuth,
      //   builder: (context, state) => SocioEconomicPage(patientId: state.pathParameters['patientId']!),
      // ),
      // TODO: Hidden — under investigation (see GitHub issue)
      // GoRoute(
      //   path: '${AppRoutes.educationalStatus}/:patientId',
      //   redirect: _requireAuth,
      //   builder: (context, state) => EducationalStatusPage(patientId: state.pathParameters['patientId']!),
      // ),
      // TODO: Hidden — dominio_ocupacao lookup missing in backend (see GitHub issue)
      // GoRoute(
      //   path: '${AppRoutes.workAndIncome}/:patientId',
      //   redirect: _requireAuth,
      //   builder: (context, state) => WorkAndIncomePage(patientId: state.pathParameters['patientId']!),
      // ),
      // TODO: Hidden — UX needs full redesign (see GitHub issue)
      // GoRoute(
      //   path: '${AppRoutes.violationReport}/:patientId',
      //   redirect: _requireAuth,
      //   builder: (context, state) => ViolationReportPage(patientId: state.pathParameters['patientId']!),
      // ),
      GoRoute(
        path: '${AppRoutes.socialIdentity}/:patientId',
        redirect: _requireAuth,
        builder: (context, state) => SocialIdentityPage(patientId: state.pathParameters['patientId']!),
      ),
      GoRoute(
        path: AppRoutes.team,
        redirect: requireRole({AuthRole.admin, AuthRole.superAdmin}),
        builder: (context, state) => const PeopleAdminShell(),
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
