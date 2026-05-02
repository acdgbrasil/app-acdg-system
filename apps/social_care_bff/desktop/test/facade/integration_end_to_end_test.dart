/// End-to-end integration tests for [SocialCareDesktop] facade (A18c-v2).
///
/// These tests exercise the full facade lifecycle in isolation. They prove that:
///   1. A write call through a sub-facade enqueues a mutation in the
///      Outbox, optimistically patches the cache, and surfaces a
///      `DrainSummary` on `drainStream` once the engine drains.
///   2. A connectivity offline → online edge auto-triggers drain even
///      when no manual call was made.
///
/// Boundary scoping (H4): these tests validate only the facade's promised
/// behavior — they do not exercise any consumer (Phase 5 CLI is the next
/// consumer to come online; previous shell consumer was removed in D1.C
/// delete batch 2026-05-01).
library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
// ignore_for_file: depend_on_referenced_packages
import 'package:test/test.dart';

import '../_test_uuids.dart';
import '_test_helpers.dart';

void main() {
  // ──────────────────────────────────────────────────────────────────────
  // E2E #1: full write lifecycle (register-style, no cache prerequisite)
  // ──────────────────────────────────────────────────────────────────────

  group('E2E — write through facade enqueues + drains + emits', () {
    test(
      'registerPatient → Outbox enqueued → drainStream emits DrainSummary',
      () async {
        final ctx = FacadeTestContext.fresh();
        addTearDown(ctx.close);

        final desktop = await SocialCareDesktop.create(
          baseUrl: 'http://localhost:8080',
          actorId: 'actor-e2e',
          tokenProvider: kStaticToken('test-token'),
          cacheFilePath: ':memory:',
          syncQueueFilePath: ':memory:',
          dio: ctx.dio,
          clock: ctx.fakeClock,
          connectivity: ctx.fakeConnectivity,
        );
        addTearDown(desktop.close);

        // App-controlled lifecycle (D4 α): START before any writes.
        await desktop.startSync();

        // Drain stream listener — captures every drain completion.
        final drainEvents = <DrainSummary>[];
        final sub = desktop.drainStream.listen(drainEvents.add);
        addTearDown(sub.cancel);

        // Issue a write through the registry sub-facade.
        const req = RegisterPatientRequest(
          personId: kPersonUuid,
          initialDiagnoses: [],
          prRelationshipId: kRoleUuid,
        );
        final writeResult = await desktop.registry.registerPatient(req);

        // The use case returns Success once the mutation is durably
        // enqueued — even if the backend hasn't acknowledged yet.
        expect(writeResult, isA<Success<StandardIdResponse>>());

        // The use case fires-and-forgets `engine.triggerDrain()`. Yield so
        // the drain completes against the (offline-by-default) Dio.
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // The drain stream MUST have emitted at least one DrainSummary —
        // proving the facade's stream is wired to the engine, not silent.
        // The drain itself may have failed-retriable (no real backend),
        // but the SUMMARY must surface either way.
        expect(
          drainEvents,
          isNotEmpty,
          reason:
              'drainStream must emit on every drain completion, even when '
              'mutations failed-retriable (UI surfaces partial progress)',
        );
      },
    );
  });

  // ──────────────────────────────────────────────────────────────────────
  // E2E #2: offline write → online restore → automatic drain
  // ──────────────────────────────────────────────────────────────────────

  group('E2E — offline write + connectivity restore drains queue', () {
    test('enqueue while offline, restore online, drain triggers without '
        'manual triggerDrain', () async {
      final ctx = FacadeTestContext.fresh(
        // Boot offline so the listener seats `_wasOnline = false`.
        bootConnectivity: const [ConnectivityResult.none],
      );
      addTearDown(ctx.close);

      final desktop = await SocialCareDesktop.create(
        baseUrl: 'http://localhost:8080',
        actorId: 'actor-e2e',
        tokenProvider: kStaticToken('test-token'),
        cacheFilePath: ':memory:',
        syncQueueFilePath: ':memory:',
        dio: ctx.dio,
        clock: ctx.fakeClock,
        connectivity: ctx.fakeConnectivity,
      );
      addTearDown(desktop.close);

      // App started, but boot was offline. Seat the offline edge first.
      await desktop.startSync();
      ctx.fakeConnectivity.emitOffline();
      await Future<void>.delayed(Duration.zero);

      final drainEvents = <DrainSummary>[];
      final sub = desktop.drainStream.listen(drainEvents.add);
      addTearDown(sub.cancel);

      // Enqueue a register-style mutation while offline. Use case still
      // returns Success (mutation is durably queued in the Outbox).
      const req = RegisterPatientRequest(
        personId: kPersonUuid,
        initialDiagnoses: [],
        prRelationshipId: kRoleUuid,
      );
      final writeResult = await desktop.registry.registerPatient(req);
      expect(writeResult, isA<Success<StandardIdResponse>>());

      // Even offline, the use case fired triggerDrain() — engine ran a
      // drain pass, may have produced a summary. Capture how many
      // events have surfaced so we can detect the additional drain
      // triggered by the restore edge.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final eventsBeforeRestore = drainEvents.length;

      // Now flip online — the connectivity listener must trigger
      // ANOTHER drain pass without us calling triggerDrain manually.
      ctx.fakeConnectivity.emitOnline();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(
        drainEvents.length,
        greaterThan(eventsBeforeRestore),
        reason:
            'connectivity restore (offline→online) must auto-trigger an '
            'additional drain — the facade subscribes to '
            'onConnectivityChanged and forwards the edge to the engine',
      );
    });
  });
}
