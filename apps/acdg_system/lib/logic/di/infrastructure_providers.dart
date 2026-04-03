import 'dart:async';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:social_care_desktop/social_care_desktop.dart';

import 'auth_providers.dart';

/// Reactive auth status from the repository's stream.
/// Riverpod providers watch this instead of the ChangeNotifier.
final authStatusProvider = StreamProvider<AuthStatus>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.statusStream;
});

/// Builds or tears down the [SyncEngine] based on authentication state.
/// Automatically stops the engine on dispose (logout or provider invalidation).
final syncEngineProvider = Provider<SyncEngine?>((ref) {
  final asyncStatus = ref.watch(authStatusProvider);
  final status = asyncStatus.value;

  if (status is! Authenticated) return null;

  final deps = ref.watch(appDependencyManagerProvider);
  final remote = SocialCareBffRemote(
    baseUrl: Env.bffBaseUrl,
    actorId: status.user.id,
    tokenProvider: () => deps.authRepository.currentToken?.accessToken,
  );

  final engine = SyncEngine(
    queueService: deps.syncQueueService,
    connectivityService: deps.connectivityService,
    remoteBff: remote,
    localRepo: deps.localSocialCareRepository,
  );
  engine.start();
  ref.onDispose(() => engine.stop());

  return engine;
});

/// Provides the [SocialCareContract] — [OfflineFirstRepository] when
/// authenticated with a running [SyncEngine], or [LocalSocialCareRepository]
/// as local-only fallback.
final socialCareContractProvider = Provider<SocialCareContract>((ref) {
  final asyncStatus = ref.watch(authStatusProvider);
  final status = asyncStatus.value;
  final syncEngine = ref.watch(syncEngineProvider);
  final deps = ref.watch(appDependencyManagerProvider);

  if (status is Authenticated && syncEngine != null) {
    final remote = SocialCareBffRemote(
      baseUrl: Env.bffBaseUrl,
      actorId: status.user.id,
      tokenProvider: () => deps.authRepository.currentToken?.accessToken,
    );

    final repo = OfflineFirstRepository(
      local: deps.localSocialCareRepository,
      remote: remote,
      connectivity: deps.connectivityService,
      syncEngine: syncEngine,
    );

    unawaited(repo.prefetchLookupTables());
    return repo;
  }

  return deps.localSocialCareRepository;
});
