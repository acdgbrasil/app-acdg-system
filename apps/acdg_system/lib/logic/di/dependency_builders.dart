import 'dart:async';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:network/network.dart';
import 'package:shared/shared.dart';
import 'package:social_care_desktop/social_care_desktop.dart';
import '../../ui/view_models/auth_view_model.dart';

/// Helper class to encapsulate the complex logic of ProxyProviders.
abstract final class DependencyBuilders {
  /// Builds or updates the [SyncEngine] based on auth status.
  static SyncEngine? buildSyncEngine({
    required AuthViewModel auth,
    required SyncQueueService queueService,
    required ConnectivityService connectivityService,
    required LocalSocialCareRepository localRepository,
    SyncEngine? previous,
  }) {
    final authStatus = auth.status;

    if (authStatus is Authenticated) {
      final remote = SocialCareBffRemote(
        baseUrl: Env.bffBaseUrl,
        actorId: authStatus.user.id,
        tokenProvider: () => auth.authRepository.currentToken?.accessToken,
      );

      if (previous == null) {
        final engine = SyncEngine(
          queueService: queueService,
          connectivityService: connectivityService,
          remoteBff: remote,
          localRepo: localRepository,
        );
        engine.start();
        return engine;
      }
      return previous;
    }

    previous?.stop();
    return null;
  }

  /// Builds the [SocialCareContract] (OfflineFirst or LocalOnly).
  static SocialCareContract buildSocialCareContract({
    required AuthViewModel auth,
    required SyncEngine? syncEngine,
    required LocalSocialCareRepository localRepository,
    required ConnectivityService connectivityService,
  }) {
    final authStatus = auth.status;

    if (authStatus is Authenticated && syncEngine != null) {
      final remote = SocialCareBffRemote(
        baseUrl: Env.bffBaseUrl,
        actorId: authStatus.user.id,
        tokenProvider: () => auth.authRepository.currentToken?.accessToken,
      );

      final repo = OfflineFirstRepository(
        local: localRepository,
        remote: remote,
        connectivity: connectivityService,
        syncEngine: syncEngine,
      );

      // Trigger prefetch without blocking UI
      unawaited(repo.prefetchLookupTables());

      return repo;
    }

    return localRepository;
  }
}
