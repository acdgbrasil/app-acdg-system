# D01 W2 — Code Review

**Reviewer:** flutter-code-reviewer (W2 / Round 1)
**Scope:** D01 — extract `PumpingSyncEngine` + `DriftExecutorFactory` + helpers
**Profile:** REFACTOR — behavior must not change, surface pública intacta
**Method:** read-only audit + line-by-line diff against `HEAD~1`
**Files audited:**
- NEW prod: `pumping_sync_engine.dart` (48L), `db_executor.dart` (107L), `connectivity_helpers.dart` (13L)
- MOD prod: `social_care_desktop.dart` (718L → 637L; delta −81L)
- NEW tests: `db_executor_test.dart`, `connectivity_helpers_test.dart`, `pumping_sync_engine_test.dart`
- Public barrel: `lib/social_care_desktop.dart` (verified unchanged)

## Verdict: APPROVED — Round 1/3

Behavior preserved bit-for-bit, surface pública unchanged, encapsulation/pattern-matching policies respected, REGRA #2 exceptions properly documented. No MUST_FIX. Two minor SHOULD_FIX items and three NICE_TO_HAVE notes for future hygiene; none of them block W3 quality gate.

---

## Behavior preservation

Audited via `git diff HEAD~1 -- apps/social_care_bff/desktop/lib/src/facade/social_care_desktop.dart` plus side-by-side reads of legacy `_PumpingSyncEngine`, `_openDriftExecutor`, `_defaultPath`, `_resultsAreOnline` against the new public counterparts.

| Checkpoint | Verdict | Evidence |
|---|---|---|
| `_PumpingSyncEngine.triggerDrain` → `PumpingSyncEngine.triggerDrain` | OK | Lines 36–47 of `pumping_sync_engine.dart` reproduce the legacy switch byte-for-byte: `await super.triggerDrain()` → `Success`-arm `if (!_drainController.isClosed) _drainController.add(value);` → `Failure`-arm `break` → return `result`. No semantic drift. |
| `_openDriftExecutor` → `DriftExecutorFactory.production.open()` | OK | Same `:memory:` short-circuit (now via constant `_inMemoryMarker = ':memory:'`); same `NativeDatabase.createInBackground(File(filePath))` for disk path. The marker is centralised inside `db_executor.dart` (was top-level in the legacy facade) — purely a relocation. |
| `_defaultPath` → `defaultDesktopFilePath` | OK | Identical body: `await getApplicationDocumentsDirectory()` + `'${dir.path}/$fileName'`. Static method became free function — no semantic change. |
| `_resultsAreOnline` → `resultsAreOnline` | OK | Identical body: `results.any((r) => r != ConnectivityResult.none)`. Empty-list semantics preserved (`any` on empty → `false`). |
| `social_care_desktop.dart` `create()` adds optional `executorFactory` (default `production`) | OK | Line 232 `DriftExecutorFactory? executorFactory,` + line 234 `final factory = executorFactory ?? DriftExecutorFactory.production;`. `:memory:` literal in `cacheFilePath`/`syncQueueFilePath` still routes correctly because `_ProductionFactory.open(':memory:')` delegates to `_InMemoryFactory.open(...)` — backward-compat preserved. |
| `connectivity wiring` (D5 γ) | OK | Initial `resultsAreOnline(initialResults)` (line 599) and listener `resultsAreOnline(results)` (line 610) call sites swapped 1:1. Late-binding `desktop` closure unchanged. |
| `triggerDrain`/`startSync`/`stopSync`/`close` plumbing | OK | No edits in lines 169–208 except a single doc-link rename (`[_PumpingSyncEngine]` → `[PumpingSyncEngine]`). |

No behavior regression detected.

---

## Surface pública

| Check | Verdict |
|---|---|
| `SocialCareDesktop.create()` — only addition is **optional** `DriftExecutorFactory? executorFactory` | OK |
| `SocialCareDesktop.startSync/stopSync/close/triggerDrain` signatures | OK — unchanged |
| Sub-facade getters (`registry`/`assessment`/`care`/`protection`/`audit`/`lookup`/`health`) | OK — unchanged |
| `SocialCareDesktop.drainStream` | OK — unchanged |
| Sub-facades themselves | OK — not touched |
| Public barrel `lib/social_care_desktop.dart` | OK — `git diff HEAD~1` returned empty for the barrel; only `SocialCareDesktop` is exported, the new types stay internal as planned |

**One nuance:** the new `executorFactory` parameter exposes `DriftExecutorFactory` as a transitively-public type because callers passing it must import it. The barrel does NOT re-export `DriftExecutorFactory` — callers that want to override must reach into `package:social_care_desktop/src/facade/composition/db_executor.dart`. That's an internal-path import, which is allowed but slightly noisy. Flagged in NICE_TO_HAVE — not blocking.

---

## Encapsulation / Pattern Matching policies

### ENCAPSULATION_POLICY (handbook lines 357–369)

| Rule | Verdict | Note |
|---|---|---|
| **H1 (SRP per file)** | OK | `pumping_sync_engine.dart` only pumps drain summaries; `connectivity_helpers.dart` only collapses results to a bool; `db_executor.dart` only opens executors + resolves the default path. The path helper sits next to the factory because both belong to the database-composition concern (NICE_TO_HAVE below if W3 wants finer split). |
| **H2 (Composition > Inheritance)** | ACCEPTED | `PumpingSyncEngine extends SyncEngine`. The handbook declares `extends` "último recurso — evitar". This refactor does NOT change the inheritance choice — it preserves the legacy decision. The pre-existing rationale: the pump observes the engine's own `triggerDrain` Result; pumping post-result is a `Decorator`-style observation that, with the current `SyncEngine` API (no extension hook), only inheritance can wire without touching `SyncEngine` itself. A Decorator-via-composition refactor (D6/D7 reserved) would require `SyncEngine` to be `abstract interface class` or a `sealed`-typed contract — **out of scope for D01** per `000-request.md` ("Não introduzir Strategy no SyncEngine — D7 reservado"). Recorded as NICE_TO_HAVE for future Decorator/Observer refactor. |
| **H5 (`abstract interface class` for contracts)** | OK | `DriftExecutorFactory` is declared `abstract interface class` (line 28). External implementation is allowed (test #9 proves it via `_StubFactory implements DriftExecutorFactory`). |
| **H7 (Function over class when stateless)** | OK | `defaultDesktopFilePath` and `resultsAreOnline` are top-level free functions, not static methods on a wrapper class. |
| **H9 (Interface across layers)** | OK | The composition root depends on the abstract interface, not the impls — `_ProductionFactory` and `_InMemoryFactory` are file-private. |

### PATTERN_MATCHING_POLICY

| Rule | Verdict | Note |
|---|---|---|
| **P1 (Exhaustive switch on sealed types)** | OK | `PumpingSyncEngine.triggerDrain` switches on `Result<DrainSummary>` with both arms (`Success<DrainSummary>(:final value)` and `Failure<DrainSummary>()`). The compiler will complain if a third arm appears. |
| **P5 (No sealed downcast)** | OK | No `as Success` / `as Failure` / `valueOrNull!` anywhere in the new code. |

---

## Factory Method (GoF)

| Check | Verdict | Note |
|---|---|---|
| Multiple impls (`production`, `inMemory`) | OK | Two `static const` singletons exposed on the abstract interface. |
| `:memory:` marker delegated cleanly inside the production factory | OK with caveat | `_ProductionFactory.open(':memory:')` calls `DriftExecutorFactory.inMemory.open(filePath)` rather than directly `NativeDatabase.memory()`. This is one extra hop versus inlining, but keeps the `NativeDatabase.memory()` call site centralised in `_InMemoryFactory`. The legacy code did inline it — that's where the new code IS slightly different in shape but identical in observable behavior. The marker constant `_inMemoryMarker = ':memory:'` is now file-private and the only string-literal occurrence in production code (was top-level in the legacy facade). Net win for SRP. |
| `static const` singletons (identity-stable) | OK | Tests #266–284 of `db_executor_test.dart` assert `identical(a, b) == true` for both. |
| Composition root injection point | OK | `SocialCareDesktop.create({ ..., DriftExecutorFactory? executorFactory })` — default `production`, tests pass `inMemory`. |

---

## REGRA #2 exception validation (4 fixture-fixed tests)

W0.5-bis edited 4 tests in `db_executor_test.dart`. Audited each comment block:

### Test #5 (`production: open(real disk path) round-trips`)
- **Fix:** wraps the `QueryExecutor` returned by `production.open(...)` in `_ProbeDb` (a minimal `GeneratedDatabase` shim with `allTables=[]`, `allSchemaEntities=[]`, `schemaVersion=1`). The shim forces the `LazyDatabase._delegate` to initialise via the standard `ensureOpen()` handshake before `customStatement`/`customSelect` runs.
- **REGRA #2 comment:** lines 178–187 — explains the empirical root cause (`LateInitializationError: LazyDatabase._delegate@... has not been initialized`) and clarifies that the test intent (round-trip data through filesystem) is preserved.
- **Verdict:** OK — fix is mechanical, intent fully preserved, comment exhaustive.

### Test #6 (`production: open(real disk path) materializes a file`)
- **Fix:** same `_ProbeDb` shim, single `customStatement` to fire `ensureOpen()`, then `expect(File(dbPath).existsSync(), isTrue)`.
- **REGRA #2 comment:** lines 232–237 — references the same root cause as #5.
- **Verdict:** OK — same shim approach, preserves "factory persists to requested path" intent.

### Test #10 (`defaultDesktopFilePath: resolves a path OR throws plugin/binding error`)
- **Fix:** `try { ... } on Object catch (e)` + substring match on `'plugin' || 'Binding' || 'initialized'`. The legacy assertion only caught `MissingPluginException`, but `flutter test` raises `FlutterError("Binding has not yet been initialized")` from `BindingBase.checkInstance` BEFORE the plugin channel is even probed.
- **REGRA #2 comment:** lines 305–317 — references the legacy pattern at `social_care_desktop_test.dart:455–505` (verified above; that test does the same `caught.toString().toLowerCase().contains('plugin')` substring check). Pattern alignment is real, not invented.
- **Verdict:** OK — substring is wider than ideal but matches established pattern in this codebase. Intent preserved: helper either resolves a docs-dir path or fails gracefully because path_provider is unbound.

### Test #11 (`defaultDesktopFilePath: deterministic OR fails consistently`)
- **Fix:** captures both `path1/path2` AND `err1/err2`; if both succeed, asserts equal paths; if both fail, asserts equal `runtimeType`.
- **REGRA #2 comment:** lines 349–356 — same root cause as #10. Intent (no partially-initialized state bug between two calls) preserved.
- **Verdict:** OK — same widening rationale, asserts determinism on either branch.

**REGRA #2 verdict overall:** all 4 fixture-fixes are legitimate test-runtime accommodations, NOT impl-conforming rewrites. Each comment explains the empirical failure mode, references the legacy pattern, and pins the intent. This is exactly the form REGRA #2 demands.

---

## W0.5-bis flagged items

### 1. `hide isNotNull, isNull` on the drift import (db_executor_test.dart:53)
**Verdict:** ACCEPTED. `package:drift/drift.dart` re-exports SQL builders called `isNotNull` / `isNull` that collide with `package:test`'s top-level matchers `isNotNull` / `isNull`. The collision is real and the test uses both `isA<QueryExecutor>` (drift type) and `isFalse`/`isNotNull` (test matchers). `hide` on the *narrower* import (drift) is the right call — `show` on `drift` would force enumerating dozens of symbols. SHOULD_FIX-tier alternative: `as drift` import alias. Not blocking — `hide` keeps the test concise and the collision is documented in the test file's comments.

### 2. Substring match in #10/#11 wider than ideal
**Verdict:** ACCEPTED. The substrings `'plugin' || 'Binding' || 'initialized'` cover both `MissingPluginException` and `FlutterError("Binding has not yet been initialized")`. Wider than ideal but matches the established pattern at `social_care_desktop_test.dart:455–505`. Intent preserved (helper either resolves or fails gracefully on unbound platform-channel). Tightening would require an integration test binding — explicitly deferred per the legacy test's `skip:` reason. NICE_TO_HAVE: extract the substring set into a shared `kPathProviderUnboundTokens` constant if more tests adopt this pattern.

### 3. `_ProbeDb` parallel with `CacheDatabase`
**Verdict:** LEGITIMATE TEST SCAFFOLD, not duplication. The `CacheDatabase` is a real production `GeneratedDatabase` with the cache schema baked in; using it inside `db_executor_test.dart` would couple the executor unit test to the cache schema (cross-concern). `_ProbeDb` is a deliberately-minimal shim (`allTables=[]`, `schemaVersion=1`) whose only purpose is to trigger `ensureOpen()`. The shim's docstring (lines 76–91) explicitly explains this. Acceptable; the duplication concern would only apply if `_ProbeDb` started carrying business state.

---

## W1 flagged items

### 1. `_ProductionFactory` delegating `:memory:` to `_InMemoryFactory.open()`
**Verdict:** CLEAN OWNERSHIP. The alternative — inlining `NativeDatabase.memory()` inside `_ProductionFactory.open` — would duplicate the call site and break the principle that `_InMemoryFactory` is the single owner of "how do I create a memory-backed executor". One extra method dispatch is a non-issue for an open-database call (which itself spawns an isolate or allocates SQLite handles). Documented in the factory's docstring (lines 41–44). Approved.

### 2. `defaultDesktopFilePath` as free function vs static on `DriftExecutorFactory`
**Verdict:** CORRECT SPLIT. The path helper has *no* dependency on the factory — it only knows about `path_provider`. Putting it as a static on `DriftExecutorFactory` would couple two orthogonal concerns. Co-locating it in `db_executor.dart` (same file, free function) keeps it discoverable for the composition root while signalling separation. NICE_TO_HAVE alternative: rename file to `db_composition.dart` to better describe the dual responsibility, or split into two files (`db_executor.dart` + `desktop_paths.dart`). Not blocking.

### 3. No barrel changes — new types stay internal
**Verdict:** ACCEPTABLE FOR D01. The barrel diff is empty (verified). Internal types (`PumpingSyncEngine`, `DriftExecutorFactory`, `defaultDesktopFilePath`, `resultsAreOnline`) are reachable only via internal paths. Tests already do this via `package:social_care_desktop/src/...` imports. Future external consumers (e.g. a hypothetical mock-injection harness in another package) would need the barrel widened — track in NICE_TO_HAVE.

### 4. 4 RED tests escalated as fixture issues, not refactor regressions
**Verdict:** CORRECT ANALYSIS. The 4 tests fail in their *original* form because of:
- Tests #5, #6: a Drift API contract (`LazyDatabase._delegate` is set by `GeneratedDatabase.ensureOpen()`, not by raw `runCustom` on the executor).
- Tests #10, #11: a Flutter binding fact (`flutter test` raises `FlutterError` before plugin channels probe).

Neither failure is caused by W1's refactor. The legacy private code (`_openDriftExecutor`, `_defaultPath`) had the exact same behavior — these tests would have been just as red against the legacy implementation. Treating them as fixture issues with REGRA #2 commentary is the correct verdict.

---

## Issues by severity

### MUST_FIX (block GREEN)
None.

### SHOULD_FIX (non-blocking — flag for follow-up)

1. **`_ProbeDb` could move to a shared test helper** (`test/_test_helpers/probe_db.dart`).
   - **Why:** Tests #5 and #6 instantiate it locally; if D02/D03 add more disk-backed executor tests they'll re-define the same shim. Promoting it to a shared helper avoids drift.
   - **Effort:** ~10 LoC move + import update in 2 tests.

2. **Doc link consistency.** `social_care_desktop.dart:166` doc-comment correctly references `[PumpingSyncEngine]` (the new public name). The file-level library docstring (lines 1–25) still talks about "pumping subclass" generically — fine, but a one-line cross-link to the new file would help discoverability. Optional.

### NICE_TO_HAVE (purely architectural polish)

1. **Barrel re-export of `DriftExecutorFactory`.** If a future ticket needs callers (e.g. integration tests in another package) to inject a custom factory, the public barrel will need `export 'src/facade/composition/db_executor.dart' show DriftExecutorFactory;`. Not needed today — current tests use the internal path import.

2. **H2 (Composition > Inheritance) follow-up:** when D6/D7 lands the SyncEngine Decorator/Observer split, `PumpingSyncEngine` becomes the textbook target — replace `extends SyncEngine` + `super.triggerDrain` with `final SyncEngine _inner` + `_inner.triggerDrain`. Out of scope for D01 per `000-request.md` "Não introduzir Strategy no SyncEngine — D7 reservado".

3. **Filename clarity.** `db_executor.dart` carries both the factory AND the unrelated `defaultDesktopFilePath`. Split into `db_executor.dart` + `desktop_paths.dart` if a future ticket adds more path-resolution helpers.

---

## Final recommendation

**APPROVED to W3 (quality gate).**

Behavior preserved bit-for-bit (verified against `git diff HEAD~1`). Surface pública intacta (`create()` only gains an *optional* parameter; barrel unchanged; sub-facades untouched). Encapsulation policy respected (H5 abstract interface class; H7 free functions; H9 interface across layers; H2 deferred to D6/D7 by design). Pattern-matching policy respected (P1 exhaustive; P5 no downcast). REGRA #2 exceptions in 4 fixture-fixed tests are legitimate, well-documented, and intent-preserving.

W3 should:
1. Verify `dart analyze` reports 0 issues on `apps/social_care_bff/desktop/`.
2. Verify `dart format` is clean.
3. Confirm `apps/social_care_bff/desktop/` test count matches the 450 GREEN +1 skip baseline (the 4 fixture-fixed tests should now be GREEN).
4. Confirm no regression on BFF Web (1137 GREEN preserved).

No round-2 needed.
