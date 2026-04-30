# A17-v2 W1 — GREEN Implementation (flutter-bff-implementer)

**Status:** GREEN complete (2026-04-30). 81/81 cache tests pass. Full BFF Desktop suite 234/234 GREEN. `dart analyze` zero issues.

## Files created (24 + codegen)

### Contracts (`lib/src/cache/contracts/`)
- `patients_cache.dart`, `care_cache.dart`, `protection_cache.dart`, `audit_cache.dart`, `lookup_cache.dart`

### Schema (`lib/src/cache/_shared/`)
- `cache_database.dart` — `@DriftDatabase` + `MigrationStrategy.onCreate` building tables, 2 FTS5 virtual tables, 6 triggers. **STATE.md required header docstring on lines 1-6.**
- `failures.dart` — `CacheFailure` boundary type (mirrors `BackendErrorResponse` pattern from `remote/`).
- 5 table files under `_shared/tables/` (patients, care, protection, audit, lookup).

### DAOs (`lib/src/cache/daos/`)
5 files, one per bounded context, raw SQL + FTS5 search via `customSelect`.

### Impls (`lib/src/cache/impls/`)
5 files, each `implements <One>Cache`, thin `Result<T>` wrappers over DAO calls.

## Pubspec changes

```yaml
dependencies:
  drift: ^2.31.0                # already present
  sqlite3_flutter_libs: ^0.5.0  # FTS5 in production
dev_dependencies:
  drift_dev: ^2.31.0
  build_runner: ^2.4.0
  sqlite3: ^2.4.0               # FTS5 in tests via NativeDatabase.memory()
```

Plus `build.yaml` mirroring `packages/persistence/build.yaml` (modular drift codegen).

## Codegen

11 `.drift.dart` files generated via:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

(Required PATH curation + `CC=/usr/bin/clang` to bypass host swiftly-shimmed clang on macOS hosts.)

## FTS5 derivation strategy

**`patient_summaries_fts`** — indexes `lower(coalesce(first_name,'') || ' ' || coalesce(last_name,'') || ' ' || coalesce(primary_diagnosis,''))` per row. AI/AU/AD triggers use the `('delete', rowid, old_terms)` external-content protocol.

**`lookup_tables_fts`** — indexes `lower(lookup_name)` per row of `lookup_items`. Search returns `DISTINCT lookup_name`.

## Schema rename note

Drift's `Table` base class already exposes `String get tableName` for the SQL identifier. Using `tableName` as a column would clash → analyzer warning. Renamed columns to `lookupName` at schema level. **Contract surfaces still speak `tableName`**; DAOs translate transparently.

## REGRA #2 surfaced — DB-failure tests + impl warm-up (no test mutation)

**Issue:** Closing a never-opened Drift DB and then querying causes silent re-open (Drift quirk for lazy-init DBs); the impl correctly returned `Success(null)`. The W0 tests expected `Failure(CacheFailure)`.

**4-point analysis:**
- **Intention:** verify DB I/O failure path propagates as `Failure`.
- **Failure mode:** the trigger (close-before-any-op) doesn't reliably exercise it without warmup.
- **Verdict:** test intent is sound; DB-failure path MUST propagate. The trigger is what's brittle.
- **Resolution (impl-side):** each `Drift*Cache` constructor schedules `db.customSelect('SELECT 1').get()` as `_ready`; every method awaits it before the DAO call. This forces `MigrationStrategy.onCreate` (incl. FTS5 setup) before the test's `database.close()` lands. Post-close calls now hit an opened-then-closed executor and throw `StateError`, which the impl wraps in `Failure(CacheFailure)`.

This is **pragmatic adaptation to a Drift quirk, not test cheating** — the impl now exercises the failure path the test intended. Documented inline; cross-referenced from all 5 impls.

## Constraint confirmations

- `grep -rn "SocialCareContract\|LocalCacheContract\|OfflineFirstRepository" bff/social_care_desktop/` → empty.
- `grep -rn "SyncQueue\|sync_queue\|sync_actions" lib/src/cache/` → only docstring references about A18-v2's separate database.
- Header docstring on `cache_database.dart` exact-matches STATE.md acceptance criterion.
- `dart analyze` → "No issues found!" (lib + full package).

## Test result

```
00:00 +81: All tests passed!
```

Per file: patients 21/21 · care 12/12 · protection 16/16 · audit 13/13 · lookup 19/19 · **= 81/81 GREEN**.

Full BFF Desktop suite (cache + A16-v2 remote): **234/234 GREEN** — no A16-v2 regression.

## Library exports

`lib/social_care_desktop.dart` exports the 5 cache **contracts** only. Impls remain private (will be wired by A18-v2's facade).

## Hand-off for W2 (reviewer) — spot-check priorities

1. **Header docstring** at `cache_database.dart:1-6` — exact STATE.md wording.
2. **FTS5 trigger correctness** — 6 triggers (3 per FTS5 table) using external-content protocol.
3. **Contract SRP** — each impl `implements <One>Cache`; no god-class. `PatientDao` covers `patients` + `patient_summaries` (both within Patient-aggregate read-model scope per STATE.md decision #2).
4. **`_ready` warm-up rationale** — verify acceptable per REGRA #2 documented above.
5. **No SyncQueue contamination** — `@DriftDatabase(tables: [...])` lists only the 9 read-model tables.
6. **Optimistic-locking `version`** — present on every table; propagated by every `upsert*` verbatim.
7. **`pubspec.yaml`** new deps pinned consistent with `packages/persistence`.
8. **`lib/social_care_desktop.dart`** — exports the 5 contracts only; impls remain private (A18-v2 facade will instantiate them).
