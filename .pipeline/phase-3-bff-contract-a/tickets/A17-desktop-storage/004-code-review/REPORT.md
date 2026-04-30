# A17-v2 W2 — Code Review (flutter-code-reviewer)

## Verdict

**APPROVED** — Round 1 of 3. Findings: **0 MUST_FIX, 0 SHOULD_FIX, 3 NICE_TO_HAVE.**

Independently verified W1's claims:
- `flutter test test/cache/` → `+81: All tests passed!`
- `flutter test` → `+234: All tests passed!` (cache + A16-v2 remote, no regression)
- `dart analyze` → `No issues found!`

## Audit checklist (13/13 PASS)

### 1. Header docstring (CRITICAL — STATE.md acceptance criterion) — PASS
`lib/src/cache/_shared/cache_database.dart:1-6` matches STATE.md exact text character-for-character. Bonus secondary docstring at `:18-22` reinforces SyncQueue separation.

### 2. SyncQueue NOT in cache DB — PASS
`@DriftDatabase(tables: [...])` at `cache_database.dart:23-35` lists exactly the 9 read-model tables. `grep -rn "SyncQueue\|sync_queue\|sync_actions\|SyncAction\|OutboxEntry"` → only docstring mentions warning A18-v2 will own it.

### 3. Cache contract fidelity vs W0 hand-off — PASS

| Contract | File | Methods | Match W0 |
|---|---|---:|:---:|
| `PatientsCache` | `contracts/patients_cache.dart:12-55` | 9 | yes |
| `CareCache` | `contracts/care_cache.dart:10-30` | 5 | yes |
| `ProtectionCache` | `contracts/protection_cache.dart:9-60` | 12 (4+4+3+1) | yes |
| `AuditCache` | `contracts/audit_cache.dart:7-26` | 5 | yes |
| `LookupCache` | `contracts/lookup_cache.dart:10-55` | 12 | yes |

All declared `abstract interface class`. All return `Future<Result<T>>` / `Future<Result<List<T>>>` / `Future<Result<void>>`.

### 4. No god-class — PASS
Each impl `implements <One>Cache`:
- `DriftPatientsCache implements PatientsCache` — `impls/drift_patients_cache.dart:26`
- `DriftCareCache implements CareCache` — `impls/drift_care_cache.dart:15`
- `DriftProtectionCache implements ProtectionCache` — `impls/drift_protection_cache.dart:15`
- `DriftAuditCache implements AuditCache` — `impls/drift_audit_cache.dart:15`
- `DriftLookupCache implements LookupCache` — `impls/drift_lookup_cache.dart:15`

`grep -rn "SocialCareContract\|LocalCacheContract\|OfflineFirstRepository"` → empty.

### 5. CRUD surface (CQRS-aligned) — PASS
Every contract method is `find*`, `list*`, `search*`, `upsert*`, `delete*`, or `clear*`. No business action verbs.

### 6. FTS5 + triggers — PASS
2 FTS5 virtual tables + 6 triggers (3 per: AI/AD/AU) in `MigrationStrategy.onCreate` (`cache_database.dart:51-136`). External-content protocol correct: AD/AU emit `('delete', rowid, old_terms)` then re-insert. DAO search queries (`patient_dao.dart:77-86`, `lookup_dao.dart:36-50`) use canonical `WHERE rowid IN (SELECT rowid FROM <fts> WHERE <fts> MATCH ?)`. Tests confirm token, prefix (`Mari*`), no-match, re-sync behavior.

### 7. Result<T> + try/catch boundary — PASS
Every public method: `try { await _ready; dao_call; return Success; } catch (e, st) { return Failure(CacheFailure(e), stackTrace: st); }`. Uniform across 5 impls. Missing rows: `Success(null)` (e.g. `drift_patients_cache.dart:39, 55`). `CacheFailure` wraps raw Drift exceptions at `_shared/failures.dart:7-16`.

### 8. `_ready` warm-up pattern (REGRA #2 from W1) — PASS
Every impl constructor schedules `db.customSelect('SELECT 1').get()` as `_ready`; every public method awaits it. Documented at `drift_patients_cache.dart:18-25`, cross-referenced from 4 other impls. DB-failure test (`patients_cache_test.dart:471-479`) verifies original intent — closed DB returns `Failure(CacheFailure)`. Pragmatic adaptation, not test cheating.

### 9. Optimistic-locking version — PASS
`IntColumn get version => integer()();` on every table:
- `patients_table.dart:16, 40` · `care_table.dart:12` · `protection_tables.dart:9, 22, 36` · `audit_table.dart:17` · `lookup_tables.dart:15, 31`

Every `upsert*` takes `{required int version}` and stores verbatim. `cachedAt` via `DateTime.now()` per REGRA #2 #2.

### 10. Library exports — PASS
`lib/social_care_desktop.dart:18-22` exports 5 cache contracts only. Impls library-private (A18-v2 facade will instantiate). 7 A16-v2 remote exports preserved at lines 9-15.

### 11. Pubspec — PASS
`drift ^2.31.0`, `sqlite3_flutter_libs ^0.5.28`, `drift_dev ^2.31.0`, `build_runner ^2.4.0`, `sqlite3 ^2.7.4`. `build.yaml` mirrors `packages/persistence/build.yaml`. No conflicts.

### 12. Codegen artifacts present — PASS
11 `.drift.dart` files: `_shared/cache_database.drift.dart` + 5 in `_shared/tables/` + 5 in `daos/`.

### 13. Test result independent verification — PASS
W1's 234/234 GREEN claim confirmed.

## NICE_TO_HAVE (non-blocking)

1. **FTS5 MATCH parameter binding** — `patient_dao.dart:81` and `lookup_dao.dart:45` build MATCH via string interpolation with `replaceAll("'", '').trim()` sanitization. Safer would be `customSelect(..., variables: [Variable.withString('${sanitized}*')])` with `?` placeholder.

2. **`_ready` warmup explicit test coverage** — pattern documented in impl comments; warmup itself not asserted directly (only side-effect via closed-DB Failure). Constructor-level test would document the contract.

3. **`version` non-negative constraint** — adding `.check(version.isBiggerOrEqualValue(0))` at table layer would catch caller bugs at write time. A18-v2's optimistic locking relies on monotonic version semantics.

None block approval.

## Conclusion

**Verdict: APPROVED.** All STATE.md acceptance criteria satisfied: header docstring exact match, 5 contracts (Aggregate-Root aligned), 9 tables + 2 FTS5 virtual tables + 6 triggers, no SyncQueue contamination, no god-class, optimistic-locking `version` everywhere, library exports contracts only, pubspec consistent. Pipeline advances to ticket close.
