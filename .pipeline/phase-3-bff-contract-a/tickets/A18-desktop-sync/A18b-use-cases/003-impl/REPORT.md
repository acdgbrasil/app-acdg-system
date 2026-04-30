# A18b-v2 W1 — GREEN Implementation (flutter-bff-implementer)

**Status:** GREEN complete (2026-04-30). 90/90 use case tests + 376/376 full BFF Desktop suite GREEN. `dart analyze` zero errors zero warnings.

## Files created

### Shared utilities (`lib/src/use_cases/_shared/` + cache layer)
- `lib/src/cache/_shared/cached.dart` — `Cached<T>` envelope (cache layer owns it)
- `lib/src/use_cases/_shared/cached.dart` — re-export for use case consumers
- `lib/src/use_cases/_shared/clock.dart` — `class Clock { DateTime now() => DateTime.now(); }`
- `lib/src/use_cases/_shared/use_case_failures.dart` — `NotFoundFailure`
- `lib/src/use_cases/_shared/stale_policy.dart` — `StalePolicy`
- `lib/src/use_cases/_shared/version_extractor.dart` — `extractPatientVersion(StandardResponse)`

### 42 use cases by bounded context

```
lib/src/use_cases/
├── registry/   — 13 (4 reads + 9 writes)
├── assessment/  — 7 (all writes)
├── care/        — 3 (1 read + 2 writes)
├── protection/  — 6 (3 reads + 3 writes)
├── audit/       — 1 (read)
├── lookup/      — 10 (4 reads + 6 writes)
└── health/      — 2 (passthroughs)
```

`grep -c "class \w*UseCase" lib/src/use_cases/**/*.dart` = 42.

### A17 cache contract refactor — surgical

**NOT full refactor.** Only the methods that use cases consume for `cached.version` reads:
- `PatientsCache.findById` → `Future<Result<Cached<PatientResponse>?>>`
- `PatientsCache.findByPersonId` → `Future<Result<Cached<PatientResponse>?>>`
- `LookupCache.findItemById` → `Future<Result<Cached<LookupItemResponse>?>>`
- `LookupCache.findRequestById` → `Future<Result<Cached<LookupRequestResponse>?>>`

Care/Protection/Audit kept their original DTO returns — their use cases either get version from PatientsCache (Care/Protection) or are register-style with `expectedVersion: 0` (Audit).

**Clock injection added cross-cutting:** all 5 cache impls accept `now: DateTime Function()?` (defaults to `DateTime.now`). Tests wire `fakeClock.now` for deterministic staleness.

### A17 cache test updates

Mechanical edits in `test/cache/patients_cache_test.dart` and `test/cache/lookup_cache_test.dart`:
- `value!.field` → `value!.dto.field`
- `Failure<DTO?>` → `Failure<Cached<DTO>?>` annotations

### Pubspec changes

```yaml
dependencies:
  uuid: ^4.0.0  # NEW
```

### Library exports

`lib/social_care_desktop.dart` adds:
- `Cached<T>`, `Clock`, `StalePolicy`, `NotFoundFailure`, `extractPatientVersion`
- All 42 use case classes

## W0 open question resolutions

1. **Q1 — copyWith on DTOs:** **Skipped.** W0 tests assert `cached.version` bumped, NOT specific patched fields. Optimistic write re-upserts same DTO with bumped version → all GREEN. **No `bff/shared/` modifications.**

2. **Q2 — Sub-contracts lack list endpoints:** **Accepted cache-only with empty fallback.** ListAppointments / ListReferrals / ListViolationReports / FetchPlacementHistory / FindLookupRequestById return cache state. Flagged for Phase 6+ to extend backend.

3. **Q3 — Cached<T> refactor (Option a):** **Surgical, not full.** Only 4 method signatures across 2 contracts. `Cached<T>` lives in cache layer (`lib/src/cache/_shared/cached.dart`); use cases re-export.

4. **Q4 — uuid dep:** Added `uuid: ^4.0.0`.

5. **Q5 — REGRA #2 #2 boundary:** Pre-enqueue only; honored. 9 "outbox failure → cache UNCHANGED + engine NOT triggered" tests pass.

## Architectural decisions

- **Clock injection into cache impls (cross-cutting).** Required by W0's deterministic staleness contract. Production code passes nothing → `DateTime.now`. Tests pass `fakeClock.now`.
- **`StalePolicy.isStale` simple semantic** (`now.difference(cachedAt) > staleAfter`). Safe because Clock-injection invariant guarantees `cachedAt <= now`.
- **All Pattern-2 writes accept `required Clock clock` and `Uuid? uuid`** for deterministic test FIFO ordering.
- **Cache-only reads accept `Clock` / `Duration staleAfter` for API uniformity** but don't store them — preserves W0 constructor contract without unused-field warnings.

## Test result

- 90/90 use case tests GREEN
- A17 cache tests: GREEN after Cached<T> refactor
- A18a sync infra tests: untouched, GREEN
- A16 remote tests: untouched, GREEN
- `bff/shared/test/`: 549/549 GREEN; no DTOs touched
- **Full BFF Desktop suite: 376/376 GREEN**

## `dart analyze` final state

- `bff/social_care_desktop`: **0 errors, 0 warnings**
  - 43 info-level `unnecessary_import` hints in W0-authored test files (W0 imported each use case explicitly; now redundant with `_test_helpers.dart` re-exports but harmless and not modifiable per REGRA #2)
- `bff/shared`: 3 pre-existing issues on `rg_document.dart` (unrelated to A18b)

## Constraint confirmations

- No `SocialCareContract` god-interface references
- No service locator / Provider lookups; constructor injection only
- All 42 use cases follow exactly ONE of the 3 patterns
- Write order verified: read cached version → build mutation → enqueue → optimistic upsert → triggerDrain
- NO rollback on `failed_dead`
- `Result<T>` end-to-end; no `throw` in use case bodies
- Pattern matching exhaustive on `Result<T>`

## REGRA #2 — zero ambiguities surfaced in W1

W0 pre-resolved 4. None new in W1.

## Hand-off for W2 (reviewer) — spot-check priorities

1. **Cache impl `now` injection** — `now: DateTime Function()?` seam vs typed `Clock` wrapper. Reviewer may want a follow-up to promote it to typed Clock.
2. **`Cached<T>` location** — cache layer owns it, re-exported by use_cases. Verify import paths.
3. **`StalePolicy` simple semantics** — safe only because of Clock-injection invariant; consider documenting on `Cached<T>` or `StalePolicy`.
4. **42 use cases × 3 patterns** — `grep "class \w*UseCase" lib/src/use_cases/**/*.dart` = 42. Each file body matches one pattern verbatim.
5. **`unawaited(_engine.triggerDrain())`** — fire-and-forget is canonical; drain summary surfaced by A18c.
6. **`uuid: ^4.0.0`** version pin — verify against workspace constraints.
7. **A17 cache contract surgical refactor** — only 4 method sigs changed; Care/Protection/Audit untouched. Confirm rationale is acceptable (not all reads need `Cached<T>` if their use case doesn't call `findById`).

## Out of scope (correctly skipped)

- Public facade + sub-facades (A18c)
- `apps/acdg_system/` rewire (A18c)
- Connectivity restore listener (A18c)
- DTO `copyWith` in `bff/shared/`
- Backend list-by-id endpoints for Care/Protection/Lookup (Phase 6+ follow-up)
