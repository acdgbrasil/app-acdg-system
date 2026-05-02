/// RED-phase tests for `AutoDrainObserver` (D03 W0.5).
///
/// `AutoDrainObserver` is a GoF Observer that wraps `connectivity_plus`'s
/// stream and triggers `engine.triggerDrain()` on every offline → online
/// edge. Today this logic lives inline as the `late SocialCareDesktop
/// desktop` self-reference closure inside `social_care_desktop.dart`'s
/// `create()` factory (post-D02, lines 328-343). D03 extracts it to a
/// standalone class:
///
/// ```dart
/// class AutoDrainObserver {
///   AutoDrainObserver._({...});
///
///   static Future<AutoDrainObserver> watch({
///     required SyncEngine engine,
///     required Connectivity connectivity,
///   }) async { ... }
///
///   Future<void> dispose();  // cancels subscription; idempotent
/// }
/// ```
///
/// The big architectural win: the callback now closes over the
/// [SyncEngine] argument — no `late SocialCareDesktop desktop`
/// self-reference. The observer is also unit-testable in isolation
/// (this file proves it).
///
/// ── Surface under test ──────────────────────────────────────────────
///   1. `watch()` factory — reads `checkConnectivity()` once for
///      initialOnline, subscribes to `onConnectivityChanged` once,
///      returns a non-null `AutoDrainObserver`.
///   2. Edge detection — drain fires ONLY on offline → online. Initial
///      offline + online emit = drain. Initial online + online re-emit
///      = no drain (no edge). Initial online + offline = no drain. Two
///      back-to-back edges = two drains.
///   3. Mixed-list semantics — `[none, wifi]` is online (any non-none
///      counts); `[none]` alone is offline.
///   4. `dispose()` — cancels the subscription (subsequent emits don't
///      trigger). Idempotent (calling twice is safe).
///
/// ── REGRA #2 pins (semantic contracts asserted here) ────────────────
///
/// Pin #1 (test #4): the boot-time `checkConnectivity()` value SEEDS the
/// internal `_wasOnline` flag. If the legacy code (post-D02 line 326)
/// computed `initialOnline = resultsAreOnline(initialResults)` and the
/// listener compared `isOnline && !desktop._wasOnline`, then booting
/// offline + emitting `[wifi]` MUST trigger a drain (`!false` is true).
/// The new `AutoDrainObserver._({required initialOnline})` constructor
/// takes that seed value explicitly. Test #4 fails if W1 forgets to
/// thread `initialOnline` through (the observer would default to
/// `_wasOnline = true`, swallowing the first edge after boot-offline).
///
/// Pin #2 (test #5): "online → offline" MUST NOT trigger a drain. The
/// edge is intentionally one-way (offline → online). If W1 widens the
/// trigger to "any transition", the panel UI would receive a drain
/// when the connection drops — wasted work + spurious "Sync ran"
/// telemetry. Test #5 pins the one-way contract.
///
/// Pin #3 (test #7): each offline → online edge must trigger ONE drain
/// (not zero, not two). A flapping connection that goes
/// offline→online→offline→online produces TWO drains. Test #7 verifies
/// the edge detection is per-transition (no accumulation, no
/// debouncing — debouncing is a future ticket's problem).
///
/// Pin #4 (test #11): `dispose()` must be idempotent. The facade's
/// `close()` calls `connectivityObserver.dispose()` once, but a defensive
/// double-close (e.g. shutdown + tear-down race) MUST NOT throw a
/// `StateError("Subscription has already been cancelled")`. The legacy
/// code did NOT have this guarantee — connectivitySub.cancel() was only
/// called once and `_closed` gated the call. The new observer takes
/// responsibility for its own subscription lifecycle, so idempotency is
/// part of its contract.
///
/// IMPORTANT (RED phase): the export from `_d03_test_helpers.dart` for
/// `auto_drain_observer.dart` resolves to a file W1 has not created
/// yet. Until then this test file fails to analyze. That is the
/// intended RED signal.
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:test/test.dart';

import '_d03_test_helpers.dart';

void main() {
  group('AutoDrainObserver — watch() factory', () {
    test('returns a non-null AutoDrainObserver instance', () async {
      final fakeConnectivity = FakeConnectivity();
      final engine = FakeSyncEngine();

      final observer = await AutoDrainObserver.watch(
        engine: engine,
        connectivity: fakeConnectivity,
      );

      addTearDown(observer.dispose);
      addTearDown(fakeConnectivity.close);

      expect(observer, isNotNull);
      expect(observer, isA<AutoDrainObserver>());
    });

    test(
      'subscribes to connectivity.onConnectivityChanged exactly once',
      () async {
        final fakeConnectivity = FakeConnectivity();
        final engine = FakeSyncEngine();

        // Pre-condition: no listener has been attached yet.
        expect(fakeConnectivity.streamSubscriptionCount, 0);

        final observer = await AutoDrainObserver.watch(
          engine: engine,
          connectivity: fakeConnectivity,
        );
        addTearDown(observer.dispose);
        addTearDown(fakeConnectivity.close);

        expect(
          fakeConnectivity.streamSubscriptionCount,
          1,
          reason: 'watch() must subscribe to onConnectivityChanged exactly once',
        );
        expect(
          fakeConnectivity.hasListener,
          isTrue,
          reason: 'subscription must be active immediately after watch()',
        );
      },
    );

    test(
      'reads checkConnectivity() to seed initialOnline (no drain on boot)',
      () async {
        // Boot with `[wifi]` (online). The first `emit(wifi)` AFTER boot
        // must NOT trigger a drain because it is not an edge.
        final fakeConnectivity = FakeConnectivity(
          defaultResults: const [ConnectivityResult.wifi],
        );
        final engine = FakeSyncEngine();

        final observer = await AutoDrainObserver.watch(
          engine: engine,
          connectivity: fakeConnectivity,
        );
        addTearDown(observer.dispose);
        addTearDown(fakeConnectivity.close);

        // Sanity: boot should not have triggered any drain.
        expect(
          engine.triggerDrainCount,
          0,
          reason: 'watch() must NOT call triggerDrain at construction time',
        );
      },
    );
  });

  group('AutoDrainObserver — edge detection (offline → online)', () {
    test(
      'boot offline + emit online → triggers triggerDrain exactly ONCE',
      () async {
        final fakeConnectivity = FakeConnectivity(
          defaultResults: const [ConnectivityResult.none],
        );
        final engine = FakeSyncEngine();

        final observer = await AutoDrainObserver.watch(
          engine: engine,
          connectivity: fakeConnectivity,
        );
        addTearDown(observer.dispose);
        addTearDown(fakeConnectivity.close);

        // Sanity: boot did not drain.
        expect(engine.triggerDrainCount, 0);

        fakeConnectivity.emitOnline();
        // Allow the listener to settle.
        await Future<void>.delayed(Duration.zero);

        expect(
          engine.triggerDrainCount,
          1,
          reason: 'offline → online edge MUST trigger exactly one drain',
        );
      },
    );

    test(
      'boot online + emit offline → NO drain (one-way contract pinned)',
      () async {
        // REGRA #2 pin #2 — see file-level docstring.
        final fakeConnectivity = FakeConnectivity(
          defaultResults: const [ConnectivityResult.wifi],
        );
        final engine = FakeSyncEngine();

        final observer = await AutoDrainObserver.watch(
          engine: engine,
          connectivity: fakeConnectivity,
        );
        addTearDown(observer.dispose);
        addTearDown(fakeConnectivity.close);

        fakeConnectivity.emitOffline();
        await Future<void>.delayed(Duration.zero);

        expect(
          engine.triggerDrainCount,
          0,
          reason:
              'online → offline edge MUST NOT trigger drain '
              '(direction is one-way; pinned by REGRA #2)',
        );
      },
    );

    test(
      'boot online + emit online (no edge) → NO drain',
      () async {
        final fakeConnectivity = FakeConnectivity(
          defaultResults: const [ConnectivityResult.wifi],
        );
        final engine = FakeSyncEngine();

        final observer = await AutoDrainObserver.watch(
          engine: engine,
          connectivity: fakeConnectivity,
        );
        addTearDown(observer.dispose);
        addTearDown(fakeConnectivity.close);

        // Same state — no transition.
        fakeConnectivity.emitOnline();
        await Future<void>.delayed(Duration.zero);

        expect(
          engine.triggerDrainCount,
          0,
          reason:
              'online → online (no transition) MUST NOT trigger drain',
        );
      },
    );

    test(
      'flapping (offline → online → offline → online) → 2 drains',
      () async {
        // REGRA #2 pin #3 — each edge counts.
        final fakeConnectivity = FakeConnectivity(
          defaultResults: const [ConnectivityResult.none],
        );
        final engine = FakeSyncEngine();

        final observer = await AutoDrainObserver.watch(
          engine: engine,
          connectivity: fakeConnectivity,
        );
        addTearDown(observer.dispose);
        addTearDown(fakeConnectivity.close);

        // Edge 1: offline → online
        fakeConnectivity.emitOnline();
        await Future<void>.delayed(Duration.zero);

        // Drop back offline.
        fakeConnectivity.emitOffline();
        await Future<void>.delayed(Duration.zero);

        // Edge 2: offline → online again
        fakeConnectivity.emitOnline();
        await Future<void>.delayed(Duration.zero);

        expect(
          engine.triggerDrainCount,
          2,
          reason:
              'each offline → online edge counts; flapping produces N '
              'drains for N edges (no accumulation, no debouncing)',
        );
      },
    );

    test('[none] alone is treated as offline', () async {
      final fakeConnectivity = FakeConnectivity(
        defaultResults: const [ConnectivityResult.none],
      );
      final engine = FakeSyncEngine();

      final observer = await AutoDrainObserver.watch(
        engine: engine,
        connectivity: fakeConnectivity,
      );
      addTearDown(observer.dispose);
      addTearDown(fakeConnectivity.close);

      // Re-emit [none] — boot-state was offline; this is no edge.
      fakeConnectivity.emit(const [ConnectivityResult.none]);
      await Future<void>.delayed(Duration.zero);

      expect(
        engine.triggerDrainCount,
        0,
        reason: '[none] is offline; offline → offline is no edge',
      );

      // Now go online: [none] → [wifi] is the offline → online edge.
      fakeConnectivity.emitOnline();
      await Future<void>.delayed(Duration.zero);

      expect(
        engine.triggerDrainCount,
        1,
        reason: '[none] → [wifi] is the offline → online edge',
      );
    });

    test(
      'mixed list [none, wifi] is treated as online (any non-none counts)',
      () async {
        // Boot offline so the next emit is the edge.
        final fakeConnectivity = FakeConnectivity(
          defaultResults: const [ConnectivityResult.none],
        );
        final engine = FakeSyncEngine();

        final observer = await AutoDrainObserver.watch(
          engine: engine,
          connectivity: fakeConnectivity,
        );
        addTearDown(observer.dispose);
        addTearDown(fakeConnectivity.close);

        fakeConnectivity.emit(
          const [ConnectivityResult.none, ConnectivityResult.wifi],
        );
        await Future<void>.delayed(Duration.zero);

        expect(
          engine.triggerDrainCount,
          1,
          reason:
              'mixed [none, wifi] counts as online — any non-none flips '
              'the bit per resultsAreOnline truth table',
        );
      },
    );
  });

  group('AutoDrainObserver — dispose()', () {
    test(
      'dispose() cancels subscription — subsequent emits do NOT trigger',
      () async {
        final fakeConnectivity = FakeConnectivity(
          defaultResults: const [ConnectivityResult.none],
        );
        final engine = FakeSyncEngine();

        final observer = await AutoDrainObserver.watch(
          engine: engine,
          connectivity: fakeConnectivity,
        );
        addTearDown(fakeConnectivity.close);

        // Trigger one drain to confirm wiring works.
        fakeConnectivity.emitOnline();
        await Future<void>.delayed(Duration.zero);
        expect(engine.triggerDrainCount, 1, reason: 'sanity: wiring is live');

        // Cancel subscription.
        await observer.dispose();
        expect(
          fakeConnectivity.hasListener,
          isFalse,
          reason: 'dispose() must cancel the connectivity subscription',
        );

        // Now go offline → online again. No new drain should fire.
        fakeConnectivity.emitOffline();
        fakeConnectivity.emitOnline();
        await Future<void>.delayed(Duration.zero);

        expect(
          engine.triggerDrainCount,
          1,
          reason:
              'after dispose(), connectivity events MUST NOT reach engine',
        );
      },
    );

    test(
      'dispose() is idempotent (safe to call twice)',
      () async {
        // REGRA #2 pin #4 — see file-level docstring.
        final fakeConnectivity = FakeConnectivity();
        final engine = FakeSyncEngine();

        final observer = await AutoDrainObserver.watch(
          engine: engine,
          connectivity: fakeConnectivity,
        );
        addTearDown(fakeConnectivity.close);

        await observer.dispose();

        // Calling dispose() again must NOT throw a StateError.
        await expectLater(
          observer.dispose(),
          completes,
          reason: 'second dispose() must not throw — subscription handle '
              'should remember its cancelled state',
        );
      },
    );
  });
}
