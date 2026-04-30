# Ticket State: A17-v2-desktop-cache (BREAK CHANGE)

phase: tdd-red (test-writer dispatched 2026-04-30)
status: re-baselined as **A17-v2** — full rebuild authorized 2026-04-29 (in continuity with A16-v2)

## Re-baseline summary

A17 original ("storage/ alinhado com payloads novos") foi re-escopado em conjunto com A16-v2. O `lib/src/storage/` legado foi **deletado em A16-v2 W1** (option a — clean break). A17-v2 **constrói a camada `cache/` do zero** mirroring web pattern minus HTTP, com Drift como engine.

**User authorization (2026-04-29):** "Vamos marcar o DESKTOP como BREAK CHANGING e fazer igual ao WEB."

## Locked architectural decisions (2026-04-30 alignment with Architect)

### 1. Cache contract surface: CRUD per entity (NOT mirror of sub-contracts)

Cache é persistência pura — separada da intenção de negócio (CQRS-aligned, Repository Pattern). Não tem `dischargePatient`; tem `upsertPatient(PatientResponse)`. Mutações de domínio passam pelo SyncQueue (A18-v2), não tocam cache diretamente.

**Surface canônica:** `find*(id)`, `findBy*(...)`, `list*(filters)`, `search*(term)`, `upsert*(dto)`, `delete*(id)`, `clear*()`.

### 2. 5 cache contracts (Aggregate Roots), não 7

Sub-contracts são 7 mas Assessment é embedded em Patient (as 7 fichas mutam `PatientResponse`, não são aggregates separados). Health não cacheia (real-time only). Fronteira correta de bounded context para a camada de cache:

| Cache Contract | Aggregate / Entidades | DAO |
|---|---|---|
| `PatientsCache` | Patient (com fichas Assessment embedded) + PatientSummary | `PatientDao` |
| `CareCache` | Appointments por patient | `CareDao` |
| `ProtectionCache` | Referrals + ViolationReports + PlacementHistories por patient | `ProtectionDao` |
| `AuditCache` | AuditTrailEntry com filtros (eventType, limit, offset) | `AuditDao` |
| `LookupCache` | Lookup tables (keyed by tableName) + LookupRequests | `LookupDao` |

Cache contracts vivem em `bff/social_care_desktop/lib/src/cache/contracts/` — desktop-only (não em `bff/shared/`; web não tem cache layer).

### 3. Drift schema: denormalized JSON-blob + FTS5 + indexed B-Tree columns

**Schema strategy:**
- Cada tabela tem `payload` (TEXT) com o DTO completo serializado em JSON.
- Indexed B-Tree columns para lookups O(log N): `id` (PK), `personId`, `status`, etc.
- **FTS5 virtual table separada por contexto buscável** — substitui `searchTerms LIKE '%...%'` (que é Full Table Scan / O(N), violação de regra de ouro).
- Drift triggers (`AFTER INSERT/UPDATE/DELETE ON <table>`) mantêm FTS5 sincronizada.

**Exemplo (Patients):**
```dart
class Patients extends Table {
  TextColumn get id => text()();              // PK, UUID v4
  TextColumn get personId => text()();        // INDEXED (lookup by personId)
  TextColumn get status => text()();          // INDEXED (active/discharged/...)
  TextColumn get payload => text()();         // FULL PatientResponse JSON
  DateTimeColumn get cachedAt => dateTime()();// last-seen-at (for refresh policy)
  IntColumn get version => integer()();       // optimistic locking (A18 uses)
  @override Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'patients_personId_idx', columns: {#personId})
@TableIndex(name: 'patients_status_idx', columns: {#status})
class Patients extends Table { ... }

// Em raw SQL via Drift migration (onCreate):
//   CREATE VIRTUAL TABLE patients_fts USING fts5(terms, content='patients', content_rowid='rowid');
//   CREATE TRIGGER patients_ai AFTER INSERT ON patients BEGIN
//     INSERT INTO patients_fts(rowid, terms) VALUES (new.rowid, ...); END;
// (similar AFTER UPDATE / AFTER DELETE)
```

Search vira: `WHERE rowid IN (SELECT rowid FROM patients_fts WHERE patients_fts MATCH 'term*')`.

### 4. SyncQueue separation (CRITICAL — Outbox protection)

**A17-v2 NÃO cria SyncQueue table.** A18-v2 vai criar **um segundo `@DriftDatabase` em arquivo físico separado** (`app_sync_queue.sqlite`). Razão (Architect's directive 2026-04-30):

> "Se o cache quebrar, recria. Se a fila quebrar, você tem perda de dados (Data Loss). A SyncQueue deve ter migração estruturada e ser indestrutível, ou deve morrer em um arquivo de banco de dados .sqlite fisicamente separado do arquivo de Cache."

**A17-v2 deliverable:** apenas `CacheDatabase` (em `app_cache.sqlite`), droppable via `dropAll(Migrator)`.
**A18-v2 deliverable:** `SyncDatabase` (em `app_sync_queue.sqlite`), com migration strategy versionada e proteção contra drop.

**Header docstring obrigatório em `cache_database.dart`:**
```dart
/// Cache database — DROPPABLE on schema change (desktop not in production).
/// Holds Read Models (DTO projections) of patients, care, protection, audit,
/// and lookup data. NEVER store the SyncQueue (Outbox) here — A18-v2 creates
/// a physically separate SyncDatabase (`app_sync_queue.sqlite`) with
/// migration-protected schema. Mixing the two would cause Data Loss on
/// cache drops.
```

### 5. Optimistic locking field (storage only, logic in A18)

`version` (int) column on every table. A17-v2 stores it; tests assert round-trip. A18-v2 SyncEngine injects `WHERE id=X AND version=Y` on remote UPDATE — that's NOT this ticket.

### 6. No TTL automation

Não há expiração automática. `cachedAt` exposto na query result; A18 use cases decidem refresh policy (e.g., "if cachedAt < now - 5min, force remote refresh").

### 7. Out of scope for A17-v2

- SyncQueue / Outbox (A18-v2)
- Use cases que orquestram cache+remote+queue (A18-v2)
- Public facade (A18-v2)
- ADR-005 update (separate handbook docs ticket — Drift-stays decision)

## New target structure

```
bff/social_care_desktop/lib/src/cache/
├── _shared/
│   ├── cache_database.dart         — @DriftDatabase declaration (CacheDatabase)
│   ├── cache_database.g.dart       — generated by build_runner (Drift codegen)
│   ├── tables/
│   │   ├── patients_table.dart      — Patients + Patients FTS5 raw SQL
│   │   ├── care_table.dart          — Appointments
│   │   ├── protection_tables.dart   — Referrals + Violations + Placement
│   │   ├── audit_table.dart         — AuditTrailEntries
│   │   └── lookup_tables.dart       — LookupTableEntries + LookupRequests
│   └── failures.dart                — CacheFailure (mapped from Drift exceptions)
├── contracts/
│   ├── patients_cache.dart          — abstract interface PatientsCache
│   ├── care_cache.dart              — abstract interface CareCache
│   ├── protection_cache.dart        — abstract interface ProtectionCache
│   ├── audit_cache.dart             — abstract interface AuditCache
│   └── lookup_cache.dart            — abstract interface LookupCache
├── daos/
│   ├── patient_dao.dart             — @DriftAccessor — raw SQL + FTS5 search
│   ├── care_dao.dart
│   ├── protection_dao.dart
│   ├── audit_dao.dart
│   └── lookup_dao.dart
└── impls/
    ├── drift_patients_cache.dart    — implements PatientsCache; uses PatientDao
    ├── drift_care_cache.dart
    ├── drift_protection_cache.dart
    ├── drift_audit_cache.dart
    └── drift_lookup_cache.dart
```

## Acceptance criteria

- [ ] 5 cache contracts (`abstract interface class`) in `contracts/`.
- [ ] 1 `CacheDatabase` (`@DriftDatabase`) in `_shared/cache_database.dart` with codegen via `build_runner`.
- [ ] 5 table files + 5 DAO files; each cacheable context has B-Tree indices for lookups + FTS5 virtual table where text search is needed (Patients, Lookup names).
- [ ] 5 cache impls in `impls/`, each `implements <One>Cache`. No god-class.
- [ ] Drift migration (`onCreate`) creates main tables AND FTS5 virtual tables AND triggers.
- [ ] Tests use `NativeDatabase.memory()` (in-memory Drift) — no file I/O.
- [ ] Each contract has its own test file in `test/cache/<contract>_test.dart` covering: upsert, find by ID, list, search (where applicable), delete, clear, version round-trip, cachedAt round-trip.
- [ ] FTS5 tests: token match, prefix match (`MATCH 'term*'`), no-match returns empty, sync after upsert, sync after delete.
- [ ] `dart analyze bff/social_care_desktop/` zero errors zero warnings (info acceptable for codegen artifacts).
- [ ] `flutter test test/cache/` all GREEN.
- [ ] No `SocialCareContract`, `LocalCacheContract`, or `OfflineFirstRepository` references anywhere.
- [ ] Header docstring in `cache_database.dart` documents the SyncQueue separation (A18-v2 will create `SyncDatabase` in separate file).

## Wave plan

- **W0 RED — test-writer:** failing tests for 5 cache contracts (~80-100 tests). Compile-fail expected.
- **W1 GREEN — flutter-bff-implementer:** Drift schema + tables + FTS5 + DAOs + 5 impls; pass tests.
- **W2 REVIEW — flutter-code-reviewer:** audit SRP, FTS5 correctness, no SyncQueue contamination, Result<T> discipline, optimistic locking present, header docstring present.

## Status
**CLOSED 2026-04-30** — APPROVED Round 1 via 3-agent BFF pipeline.

- W0 RED: 81 failing tests across 5 cache contracts + in-memory DB helper. 5 surfaces locked (Aggregate-Root aligned).
- W1 GREEN: 24 impl files (5 contracts + 1 CacheDatabase + 5 tables + 5 DAOs + 5 impls + 1 CacheFailure + 11 codegen `.drift.dart`) + pubspec deps + build.yaml. 1 REGRA #2 surfaced (`_ready` warm-up pattern resolved DB-failure test intent without modifying tests).
- W2 REVIEW: APPROVED. 13/13 audit checks pass. 3 NICE_TO_HAVE non-blocking.

**Acceptance criteria final state:**
- [x] 5 cache contracts (`abstract interface class`) in `contracts/`.
- [x] `CacheDatabase` (`@DriftDatabase`) with codegen via `build_runner`.
- [x] 5 table files + 5 DAO files; B-Tree indices + FTS5 virtual tables (Patients summaries + Lookup tableNames).
- [x] 5 cache impls in `impls/`; each `implements <One>Cache`. No god-class.
- [x] `MigrationStrategy.onCreate` creates main tables + 2 FTS5 virtual tables + 6 triggers (AI/AU/AD).
- [x] Tests use `NativeDatabase.memory()`; 81 tests covering CRUD + FTS5 + version round-trip + cachedAt round-trip + DB-failure path.
- [x] `dart analyze bff/social_care_desktop/` zero issues.
- [x] `flutter test test/cache/` 81/81 GREEN. Full suite 234/234 GREEN (no A16-v2 regression).
- [x] No `SocialCareContract`, `LocalCacheContract`, or `OfflineFirstRepository` references.
- [x] Header docstring on `cache_database.dart` documents SyncQueue separation (A18-v2 will create separate DB).
- [x] Library exports 5 contracts (impls library-private until A18-v2 facade).

**Next ticket:** A18-v2 (sync/ + use_cases/ + facade/ — restaurar `apps/acdg_system/`).
