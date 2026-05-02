/// Helper to spin up an in-memory `SyncDatabase` per sync test (A18a-v2).
///
/// Mirrors `test/cache/_test_db.dart` (the cache equivalent), but targets
/// the **physically separate** SyncDatabase that A18a creates.
///
/// CRITICAL — Why a SECOND helper exists alongside the cache one:
///   `SyncDatabase` lives in a SEPARATE `.sqlite` file from `CacheDatabase`
///   (`app_sync_queue.sqlite` vs `app_cache.sqlite`). Cache is droppable
///   on schema bump; SyncQueue is migration-protected. Keeping the test
///   helpers separate enforces that physical separation in tests too — a
///   single helper would temptingly let an Outbox table land on the wrong
///   database.
///
/// IMPORTANT (RED phase): the `SyncDatabase` class does NOT exist yet.
/// W1 (flutter-bff-implementer) is expected to create it at
/// `lib/src/sync/_shared/sync_database.dart` with a `@DriftDatabase`
/// annotation, plus run `dart run build_runner build` to generate
/// `sync_database.drift.dart`. Until then, the `import` below will fail —
/// that is the intended RED signal.
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/sync/_shared/sync_database.dart';

/// Returns a fresh in-memory [SyncDatabase].
///
/// [logStatements] forwards to [NativeDatabase] for debugging — leave at
/// `false` in CI; flip to `true` locally to dump every SQL statement.
SyncDatabase newInMemorySyncDatabase({bool logStatements = false}) {
  return SyncDatabase(NativeDatabase.memory(logStatements: logStatements));
}

/// Convenience: closes the underlying [QueryExecutor] without bubbling
/// up exceptions if the DB was already closed (idempotent for tearDown).
Future<void> safeCloseSync(SyncDatabase db) async {
  try {
    await db.close();
  } catch (_) {
    // already closed — fine.
  }
}
