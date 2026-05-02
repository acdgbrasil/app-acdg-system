/// Cache database — DROPPABLE on schema change (desktop not in production).
/// Holds Read Models (DTO projections) of patients, care, protection, audit,
/// and lookup data. NEVER store the SyncQueue (Outbox) here — A18-v2 creates
/// a physically separate SyncDatabase (`app_sync_queue.sqlite`) with
/// migration-protected schema. Mixing the two would cause Data Loss on
/// cache drops.
library;

import 'package:drift/drift.dart';

import 'cache_database.drift.dart';
import 'tables/audit_table.dart';
import 'tables/care_table.dart';
import 'tables/lookup_tables.dart';
import 'tables/patients_table.dart';
import 'tables/protection_tables.dart';

/// Drift database aggregating every cache table for the desktop BFF.
///
/// Schema is rebuilt from scratch on version bumps (no upgrade
/// migrations) — desktop is not in production, dropping the cache is
/// acceptable. The SyncQueue lives in a SEPARATE database (A18-v2).
@DriftDatabase(
  tables: [
    Patients,
    PatientSummaries,
    Appointments,
    Referrals,
    ViolationReports,
    PlacementHistories,
    AuditEntries,
    LookupItems,
    LookupRequests,
  ],
)
class CacheDatabase extends $CacheDatabase {
  CacheDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();

      // ── FTS5: patient_summaries ──────────────────────────────────────
      // External-content FTS5 — `patient_summaries` is the source-of-truth
      // table; the FTS5 index stores a single concatenated `terms`
      // column built from firstName + lastName + primaryDiagnosis.
      await customStatement('''
        CREATE VIRTUAL TABLE patient_summaries_fts USING fts5(
          terms,
          content='patient_summaries',
          content_rowid='rowid'
        );
      ''');

      await customStatement('''
        CREATE TRIGGER patient_summaries_ai AFTER INSERT ON patient_summaries
        BEGIN
          INSERT INTO patient_summaries_fts(rowid, terms)
          VALUES (
            new.rowid,
            lower(coalesce(new.first_name, '') || ' ' ||
                  coalesce(new.last_name, '') || ' ' ||
                  coalesce(new.primary_diagnosis, ''))
          );
        END;
      ''');

      await customStatement('''
        CREATE TRIGGER patient_summaries_ad AFTER DELETE ON patient_summaries
        BEGIN
          INSERT INTO patient_summaries_fts(patient_summaries_fts, rowid, terms)
          VALUES ('delete', old.rowid,
            lower(coalesce(old.first_name, '') || ' ' ||
                  coalesce(old.last_name, '') || ' ' ||
                  coalesce(old.primary_diagnosis, '')));
        END;
      ''');

      await customStatement('''
        CREATE TRIGGER patient_summaries_au AFTER UPDATE ON patient_summaries
        BEGIN
          INSERT INTO patient_summaries_fts(patient_summaries_fts, rowid, terms)
          VALUES ('delete', old.rowid,
            lower(coalesce(old.first_name, '') || ' ' ||
                  coalesce(old.last_name, '') || ' ' ||
                  coalesce(old.primary_diagnosis, '')));
          INSERT INTO patient_summaries_fts(rowid, terms)
          VALUES (
            new.rowid,
            lower(coalesce(new.first_name, '') || ' ' ||
                  coalesce(new.last_name, '') || ' ' ||
                  coalesce(new.primary_diagnosis, ''))
          );
        END;
      ''');

      // ── FTS5: lookup_items.tableName (typeahead over distinct names) ──
      // External-content FTS5 indexes the per-row `table_name`. The
      // searchTables impl reads DISTINCT to dedupe.
      await customStatement('''
        CREATE VIRTUAL TABLE lookup_tables_fts USING fts5(
          terms,
          content='lookup_items',
          content_rowid='rowid'
        );
      ''');

      await customStatement('''
        CREATE TRIGGER lookup_items_ai AFTER INSERT ON lookup_items
        BEGIN
          INSERT INTO lookup_tables_fts(rowid, terms)
          VALUES (new.rowid, lower(new.lookup_name));
        END;
      ''');

      await customStatement('''
        CREATE TRIGGER lookup_items_ad AFTER DELETE ON lookup_items
        BEGIN
          INSERT INTO lookup_tables_fts(lookup_tables_fts, rowid, terms)
          VALUES ('delete', old.rowid, lower(old.lookup_name));
        END;
      ''');

      await customStatement('''
        CREATE TRIGGER lookup_items_au AFTER UPDATE ON lookup_items
        BEGIN
          INSERT INTO lookup_tables_fts(lookup_tables_fts, rowid, terms)
          VALUES ('delete', old.rowid, lower(old.lookup_name));
          INSERT INTO lookup_tables_fts(rowid, terms)
          VALUES (new.rowid, lower(new.lookup_name));
        END;
      ''');
    },
  );
}
