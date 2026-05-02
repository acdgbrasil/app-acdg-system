/// GoF Observer for `connectivity_plus` events that fires-and-forgets
/// `engine.triggerDrain()` on every offline → online edge.
///
/// Pre-D03 this logic lived inline inside `social_care_desktop.dart`'s
/// `create()` factory as a closure capturing a `late SocialCareDesktop
/// desktop` self-reference. D03 extracts the closure into a standalone
/// class that closes over [SyncEngine] directly — eliminating the
/// circular self-reference and making the edge detector unit-testable
/// in isolation.
///
/// Lifecycle:
///   * [watch] subscribes to `connectivity.onConnectivityChanged` ONCE,
///     reads `connectivity.checkConnectivity()` ONCE to seed the
///     edge-detection state, and returns a fully-constructed observer.
///     No drain is triggered at construction time, regardless of the
///     boot state.
///   * The listener compares each emit's online-ness against the cached
///     `_wasOnline` flag. Only the offline → online edge unwraps an
///     `unawaited(engine.triggerDrain())`. Online → offline, online →
///     online, and offline → offline are all silent.
///   * [dispose] cancels the subscription. Idempotent — safe to call
///     twice (a second call is a no-op).
///
/// The drain dispatch is fire-and-forget by design: the listener must
/// return synchronously so connectivity_plus's stream stays responsive.
/// The drain's `Result` is observed via the engine's pump (see
/// `PumpingSyncEngine`) onto the facade's `drainStream`.
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../facade/composition/connectivity_helpers.dart';
import '../engine/sync_engine.dart';

/// Observer that listens to connectivity transitions and triggers
/// [SyncEngine.triggerDrain] on every offline → online edge.
class AutoDrainObserver {
  AutoDrainObserver._({
    required SyncEngine engine,
    required StreamSubscription<List<ConnectivityResult>> subscription,
    required bool initialOnline,
  }) : _engine = engine,
       _subscription = subscription,
       _wasOnline = initialOnline;

  final SyncEngine _engine;
  final StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _wasOnline;
  bool _disposed = false;

  /// Subscribes to [Connectivity.onConnectivityChanged] and triggers
  /// [SyncEngine.triggerDrain] (fire-and-forget) on every offline →
  /// online edge.
  ///
  /// The initial connectivity state is read once via
  /// [Connectivity.checkConnectivity] to seed the edge-detection state.
  /// No drain is fired on construction, even if the boot state is
  /// online — only an actual transition triggers a drain.
  ///
  /// Use [dispose] to cancel the subscription when shutting down.
  static Future<AutoDrainObserver> watch({
    required SyncEngine engine,
    required Connectivity connectivity,
  }) async {
    final initialResults = await connectivity.checkConnectivity();
    final initialOnline = resultsAreOnline(initialResults);

    // `observer` is closure-local to this method. Even though the
    // listener body references `observer._wasOnline`, the reference is
    // safe because:
    //   1. `subscription.listen(...)` returns synchronously without
    //      firing the callback — the stream's first emit is async.
    //   2. By the time the stream emits, `observer = ...` below has
    //      executed and `observer` is a fully-constructed instance.
    // No external code can hold the observer until after this method
    // returns, so the late-binding window is closed before any caller
    // can race with it.
    late AutoDrainObserver observer;
    final subscription = connectivity.onConnectivityChanged.listen((results) {
      final isOnline = resultsAreOnline(results);
      if (isOnline && !observer._wasOnline) {
        // Fire-and-forget — keep the connectivity callback synchronous.
        unawaited(observer._engine.triggerDrain());
      }
      observer._wasOnline = isOnline;
    });

    observer = AutoDrainObserver._(
      engine: engine,
      subscription: subscription,
      initialOnline: initialOnline,
    );
    return observer;
  }

  /// Cancels the connectivity subscription. Idempotent — calling more
  /// than once is safe (subsequent calls are no-ops).
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _subscription.cancel();
  }
}
