/// Sync Database — MIGRATION-PROTECTED. Holds the Outbox of pending
/// mutations that have NOT yet been acknowledged by the backend.
///
/// CRITICAL: This database lives in a physically SEPARATE .sqlite file
/// from CacheDatabase (`app_sync_queue.sqlite` vs `app_cache.sqlite`).
/// A drop+recreate of the cache is safe (re-fetched from backend);
/// a drop of THIS database = Data Loss of offline mutations.
///
/// Schema changes here MUST be versioned via MigrationStrategy.
/// Increment `schemaVersion` and add migration steps; NEVER drop tables.
library;

import 'package:drift/drift.dart';

import 'sync_database.drift.dart';
import 'tables/outbox_table.dart';

/// Drift database aggregating the SyncQueue tables for the desktop BFF.
///
/// Schema is migration-protected: schema bumps MUST add migration steps
/// (`MigrationStrategy.onUpgrade`); dropping tables would lose offline
/// mutations the user has already produced.
@DriftDatabase(tables: [Outbox])
class SyncDatabase extends $SyncDatabase {
  SyncDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // Future schema bumps add migration steps here. NEVER drop
      // tables — that would lose user mutations that have not been
      // acknowledged by the backend yet.
    },
  );
}
