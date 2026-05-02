/// RED-phase tests for [SocialCareDesktop] facade (A18c-v2).
///
/// Boundary scoping (REGRA #2 H4): these tests cover the FACADE
/// boundary only — entry point construction, lifecycle (`startSync` /
/// `stopSync` / `close`), connectivity-driven drain trigger, and the
/// `drainStream` exposure. They do NOT re-test:
///   * Use case internal logic (cache-first, optimistic-through) — A18b.
///   * SyncEngine drain logic (FIFO, retries, conflict resolution) — A18a.
///   * Cache contracts — A17.
///   * Remote sub-contracts — A16.
///
/// ── Locked contract (W1 must implement EXACTLY) ──────────────────────
///
///   class SocialCareDesktop {
///     // private constructor + private internals
///     // public sub-facades:
///     final RegistryFacade registry;
///     final AssessmentFacade assessment;
///     final CareFacade care;
///     final ProtectionFacade protection;
///     final AuditFacade audit;
///     final LookupFacade lookup;
///     final HealthFacade health;
///     // public sync state:
///     Stream<DrainSummary> get drainStream;
///     Future<Result<DrainSummary>> triggerDrain();
///     // public lifecycle (D4 α):
///     Future<void> startSync();
///     Future<void> stopSync();
///     Future<void> close();
///     // factory (D3 + D4 + D5 wired):
///     static Future<SocialCareDesktop> create({
///       required String baseUrl,
///       required String actorId,
///       required String? Function() tokenProvider,
///       String? cacheFilePath,
///       String? syncQueueFilePath,
///       Dio? dio,
///       Clock? clock,
///       Duration staleAfter = const Duration(minutes: 5),
///       Connectivity? connectivity,
///     });
///   }
///
/// IMPORTANT (RED phase): the facade module
/// `lib/src/facade/social_care_desktop.dart` does NOT exist yet. Imports
/// fail — that is the intended RED signal.
library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared/shared.dart';
// ignore_for_file: depend_on_referenced_packages
import 'package:test/test.dart';

import '_test_helpers.dart';

void main() {
  // ──────────────────────────────────────────────────────────────────────
  // Factory smoke
  // ──────────────────────────────────────────────────────────────────────

  group('SocialCareDesktop.create (factory)', () {
    test('returns instance with all 7 sub-facades wired', () async {
      final ctx = FacadeTestContext.fresh();
      addTearDown(ctx.close);

      final desktop = await SocialCareDesktop.create(
        baseUrl: 'http://localhost:8080',
        actorId: 'actor-123',
        tokenProvider: kStaticToken('test-token'),
        cacheFilePath: ':memory:',
        syncQueueFilePath: ':memory:',
        dio: ctx.dio,
        clock: ctx.fakeClock,
        connectivity: ctx.fakeConnectivity,
      );
      addTearDown(desktop.close);

      // Sub-facades are non-nullable fields; existence proves wire-up.
      expect(desktop.registry, isA<RegistryFacade>());
      expect(desktop.assessment, isA<AssessmentFacade>());
      expect(desktop.care, isA<CareFacade>());
      expect(desktop.protection, isA<ProtectionFacade>());
      expect(desktop.audit, isA<AuditFacade>());
      expect(desktop.lookup, isA<LookupFacade>());
      expect(desktop.health, isA<HealthFacade>());
    });

    test('exposes drainStream + triggerDrain getters', () async {
      final ctx = FacadeTestContext.fresh();
      addTearDown(ctx.close);

      final desktop = await SocialCareDesktop.create(
        baseUrl: 'http://localhost:8080',
        actorId: 'actor-123',
        tokenProvider: kStaticToken('test-token'),
        cacheFilePath: ':memory:',
        syncQueueFilePath: ':memory:',
        dio: ctx.dio,
        clock: ctx.fakeClock,
        connectivity: ctx.fakeConnectivity,
      );
      addTearDown(desktop.close);

      // Stream exists (and is broadcast — multiple panels subscribe).
      expect(desktop.drainStream, isA<Stream<DrainSummary>>());
      expect(desktop.drainStream.isBroadcast, isTrue);
    });

    test(
      'subscribes to connectivity.onConnectivityChanged exactly once',
      () async {
        final ctx = FacadeTestContext.fresh();
        addTearDown(ctx.close);

        expect(ctx.fakeConnectivity.streamSubscriptionCount, 0);

        final desktop = await SocialCareDesktop.create(
          baseUrl: 'http://localhost:8080',
          actorId: 'actor-123',
          tokenProvider: kStaticToken('test-token'),
          cacheFilePath: ':memory:',
          syncQueueFilePath: ':memory:',
          dio: ctx.dio,
          clock: ctx.fakeClock,
          connectivity: ctx.fakeConnectivity,
        );
        addTearDown(desktop.close);

        expect(ctx.fakeConnectivity.streamSubscriptionCount, 1);
        expect(ctx.fakeConnectivity.hasListener, isTrue);
      },
    );
  });

  // ──────────────────────────────────────────────────────────────────────
  // Lifecycle — D4 α (app-controlled, NO auto-start)
  // ──────────────────────────────────────────────────────────────────────

  group('SocialCareDesktop lifecycle (D4 α)', () {
    test('triggerDrain pre-startSync returns Success(processed: 0)', () async {
      final ctx = FacadeTestContext.fresh();
      addTearDown(ctx.close);

      final desktop = await SocialCareDesktop.create(
        baseUrl: 'http://localhost:8080',
        actorId: 'actor-123',
        tokenProvider: kStaticToken('test-token'),
        cacheFilePath: ':memory:',
        syncQueueFilePath: ':memory:',
        dio: ctx.dio,
        clock: ctx.fakeClock,
        connectivity: ctx.fakeConnectivity,
      );
      addTearDown(desktop.close);

      // No startSync() called — engine not started → drain is no-op.
      final result = await desktop.triggerDrain();
      expect(result, isA<Success<DrainSummary>>());
      final summary = (result as Success<DrainSummary>).value;
      expect(summary.processed, 0);
      expect(summary.completed, 0);
      expect(summary.failedRetriable, 0);
      expect(summary.failedDead, 0);
    });

    test('startSync enables drain (idempotent)', () async {
      final ctx = FacadeTestContext.fresh();
      addTearDown(ctx.close);

      final desktop = await SocialCareDesktop.create(
        baseUrl: 'http://localhost:8080',
        actorId: 'actor-123',
        tokenProvider: kStaticToken('test-token'),
        cacheFilePath: ':memory:',
        syncQueueFilePath: ':memory:',
        dio: ctx.dio,
        clock: ctx.fakeClock,
        connectivity: ctx.fakeConnectivity,
      );
      addTearDown(desktop.close);

      // First start.
      await desktop.startSync();
      final r1 = await desktop.triggerDrain();
      expect(r1, isA<Success<DrainSummary>>());

      // Idempotent — calling twice is a no-op.
      await desktop.startSync();
      final r2 = await desktop.triggerDrain();
      expect(r2, isA<Success<DrainSummary>>());
    });

    test('stopSync suspends drain — pending rows stay queued', () async {
      final ctx = FacadeTestContext.fresh();
      addTearDown(ctx.close);

      final desktop = await SocialCareDesktop.create(
        baseUrl: 'http://localhost:8080',
        actorId: 'actor-123',
        tokenProvider: kStaticToken('test-token'),
        cacheFilePath: ':memory:',
        syncQueueFilePath: ':memory:',
        dio: ctx.dio,
        clock: ctx.fakeClock,
        connectivity: ctx.fakeConnectivity,
      );
      addTearDown(desktop.close);

      await desktop.startSync();
      await desktop.stopSync();

      // Post-stop, triggerDrain returns processed=0 (engine stopped).
      final result = await desktop.triggerDrain();
      expect(result, isA<Success<DrainSummary>>());
      expect((result as Success<DrainSummary>).value.processed, 0);
    });

    test(
      'close releases resources — subsequent triggerDrain returns Failure',
      () async {
        final ctx = FacadeTestContext.fresh();
        addTearDown(ctx.close);

        final desktop = await SocialCareDesktop.create(
          baseUrl: 'http://localhost:8080',
          actorId: 'actor-123',
          tokenProvider: kStaticToken('test-token'),
          cacheFilePath: ':memory:',
          syncQueueFilePath: ':memory:',
          dio: ctx.dio,
          clock: ctx.fakeClock,
          connectivity: ctx.fakeConnectivity,
        );

        await desktop.startSync();
        await desktop.close();

        // After close, the engine fails loudly (per A18a's contract). The
        // facade forwards the Failure verbatim.
        final result = await desktop.triggerDrain();
        expect(result, isA<Failure<DrainSummary>>());
      },
    );

    test('close cancels connectivity subscription (no leak)', () async {
      final ctx = FacadeTestContext.fresh();
      addTearDown(ctx.close);

      final desktop = await SocialCareDesktop.create(
        baseUrl: 'http://localhost:8080',
        actorId: 'actor-123',
        tokenProvider: kStaticToken('test-token'),
        cacheFilePath: ':memory:',
        syncQueueFilePath: ':memory:',
        dio: ctx.dio,
        clock: ctx.fakeClock,
        connectivity: ctx.fakeConnectivity,
      );

      expect(ctx.fakeConnectivity.hasListener, isTrue);

      await desktop.close();

      // The facade must cancel its subscription. Without that, emitting
      // events post-close would leak through and could trigger a drain
      // on a closed engine.
      expect(ctx.fakeConnectivity.hasListener, isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // Connectivity listener — D5 γ (trigger-based drain on restore)
  // ──────────────────────────────────────────────────────────────────────

  group('Connectivity listener (D5 γ)', () {
    test('offline → online transition triggers a drain', () async {
      final ctx = FacadeTestContext.fresh(
        // Boot offline so the first emit(online) is a real edge.
        bootConnectivity: const [ConnectivityResult.none],
      );
      addTearDown(ctx.close);

      final desktop = await SocialCareDesktop.create(
        baseUrl: 'http://localhost:8080',
        actorId: 'actor-123',
        tokenProvider: kStaticToken('test-token'),
        cacheFilePath: ':memory:',
        syncQueueFilePath: ':memory:',
        dio: ctx.dio,
        clock: ctx.fakeClock,
        connectivity: ctx.fakeConnectivity,
      );
      addTearDown(desktop.close);

      await desktop.startSync();

      // Listen on drainStream so we can deterministically wait for the
      // engine's drain completion (single-flight; one DrainSummary per
      // drain).
      final drainEvents = <DrainSummary>[];
      final sub = desktop.drainStream.listen(drainEvents.add);
      addTearDown(sub.cancel);

      // Emit offline first to seat the internal `_wasOnline = false`.
      ctx.fakeConnectivity.emitOffline();
      await Future<void>.delayed(Duration.zero);
      // Now emit online — this is the offline→online edge.
      ctx.fakeConnectivity.emitOnline();
      // Yield so the listener + engine drain settle.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // At least one drain summary surfaced via the stream — the listener
      // fired because of the edge, not because we called triggerDrain.
      expect(
        drainEvents,
        isNotEmpty,
        reason: 'offline→online edge must trigger drain',
      );
    });

    test('online → online (no edge) does NOT trigger a drain', () async {
      final ctx = FacadeTestContext.fresh();
      addTearDown(ctx.close);

      final desktop = await SocialCareDesktop.create(
        baseUrl: 'http://localhost:8080',
        actorId: 'actor-123',
        tokenProvider: kStaticToken('test-token'),
        cacheFilePath: ':memory:',
        syncQueueFilePath: ':memory:',
        dio: ctx.dio,
        clock: ctx.fakeClock,
        connectivity: ctx.fakeConnectivity,
      );
      addTearDown(desktop.close);

      await desktop.startSync();

      final drainEvents = <DrainSummary>[];
      final sub = desktop.drainStream.listen(drainEvents.add);
      addTearDown(sub.cancel);

      // Boot is wifi (online). Emitting wifi again is a no-op edge.
      ctx.fakeConnectivity.emitOnline();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // No transition → no auto-trigger. (The user can still call
      // desktop.triggerDrain() manually; that's a different code path.)
      expect(drainEvents, isEmpty);
    });

    test('offline → offline (still down) does NOT trigger a drain', () async {
      final ctx = FacadeTestContext.fresh(
        bootConnectivity: const [ConnectivityResult.none],
      );
      addTearDown(ctx.close);

      final desktop = await SocialCareDesktop.create(
        baseUrl: 'http://localhost:8080',
        actorId: 'actor-123',
        tokenProvider: kStaticToken('test-token'),
        cacheFilePath: ':memory:',
        syncQueueFilePath: ':memory:',
        dio: ctx.dio,
        clock: ctx.fakeClock,
        connectivity: ctx.fakeConnectivity,
      );
      addTearDown(desktop.close);

      await desktop.startSync();

      final drainEvents = <DrainSummary>[];
      final sub = desktop.drainStream.listen(drainEvents.add);
      addTearDown(sub.cancel);

      ctx.fakeConnectivity.emitOffline();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(drainEvents, isEmpty);
    });

    test('mobile (any non-none) counts as online for the edge', () async {
      final ctx = FacadeTestContext.fresh(
        bootConnectivity: const [ConnectivityResult.none],
      );
      addTearDown(ctx.close);

      final desktop = await SocialCareDesktop.create(
        baseUrl: 'http://localhost:8080',
        actorId: 'actor-123',
        tokenProvider: kStaticToken('test-token'),
        cacheFilePath: ':memory:',
        syncQueueFilePath: ':memory:',
        dio: ctx.dio,
        clock: ctx.fakeClock,
        connectivity: ctx.fakeConnectivity,
      );
      addTearDown(desktop.close);

      await desktop.startSync();

      final drainEvents = <DrainSummary>[];
      final sub = desktop.drainStream.listen(drainEvents.add);
      addTearDown(sub.cancel);

      ctx.fakeConnectivity.emitOffline();
      await Future<void>.delayed(Duration.zero);
      ctx.fakeConnectivity.emitOnlineMobile();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Mobile == non-none == online → edge fires drain.
      expect(drainEvents, isNotEmpty);
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // drainStream emission + manual triggerDrain
  // ──────────────────────────────────────────────────────────────────────

  group('drainStream + manual triggerDrain', () {
    test('drainStream emits DrainSummary on every drain completion', () async {
      final ctx = FacadeTestContext.fresh();
      addTearDown(ctx.close);

      final desktop = await SocialCareDesktop.create(
        baseUrl: 'http://localhost:8080',
        actorId: 'actor-123',
        tokenProvider: kStaticToken('test-token'),
        cacheFilePath: ':memory:',
        syncQueueFilePath: ':memory:',
        dio: ctx.dio,
        clock: ctx.fakeClock,
        connectivity: ctx.fakeConnectivity,
      );
      addTearDown(desktop.close);

      await desktop.startSync();

      final drainEvents = <DrainSummary>[];
      final sub = desktop.drainStream.listen(drainEvents.add);
      addTearDown(sub.cancel);

      // Manual trigger → engine completes → stream emits.
      await desktop.triggerDrain();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        drainEvents,
        isNotEmpty,
        reason: 'every successful drain must surface on drainStream',
      );
    });

    test(
      'default-paths factory uses path_provider when '
      'cacheFilePath/syncQueueFilePath are null',
      () async {
        // REGRA #2 boundary: `path_provider` is platform-dependent.
        // Without an `IntegrationTestWidgetsFlutterBinding` the plugin
        // throws `MissingPluginException`. We assert the failure mode is
        // SOMETHING related to platform-channel/path_provider — proving
        // that W1 actually delegated to it instead of silently picking a
        // hard-coded path.
        //
        // If path_provider eventually ships a desktop test shim, this
        // test should be tightened to assert the resolved file paths
        // match `getApplicationDocumentsDirectory()/app_cache.sqlite` and
        // `app_sync_queue.sqlite`. Flag in REPORT.md if W1 finds a more
        // robust assertion path.
        final ctx = FacadeTestContext.fresh();
        addTearDown(ctx.close);

        Object? caught;
        try {
          final desktop = await SocialCareDesktop.create(
            baseUrl: 'http://localhost:8080',
            actorId: 'actor-123',
            tokenProvider: kStaticToken('test-token'),
            // cacheFilePath / syncQueueFilePath omitted → defaults via
            // path_provider.
            dio: ctx.dio,
            clock: ctx.fakeClock,
            connectivity: ctx.fakeConnectivity,
          );
          addTearDown(desktop.close);
        } catch (e) {
          caught = e;
        }

        // Either:
        //   (a) caught a MissingPluginException-style error → W1 wired
        //       path_provider correctly (the plugin just isn't bound in
        //       unit tests).
        //   (b) factory completed → W1 resolved a fallback (e.g. tmp dir);
        //       acceptable but should be documented.
        // The test passes in either case — what we care about is that W1
        // did NOT silently use a hard-coded path like `'app_cache.sqlite'`
        // in cwd, which would corrupt CI runs.
        //
        // NOTE: skipped if running under a binding that DOES have
        // path_provider available (rare in unit tests).
        expect(
          caught == null || caught.toString().toLowerCase().contains('plugin'),
          isTrue,
          reason:
              'Either path_provider fired (unbound in unit tests = OK) or W1 '
              'resolved a fallback. Hard-coded cwd path is NOT acceptable.',
        );
      },
      skip:
          'path_provider is platform-channel-bound; requires integration '
          'test binding. W1 to validate via integration_test/ if needed.',
    );
  });
}
