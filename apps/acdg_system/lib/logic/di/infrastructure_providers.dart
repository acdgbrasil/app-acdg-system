import 'dart:async';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:social_care/social_care.dart';
import 'package:social_care_desktop/social_care_desktop.dart';

import 'auth_providers.dart';

/// Reactive auth status from the repository's stream.
/// Riverpod providers watch this instead of the ChangeNotifier.
final authStatusProvider = StreamProvider<AuthStatus>((ref) async* {
  final repo = ref.watch(authRepositoryProvider);

  // Yield current state immediately
  yield repo.currentStatus;

  // Then yield subsequent changes
  yield* repo.statusStream;
});

/// Builds or tears down the [SyncEngine] based on authentication state.
/// Returns `null` on web (no offline sync) or when unauthenticated.
final syncEngineProvider = Provider<SyncEngine?>((ref) {
  final deps = ref.watch(appDependencyManagerProvider);
  if (deps.isWeb) return null;

  final asyncStatus = ref.watch(authStatusProvider);

  return switch (asyncStatus) {
    AsyncData(value: Authenticated(:final user)) => _buildSyncEngine(ref, user),
    _ => null,
  };
});

SyncEngine _buildSyncEngine(Ref ref, AuthUser user) {
  final deps = ref.watch(appDependencyManagerProvider);
  final remote = SocialCareBffRemote(
    baseUrl: Env.bffBaseUrl,
    actorId: user.id,
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
}

/// Provides the [SocialCareContract].
///
/// - **Desktop:** [OfflineFirstRepository] when authenticated with a running
///   [SyncEngine], or [LocalSocialCareRepository] as local-only fallback.
/// - **Web:** TODO — wire [HttpSocialCareClient] that calls the BFF's
///   `/api/patients/*`, `/api/lookups/*` endpoints. For now returns a
///   [_WebSocialCarePlaceholder] that throws on every call.
final socialCareContractProvider = Provider<SocialCareContract>((ref) {
  final deps = ref.watch(appDependencyManagerProvider);

  if (deps.isWeb) {
    return _buildWebContract(ref);
  }

  final asyncStatus = ref.watch(authStatusProvider);
  final syncEngine = ref.watch(syncEngineProvider);

  return switch (asyncStatus) {
    AsyncData(value: Authenticated(:final user)) when syncEngine != null =>
      _buildOfflineRepository(ref, user, syncEngine),
    _ => deps.localSocialCareRepository,
  };
});

// ---------------------------------------------------------------------------
// Desktop: offline-first
// ---------------------------------------------------------------------------

OfflineFirstRepository _buildOfflineRepository(
  Ref ref,
  AuthUser user,
  SyncEngine syncEngine,
) {
  final deps = ref.watch(appDependencyManagerProvider);
  final remote = SocialCareBffRemote(
    baseUrl: Env.bffBaseUrl,
    actorId: user.id,
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

// ---------------------------------------------------------------------------
// Web: direct BFF calls via HTTP (no offline layer)
// ---------------------------------------------------------------------------

/// Builds the web [SocialCareContract].
///
/// Uses [HttpSocialCareClient] that calls the BFF's REST endpoints.
/// Cookies are sent automatically on same-origin requests so no
/// Authorization header is needed.
SocialCareContract _buildWebContract(Ref ref) {
  return HttpSocialCareClient(baseUrl: Env.bffBaseUrl);
}
