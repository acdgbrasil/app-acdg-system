# A17-v2 W0 — RED Tests (test-writer)

**Status:** RED complete (2026-04-30). Hand-off to flutter-bff-implementer (W1).

## Summary

5 cache contracts (Aggregate-Root-aligned) for `bff/social_care_desktop/lib/src/cache/contracts/`. W0 produced **81 RED tests** across 5 files plus shared in-memory DB helper. Analyzer reports 18 errors of expected RED-signal kind (`undefined_class`, `undefined_function`, `non_type_as_type_argument`) plus dead-code warnings downstream.

## Files created

| File | Tests | LoC |
|---|---:|---:|
| `bff/social_care_desktop/test/cache/_test_db.dart` | — | 43 |
| `test/cache/patients_cache_test.dart` | 21 | 481 |
| `test/cache/care_cache_test.dart` | 12 | 248 |
| `test/cache/protection_cache_test.dart` | 16 | 391 |
| `test/cache/audit_cache_test.dart` | 13 | 296 |
| `test/cache/lookup_cache_test.dart` | 19 | 416 |
| **Total** | **81** | **1 875** |

## Cache contract surfaces (locked for W1)

Every method returns `Future<Result<T>>`. Missing rows = `Success(null)`, **never** `Failure`. DB failures = `Failure(error)`. Constructor convention: `class DriftXCache implements XCache { DriftXCache(this._db); final CacheDatabase _db; }`.

### `PatientsCache`
```dart
abstract interface class PatientsCache {
  Future<Result<PatientResponse?>>             findById(String patientId);
  Future<Result<PatientResponse?>>             findByPersonId(String personId);
  Future<Result<List<PatientSummaryResponse>>> listSummaries({String? status, String? cursor, int? limit});
  Future<Result<List<PatientSummaryResponse>>> searchSummaries(String term);   // FTS5
  Future<Result<void>>                         upsertPatient(PatientResponse dto, {required int version});
  Future<Result<void>>                         upsertSummary(PatientSummaryResponse dto, {required int version});
  Future<Result<void>>                         deletePatient(String patientId);
  Future<Result<void>>                         deleteSummary(String patientId);
  Future<Result<void>>                         clear();
}
```

### `CareCache`
```dart
abstract interface class CareCache {
  Future<Result<AppointmentResponse?>>      findById(String patientId, String appointmentId);
  Future<Result<List<AppointmentResponse>>> listByPatient(String patientId, {int? limit});
  Future<Result<void>>                      upsert(String patientId, AppointmentResponse dto, {required int version});
  Future<Result<void>>                      delete(String patientId, String appointmentId);
  Future<Result<void>>                      clear();
}
```

### `ProtectionCache`
3 sub-aggregates: Referrals, ViolationReports, PlacementHistories. 12 methods total, similar shape per sub-aggregate (`find*ById`, `list*`, `upsert*`, `delete*`).

### `AuditCache`
```dart
abstract interface class AuditCache {
  Future<Result<AuditTrailEntryResponse?>>      findById(String entryId);
  Future<Result<List<AuditTrailEntryResponse>>> listByPatient(String patientId,
      {String? eventType, int? limit, int? offset});
  Future<Result<void>>                          upsert(String patientId, AuditTrailEntryResponse dto, {required int version});
  Future<Result<void>>                          delete(String entryId);
  Future<Result<void>>                          clear();
}
```

### `LookupCache`
12 methods: lookup items (by tableName) + lookup tableName search via FTS5 + lookup requests (read/upsert/delete with status/tableName filters).

## Drift schema (assumed minimum shape)

| Table | Indexed columns | FTS5? | Notes |
|---|---|---|---|
| `patients` | id (PK), personId, status | — | One-row-per-patient, full PatientResponse JSON in payload |
| `patient_summaries` | id (PK), status | **YES** (`patient_summaries_fts`) | name + diagnosis searchable |
| `appointments` | (patientId, id) (PK), patientId | — | Per-patient list |
| `referrals` | (patientId, id) (PK), patientId | — | |
| `violation_reports` | (patientId, id) (PK), patientId | — | |
| `placement_histories` | patientId (PK) | — | One-per-patient |
| `audit_entries` | id (PK), patientId, eventType | — | Multi-filter support |
| `lookup_items` | (tableName, id) (PK), tableName | **YES** (`lookup_tables_fts`) | tableName searchable |
| `lookup_requests` | id (PK), tableName, status | — | |

Every table has: `payload` TEXT (full DTO JSON), `cachedAt` DATETIME, `version` INT.

## REGRA #2 ambiguities (pre-resolved in tests)

1. **`version` is caller-controlled, NOT auto-incremented.** Tests assert `cache.upsertPatient(dto, version: 7)` round-trips 7. A18-v2 owns increment via optimistic-locking writes. If W1 wants different semantics, MUST flag — no silent change.

2. **`cachedAt` provenance:** tests assert it is set by `upsert*` but do NOT assert exact equality (no `Clock` injection at this layer). Implementer can use `DateTime.now()`. Clock injection is A18-v2 concern.

3. **`AuditTrailEntryResponse.payload` deep equality:** payload is `Map<String, dynamic>?`. Equatable does not recurse through dynamic. Tests assert field-by-field (`value.payload?['reason']`), never `expect(dtoA, equals(dtoB))` on full DTO.

## Hand-off to W1

**Pubspec changes** (`bff/social_care_desktop/pubspec.yaml`):
```yaml
dependencies:
  drift: ^2.31.0                # already present
  sqlite3_flutter_libs: ^0.5.0  # production: SQLite with FTS5 enabled
dev_dependencies:
  drift_dev: ^2.31.0
  build_runner: ^2.4.0
  sqlite3: ^2.4.0               # tests: in-process SQLite
```

**Codegen:** `dart run build_runner build --delete-conflicting-outputs` after declaring `@DriftDatabase(tables: [...])`.

**FTS5 + triggers:** No first-class Drift API. Use `customStatement` in `MigrationStrategy.onCreate` for raw `CREATE VIRTUAL TABLE ... USING fts5(...)` + `CREATE TRIGGER ... AFTER INSERT/UPDATE/DELETE`.

**Header docstring (non-negotiable, STATE.md acceptance criterion)** — `lib/src/cache/_shared/cache_database.dart` MUST start with the SyncQueue separation warning (see STATE.md).

**Definition of Done for W1:**
1. `_shared/cache_database.dart` (with header) + 5 table files + generated `.g.dart`.
2. 5 contract files in `contracts/` (`abstract interface class`).
3. 5 DAO files in `daos/` with raw SQL + FTS5 search.
4. 5 impl files in `impls/` — each `implements XCache`, thin wrapper over DAO. **No god-class.**
5. `MigrationStrategy.onCreate` creates main tables + FTS5 + triggers.
6. `dart analyze bff/social_care_desktop/` zero errors zero warnings (info OK for codegen).
7. `flutter test bff/social_care_desktop/test/cache/` all 81 GREEN.
8. `lib/social_care_desktop.dart` exports the 5 contracts (impls wired by A18 facade).

**Out of scope for W1:** SyncQueue/Outbox, TTL, use cases, facade, ADR-005 update.

Per REGRA #2, if W1 finds the test surface inadequate, raise issue against this hand-off before touching test files — no silent test rewrites.
