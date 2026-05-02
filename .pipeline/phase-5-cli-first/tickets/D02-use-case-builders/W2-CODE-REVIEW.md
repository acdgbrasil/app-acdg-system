# D02 W2 — Code Review

**Reviewer:** flutter-code-reviewer (W2 / Round 1)
**Scope:** D02 — Extract 7 per-bounded-context UseCase Builders + simplify 7 sub-facades + reduce `social_care_desktop.dart` 637L → 364L
**Profile:** REFACTOR — behavior must not change, surface pública intacta
**Method:** read-only audit + line-by-line diff against `HEAD` (D01 closed at `06da0dd`)

**Files audited:**
- NEW prod: 7 builders under `lib/src/facade/composition/builders/` (162 + 95 + 67 + 89 + 38 + 130 + 29 = 610L total)
- MOD prod: `social_care_desktop.dart` (637L → 364L; delta −273L)
- MOD prod: 7 sub-facades (combined ~418L → ~318L; delta −100L)
- NEW tests: `_builders_test_helpers.dart` (234L) + 7 builder structural tests (21 tests total)
- Public barrel `lib/social_care_desktop.dart`: verified untouched (zero diff)

---

## Verdict: APPROVED — Round 1/3

Behavior preserved bit-for-bit across all 42 use cases (mechanical Python audit, 0 discrepancies). Surface pública intact (`SocialCareDesktop.create()` signature unchanged; sub-facade public methods identical; barrel unchanged). Encapsulation/Pattern Matching policies respected. All 6 W1 architectural decisions sound. No MUST_FIX. Two SHOULD_FIX items (carry-overs from D01 — neither addressed by D02, neither blocking).

---

## Round: 1/3

---

## Behavior preservation

### Per-use-case dep audit (42/42 byte-identical)

I extracted every `XxxUseCase(...)` block from the legacy `social_care_desktop.dart` (`HEAD`) and from the 7 new builders, normalised variable renames (`effectiveClock` → `clock`, `xxxRemote` → `remote`), and compared.

**Result: 0 discrepancies across 42 use cases.**

| Category | Count | Verdict |
|---|---|---|
| Pattern 1 reads (cache + remote + clock + staleAfter) | 4 Registry + 1 Care + 1 Audit + 4 Lookup = 10 | All preserved |
| Pattern 2 patient-aggregate writes (patientsCache + outbox + engine + clock) | 9 Registry + 7 Assessment + Update intake/placement = 18 | All preserved |
| Pattern 2 protection-cache reads (cache + clock + staleAfter, no remote) | 3 Protection | All preserved (`remote:` correctly omitted) |
| Pattern 2 outbox-only writes (outbox + engine + clock, no cache) | 2 Protection + 2 Lookup request creates = 4 | All preserved |
| Pattern 2 lookup-cache writes (cache + outbox + engine + clock) | 4 Lookup item writes = 4 | All preserved |
| Pattern 2 care-cache writes (careCache + outbox + engine + clock) | 1 Care (RegisterAppointment) | All preserved (`careCache:` named arg) |
| Pattern 3 health passthroughs (remote only) | 2 Health | All preserved |

### Spot-check on exotic deps (sample of 4)

| Use case | Cache used | Verdict |
|---|---|---|
| `UpdateIntakeInfoUseCase` | `patientsCache: patientsCache` (NOT careCache) | OK — both legacy and new use `patientsCache: patientsCache` (intake info lives on Patient aggregate, A18b-v2). Care builder accepts BOTH `careCache` and `patientsCache` for this exact reason — the asymmetry is documented in the builder docstring. |
| `UpdatePlacementHistoryUseCase` | `patientsCache: patientsCache` (NOT protectionCache) | OK — placement history lives on Patient aggregate. Protection builder accepts both `protectionCache` and `patientsCache`. |
| `RegisterAppointmentUseCase` | `careCache: careCache` (named arg, not generic `cache:`) | OK — preserved in `care_use_cases.dart:54-58`. |
| `Pattern-1 Protection reads` (ListReferrals/ListViolationReports/FetchPlacementHistory) | `cache + clock + staleAfter` (no `remote:`) | OK — protection reads are cache-only because Phase 5 backend doesn't expose protection list/get endpoints. Builder correctly omits `remote:` parameter in these 3 invocations. |

### `social_care_desktop.dart` cleanup

| Check | Verdict |
|---|---|
| 42 individual `final foo = FooUseCase(...)` declarations removed | OK — replaced with 7 `final fooUseCases = FooUseCases.build(...)` calls |
| 42 individual use case imports removed | OK — replaced with 7 builder imports |
| Sub-facade construction simplified to `Facade.internal(useCases: ...)` | OK — all 7 sub-facade calls use the new single-param form |
| Dead imports remaining | NONE — verified with per-symbol grep across 30 imported types |

### Diff sanity

`git diff HEAD apps/social_care_bff/desktop/lib/src/facade/social_care_desktop.dart` shows only:
- Library-doc addition: "Composition (D02): 7 per-bounded-context builders…"
- Comment header rename (`Factory (D3 + D4 + D5 wired)` → `Factory (D3 + D4 + D5 + D02 wired)`)
- Removal of 42 use case imports + replacement with 7 builder imports
- Removal of 42 `final XxxUseCase = XxxUseCase(...)` blocks + replacement with 7 builder invocations
- Sub-facade calls collapsed from N args to 1 (`useCases:`)

No semantic drift. Constructor sequence (caches → outbox → remotes → drainController → engine → use-case bundles → sub-facades → connectivity wiring → instance assembly) is preserved exactly.

---

## Surface pública

| Check | Verdict |
|---|---|
| `SocialCareDesktop.create()` signature | UNCHANGED — same 11 parameters as D01 closed (`baseUrl`, `actorId`, `tokenProvider`, `cacheFilePath?`, `syncQueueFilePath?`, `dio?`, `clock?`, `staleAfter`, `connectivity?`, `executorFactory?`) |
| `SocialCareDesktop.{startSync, stopSync, close, triggerDrain, drainStream}` | UNCHANGED |
| Public sub-facade getters (`registry`, `assessment`, `care`, `protection`, `audit`, `lookup`, `health`) | UNCHANGED |
| Public sub-facade method signatures | UNCHANGED — verified 1:1 across all 7 sub-facades via `grep "Future<Result"` diff (legacy vs new). Only differences are method bodies (`_foo(...)` → `_useCases.foo(...)`) — purely internal |
| Public barrel `lib/social_care_desktop.dart` | UNCHANGED — `git diff HEAD` returned empty. 42 use case classes still individually exported; 7 sub-facades still exported; `SocialCareDesktop` still exported. Builders are NOT exported (correct — internal composition). |
| Sub-facade `.internal()` constructor signature | CHANGED (from N use cases to 1 grouped `XxxUseCases`) — but this constructor is INTERNAL (called only by `social_care_desktop.dart::create()`). Verified via `grep -rln "Facade\.internal"` across all of `apps/social_care_bff/desktop/`: 9 hits, all inside `lib/src/facade/`. Zero test files outside `test/facade/composition/builders/` construct sub-facades directly. The sub-facade `.internal()` is a documented internal API per existing convention (the `internal` suffix is the contract), so changing its parameter shape does NOT break the public surface. |

---

## Encapsulation / Pattern Matching policies

### ENCAPSULATION_POLICY (H1–H9)

| Rule | Verdict | Note |
|---|---|---|
| **H1 (SRP per file)** | OK | Each builder = 1 bounded context. File names map 1:1 to the 7 sub-facades (`registry_use_cases.dart` ↔ `registry_facade.dart`, etc.). |
| **H2 (Composition over inheritance)** | OK | Builders are plain data classes; zero `extends`, zero `implements`, zero `with` — verified by grep across all 7 builder files. Composition is the entire point: each builder composes 1–13 use cases from 4–7 shared dependencies. |
| **H3 (Pattern uniformity)** | OK | Reads use `(cache, remote, clock, staleAfter)`; writes use `(cache, outbox, engine, clock)`. Asymmetric builders (Care has 2 caches; Protection has cache-only reads + outbox-only writes; Health has only `remote`) document the asymmetry in the builder's library docstring. |
| **H5 (Abstract types where appropriate)** | OK | `build()` accepts abstract `XxxContract` for all reads (matches use case constructor expectations — verified that `FetchPatientUseCase` declares `required RegistryContract remote`, etc.). See "W1 architectural choices" below for fuller rationale. |
| **H7 (Composition over class when stateless)** | N/A | Builders are intentionally classes (data + factory) — using a free function would lose the field grouping that the sub-facade consumes. |
| **H9 (Interface across layers)** | OK | Builders depend on abstract contracts (`PatientsCache`, `RegistryContract`, `OutboxRepository`, `SyncEngine`, `Clock`) — never concrete impls. |

### PATTERN_MATCHING_POLICY (P1–P5)

| Rule | Verdict | Note |
|---|---|---|
| **P1 (Exhaustive switch on sealed types)** | N/A | Builders contain no flow control (just construction). |
| **P5 (No sealed downcast)** | OK | Verified via grep: zero `as Success` / `as Failure` / `valueOrNull!` across builders + sub-facades. |

---

## Builder cleanliness

| Check | Verdict |
|---|---|
| Each builder has clear docstring (bounded context + count + asymmetries) | OK — all 7 verified |
| `build()` factory uses named params | OK — every `build()` is `static FooUseCases build({required ..., required ...})` |
| Fields are `final` | OK — verified via `grep "^\s*final \w+UseCase "` (42 fields total: 13+7+3+6+1+10+2) |
| No business logic in builders — pure structural | OK — every `build()` body is just `return FooUseCases(field1: FooUseCase(...), field2: ...)`. No `if`, no `switch`, no conditional construction. |
| Field count matches spec | OK — Registry 13, Assessment 7, Care 3, Protection 6, Audit 1, Lookup 10, Health 2 (total 42 — matches A18b-v2 inventory) |
| `library;` directive | OK — all 7 use the directive (matches existing convention from D01: `pumping_sync_engine.dart`, `db_executor.dart`, etc.) |
| Magic strings | NONE in builder code (only import paths) |
| Code style — Dart 3+ APIs, named params, immutability | OK — every constructor uses `required this.foo` shorthand; every field `final` |

---

## W1 architectural choices (6 items)

### 1. Abstract contract types in `build()` (`RegistryContract` over `RegistryRemote`)

**Verdict: APPROVED.**

Spec (`000-request.md` line 56) says `required RegistryRemote remote` (concrete). W1 used `RegistryContract` (abstract). Three points of evidence justify the divergence:

1. **Existing use cases ALREADY declare abstract deps.** `FetchPatientUseCase` declares `required RegistryContract remote` (verified at `lib/src/use_cases/registry/fetch_patient_use_case.dart`). Same for `ListPatients`, `SearchPatients`, `FetchPatientByPersonId`, `ListAppointments`, `FetchAuditTrail`, `GetLookupTable` (all 4 reads) — every Pattern-1 read across the 6 contexts uses the abstract contract.
2. **Concrete IS-A contract.** `RegistryRemote extends RemoteBase implements RegistryContract` (verified at `lib/src/remote/registry_remote.dart:1`). Production wiring still creates concrete `RegistryRemote(dio: ...)` and passes it — type-safe.
3. **Test-time benefit.** With abstract types, `BuilderDeps.fresh()` can supply `FakeRegistryBff` (which implements `RegistryContract`) instead of forcing tests to instantiate real `RegistryRemote(dio: Dio())`. This matches the established testing pattern in the existing 22+ use case tests.

Decision is sound and architecturally cleaner than the spec.

### 2. `Health` builder has no Clock / Outbox / Engine

**Verdict: APPROVED.**

`HealthUseCases.build({required HealthContract remote})` — only param is `remote`. Verified via `grep` that `CheckHealthUseCase` and `CheckReadyUseCase` constructors take only `remote: HealthContract`. Health is Pattern-3 passthrough — no cache, no outbox, no clock. Builder correctly mirrors the use case shape. Asymmetry documented in builder docstring.

### 3. `Protection` builder has no `remote:`

**Verdict: APPROVED.**

`ProtectionUseCases.build()` parameters: `protectionCache, patientsCache, outbox, engine, clock, staleAfter`. NO `remote:`. Protection has 3 reads (cache-only — Phase 5 backend exposes no protection list/get endpoints) and 3 writes (Outbox-bound; sync engine drains them, not the use case directly). The 6 use case constructors all match this shape. Builder correctly mirrors. `staleAfter` is accepted "for Pattern-1 uniformity (H3)" per docstring — used by the 3 cache-only reads.

### 4. `library;` directive on each builder

**Verdict: APPROVED.**

Matches existing convention. D01 introduced this pattern (`pumping_sync_engine.dart`, `db_executor.dart`, `connectivity_helpers.dart`) and the precedent goes back further to other internal-only Dart files. The directive associates the file-level docstring with the library and is required by `dart analyze` for files that contain a top-level `///`-doc above `library;`.

### 5. Per-context ordering preserved (registry → assessment → care → protection → audit → lookup → health)

**Verdict: APPROVED.**

Verified via reading `social_care_desktop.dart::create()` lines 263–308 — order is `registry → assessment → care → protection → audit → lookup → health`. Identical to the legacy ordering at lines 291–538 of HEAD~0. Sub-facade construction order (lines 311–321) matches the bundle ordering. Instance assembly (lines 345–360) lists sub-facades alphabetically — also unchanged from legacy.

### 6. No barrel re-export of builders — internal composition only

**Verdict: APPROVED.**

Builders live under `lib/src/facade/composition/builders/` and are NOT exported from `lib/social_care_desktop.dart`. Reasoning is the same as D01's `DriftExecutorFactory`: builders are an internal composition concern; consumers of the BFF call `SocialCareDesktop.create()` (which internally calls the builders) and then use the public sub-facades. No external consumer needs to compose use cases independently. If a future ticket needs that (e.g. a CLI test harness), the barrel can be widened then.

---

## D01 SHOULD_FIX status

D01 W2 flagged two SHOULD_FIX items:

| Item | Status |
|---|---|
| 1. Move `_ProbeDb` to shared `test/_test_helpers/probe_db.dart` | **NOT addressed by D02.** Verified `find apps/social_care_bff/desktop/test -name "probe_db*"` returns nothing. The `_ProbeDb` shim still lives only inside `db_executor_test.dart`. |
| 2. Cross-link in `social_care_desktop.dart` library docstring to `pumping_sync_engine.dart` | **NOT addressed by D02.** The library docstring was updated for D02 (added "Composition (D02)" section) but no cross-link to `pumping_sync_engine.dart` was added. `PumpingSyncEngine` is still mentioned only in inline comments at lines 137 and 251. |

Neither is a regression. Both remain SHOULD_FIX (non-blocking) — carry forward to D03/D04.

---

## Test integrity

| Check | Verdict |
|---|---|
| 21 builder structural tests created (3 per builder × 7 builders) | OK — verified file count + test count via `grep "^\s*test("` |
| Tests assert non-null, type-correctness, factory-independence | OK — every test file has the same 3-test shape (`is not null + isA<XxxUseCase> + identical(a, b) is false + runtimeType match`) |
| `_builders_test_helpers.dart` reuses existing fakes (no duplication) | OK — uses `FakeRegistryBff/FakeAssessmentBff/...` from `bff/contracts/lib/src/testing/`, `FakeSyncEngine` from `test/use_cases/_fakes/`, real Drift in-memory caches over `NativeDatabase.memory()`. Only `_FakeHealthBff` and `BuilderFakeClock` are local — both are minimal, both have docstrings explaining the local re-declaration, both match the shape used in neighbour helpers. |
| 450 baseline preserved (W1 verified) | NOT directly verified by W2 (W3 will run tests) — but the test files import use cases (not legacy structures), the public surface is unchanged, and the per-use-case dep audit confirmed byte-identical construction. No mechanism by which the existing 450 tests could regress. |
| Baseline tests modified | NONE — W1's claim of "zero teste tocado" is consistent with the diff (only 7 `sub_facades/*.dart` and `social_care_desktop.dart` are MOD; 14 NEW files are all under `composition/builders/` or `test/facade/composition/builders/`). |

The 21 new tests verify the structural contract of `build()` — they don't re-test use case behavior (which the existing 450 tests already cover). Their failure modes are:
1. `build()` throws → caught by NPE on field access (test #1)
2. Field wired to wrong type (e.g. `fetchPatient` swapped with `listPatients`) → caught by `isA<T>` (test #2)
3. `build()` cached/singleton → caught by `identical(a, b) == false` (test #3)

These tests would fail loudly on any of the three regressions, so they are NOT silent-pass on a buggy impl.

---

## Issues by severity

### MUST_FIX (block W3)

**None.**

### SHOULD_FIX (non-blocking — flag for follow-up)

1. **D01 carry-over: `_ProbeDb` move to shared helper.** Still pending. Not blocking D02 — defer to D03/D04.
2. **D01 carry-over: cross-link library docstring to `pumping_sync_engine.dart`.** Still pending. The D02 docstring update added a "Composition (D02)" section but did NOT add a cross-link for D01. Not blocking — defer to D04 docs sweep.

### NICE_TO_HAVE (purely architectural polish)

1. **`AssessmentUseCases.build()` does not take a `staleAfter` even though it accepts a `clock`.** Reason: all 7 Assessment use cases are writes (Pattern 2) — `staleAfter` is only relevant for Pattern-1 reads. Spec uniformity could argue `AssessmentUseCases.build()` should still accept `staleAfter` as a parametric uniformity gesture (per H3), the way Protection does. But Protection uses `staleAfter` on its 3 reads — Assessment has no reads. Current shape is correct. Flagging only because reviewers may notice the asymmetry.
2. **`audit_use_cases.dart` builder for 1 use case feels heavy.** Docstring already addresses this ("not economy, it's uniformity"). When `RecordAuditEventUseCase` lands later, the entry point doesn't change. Architecturally correct.
3. **Builder filename + class name use plural (`registry_use_cases.dart` / `RegistryUseCases`) but each holds N use cases (1, 2, 3, 6, 7, 10, 13).** Consistent across all 7 — not a code smell.
4. **`BuilderFakeClock` re-declared in `_builders_test_helpers.dart` instead of importing the existing `FakeClock` from `test/use_cases/_test_helpers.dart`.** The helper file documents this choice (lines 38–41) — keeps the builder helper self-contained, avoids cross-folder helper coupling. Acceptable. If D03/D04 introduce more test helper folders, consider promoting to `test/_test_helpers/fake_clock.dart` (a single source of truth).
5. **No barrel re-export of builders.** Same rationale as D01 (`DriftExecutorFactory` not re-exported). When/if external consumers need to compose use cases independently, widen then.

---

## Final recommendation

**APPROVED to W3 (quality gate).**

Behavior preserved bit-for-bit (mechanical Python audit confirmed 0/42 discrepancies). Surface pública intact (every public method signature byte-identical; barrel unchanged; only the internal sub-facade `.internal()` constructor changed shape, and no test outside `test/facade/composition/builders/` constructs sub-facades directly). Encapsulation policy respected (H1 SRP per file, H2 composition not inheritance, H3 pattern uniformity, H5 abstract types, H9 interface across layers). Pattern-matching policy respected (P5 no sealed downcast). All 6 W1 architectural choices sound and documented. No MUST_FIX. Two D01 SHOULD_FIX items remain pending — neither addressed nor regressed.

W3 should:
1. Verify `dart analyze apps/social_care_bff/desktop/lib/` reports 0 issues.
2. Verify `dart format --output=none --set-exit-if-changed apps/social_care_bff/desktop/lib/` exits 0.
3. Confirm `apps/social_care_bff/desktop/` test count is 471 GREEN +1 skip (450 baseline from D01 + 21 new builder tests).
4. Confirm BFF Web (`apps/social_care_bff/web`) still 1137 GREEN — D02 only touched `desktop`, so no Web regression possible, but spot-check is cheap.
5. Confirm BFF Contracts (`apps/social_care_bff/contracts`) still 535 GREEN.

Total expected: 535 + 1137 + 471 = **2143 GREEN +1 skip** (vs D01's 2122 — delta +21 from D02's 21 new builder structural tests).

No round-2 needed.
