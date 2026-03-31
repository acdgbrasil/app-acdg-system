import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:network/network.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';
import 'package:social_care/social_care.dart';
import 'package:social_care_desktop/social_care_desktop.dart';

import 'dependency_builders.dart';
import 'dependency_manager.dart';
import '../../ui/view_models/auth_view_model.dart';

/// Injects all global dependencies into the widget tree.
class AppProviders extends StatelessWidget {
  const AppProviders({super.key, required this.deps, required this.child});

  final AppDependencyManager deps;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 0. The Manager itself (for cleaner access to router/etc)
        Provider<AppDependencyManager>.value(value: deps),

        // 1. Core State & Infrastructure
        ChangeNotifierProvider<AuthViewModel>.value(value: deps.authViewModel),
        ListenableProvider<AuthRepository>.value(value: deps.authRepository),
        Provider<IsarService>.value(value: deps.isarService),
        Provider<ConnectivityService>.value(value: deps.connectivityService),
        Provider<SyncQueueService>.value(value: deps.syncQueueService),
        Provider<LocalSocialCareRepository>.value(
          value: deps.localSocialCareRepository,
        ),

        // 2. Auth Use Cases (Shared)
        Provider.value(value: deps.loginUseCase),
        Provider.value(value: deps.logoutUseCase),
        Provider.value(value: deps.restoreSessionUseCase),

        // 3. Reactive Infrastructure (BFF & Sync)
        ProxyProvider<AuthViewModel, SyncEngine?>(
          update: (context, auth, previous) =>
              DependencyBuilders.buildSyncEngine(
                auth: auth,
                queueService: deps.syncQueueService,
                connectivityService: deps.connectivityService,
                localRepository: deps.localSocialCareRepository,
                previous: previous,
              ),
          dispose: (_, engine) => engine?.stop(),
        ),

        ProxyProvider2<AuthViewModel, SyncEngine?, SocialCareContract>(
          update: (context, auth, syncEngine, _) =>
              DependencyBuilders.buildSocialCareContract(
                auth: auth,
                syncEngine: syncEngine,
                localRepository: deps.localSocialCareRepository,
                connectivityService: deps.connectivityService,
              ),
        ),

        // 4. Social Care Module (Repositories & UseCases)
        ProxyProvider<SocialCareContract, PatientService>(
          update: (_, contract, _) => PatientService(bff: contract),
        ),
        ProxyProvider2<SocialCareContract, PatientService, PatientRepository>(
          update: (_, contract, service, _) => BffPatientRepository(
            bff: contract,
            patientService: service,
          ),
        ),
        ProxyProvider<SocialCareContract, LookupRepository>(
          update: (_, contract, _) => BffLookupRepository(bff: contract),
        ),
        ProxyProvider<PatientRepository, RegisterPatientUseCase>(
          update: (_, repo, _) =>
              RegisterPatientUseCase(patientRepository: repo),
        ),
        ProxyProvider<PatientRepository, GetPatientUseCase>(
          update: (_, repo, _) => GetPatientUseCase(patientRepository: repo),
        ),
        ProxyProvider<PatientRepository, ListPatientsUseCase>(
          update: (_, repo, _) =>
              ListPatientsUseCase(patientRepository: repo),
        ),
      ],
      child: child,
    );
  }
}
