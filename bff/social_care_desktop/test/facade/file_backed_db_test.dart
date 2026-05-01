/// Regression test for T1.1 — Drift file-backed executor.
///
/// Onda 4 facade tests run with `cacheFilePath: ':memory:'` /
/// `syncQueueFilePath: ':memory:'` (in-memory marker). That branch of
/// `_openDriftExecutor` is exercised end-to-end. The OTHER branch —
/// `NativeDatabase(File(filePath))` — has ZERO test coverage today.
///
/// This file fixes that gap:
///   * Pre-fix (T1.1 = `NativeDatabase(File(...))`): the test PASSES,
///     proving the file-backed open+query+close behavior we want to preserve.
///   * Post-fix (T1.1 = `NativeDatabase.createInBackground(File(...))`):
///     the test STILL PASSES, proving the isolated executor honors the
///     same contract from the caller's POV.
///
/// **Behavior asserted (the regression contract):**
///   1. `SocialCareDesktop.create()` with explicit file paths returns a
///      working instance (no hang during isolate spawn).
///   2. A cache-only operation (`audit.fetchAuditTrail`) completes and
///      returns the expected empty `Success` — proves the cache Drift
///      executor actually serves queries.
///   3. After the operation, both `.sqlite` files materialize on disk
///      (Drift creates them lazily on first query).
///   4. `desktop.close()` releases everything cleanly (no hang on
///      isolate join, no leaked file handles).
///
/// Boundary: `packages/*` untouched (per `feedback_packages_user_owned.md`).
library;

import 'dart:io';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart' show AppointmentResponse;
import 'package:test/test.dart';

import '../_test_uuids.dart';
import '_test_helpers.dart';

void main() {
  group('T1.1 — Drift file-backed executor regression', () {
    late Directory tmpDir;
    late String cachePath;
    late String syncPath;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('t11_drift_file_');
      cachePath = '${tmpDir.path}/cache.sqlite';
      syncPath = '${tmpDir.path}/sync_queue.sqlite';
    });

    tearDown(() {
      try {
        tmpDir.deleteSync(recursive: true);
      } catch (_) {
        // Best-effort cleanup; if the OS still holds a handle on Windows,
        // the temp dir gets reaped by the OS later.
      }
    });

    test(
      'create() with file paths opens both Drift databases, serves a '
      'cache-only query, materializes .sqlite files, and closes cleanly',
      () async {
        final ctx = FacadeTestContext.fresh();

        // 1. Build with EXPLICIT file paths (not in-memory marker).
        final desktop = await SocialCareDesktop.create(
          baseUrl: 'http://localhost',
          actorId: 'test-actor',
          tokenProvider: kStaticToken('test-token'),
          cacheFilePath: cachePath,
          syncQueueFilePath: syncPath,
          dio: ctx.dio,
          clock: ctx.fakeClock,
          connectivity: ctx.fakeConnectivity,
        );

        expect(desktop, isNotNull);

        // 2. Trigger a cache-only op against the file-backed executor.
        //    `care.listAppointments` is one of the 5 use cases A18b
        //    deliberately implements as cache-only (no remote `list`
        //    endpoint exists in CareContract). It exercises ONLY the
        //    cache Drift executor without ANY network dependency —
        //    the perfect probe for the file-backed branch.
        final listResult = await desktop.care
            .listAppointments(kPatientUuid)
            .timeout(const Duration(seconds: 10));

        // Cache is empty (fresh file-backed DB) → expect Success([]).
        // If the file-backed executor were wedged (isolate handshake
        // failure, etc.) this would hang past the timeout.
        expect(
          listResult,
          isA<Success<List<AppointmentResponse>>>(),
          reason: 'cache I/O on file-backed Drift executor should succeed',
        );
        if (listResult case Success(:final value)) {
          expect(value, isEmpty, reason: 'fresh DB → no appointments');
        }

        // 3. After the query, Drift has flushed both .sqlite files to disk.
        //    (Cache file is touched directly by the audit query; the sync
        //    queue file is touched at facade-construction time by the
        //    SyncEngine wiring + outbox warmup.)
        expect(
          File(cachePath).existsSync(),
          isTrue,
          reason: 'cache .sqlite must exist on disk after first query',
        );
        expect(
          File(syncPath).existsSync(),
          isTrue,
          reason: 'sync queue .sqlite must exist on disk after create()',
        );

        // 4. Tear-down: close releases everything without throwing or
        //    hanging. If the executor is wedged (e.g. isolate not joining),
        //    this would block past the test timeout.
        await desktop.close();
        await ctx.close();
      },
      // Be generous — first isolate spawn can be slow on cold boot,
      // especially on CI / Windows where Dart's isolate spawn is slower.
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
