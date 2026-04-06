import 'package:core/core_offline.dart';
import 'package:flutter/material.dart';
import 'package:network/network.dart';
import 'package:provider/provider.dart';
import 'package:social_care_desktop/social_care_desktop.dart';

import 'dependency_manager.dart';

/// Injects infrastructure dependencies into the widget tree.
///
/// Auth, SyncEngine, SocialCareContract, and Social Care module providers
/// have been migrated to Riverpod (see auth_providers.dart,
/// infrastructure_providers.dart, social_care_providers.dart).
///
/// On **web** the offline-only providers (Drift, SyncQueue, LocalRepo,
/// Connectivity) are omitted — the BFF handles persistence server-side.
class AppProviders extends StatelessWidget {
  const AppProviders({super.key, required this.deps, required this.child});

  final AppDependencyManager deps;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDependencyManager>.value(value: deps),
        if (!deps.isWeb) ...[
          Provider<DriftDatabaseService>.value(value: deps.dbService),
          Provider<ConnectivityService>.value(value: deps.connectivityService),
          Provider<SyncQueueService>.value(value: deps.syncQueueService),
          Provider<LocalSocialCareRepository>.value(
            value: deps.localSocialCareRepository,
          ),
        ],
      ],
      child: child,
    );
  }
}
