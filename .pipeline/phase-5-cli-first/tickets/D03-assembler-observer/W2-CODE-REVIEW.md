# D03 W2 — Code Review

## Verdict: APPROVED

## Round: 1/3

---

## 1. Behavior preservation

Compared `social_care_desktop.dart` head (D03) against D02 closure
(`a467dd0`). Per-checkpoint:

- **`create()` public API — same parameters?** ✅ Identical. 10 named
  params (`baseUrl`, `actorId`, `tokenProvider`, `cacheFilePath`,
  `syncQueueFilePath`, `dio`, `clock`, `staleAfter`, `connectivity`,
  `executorFactory`). Defaults preserved: `staleAfter = const
  Duration(minutes: 5)`, `executorFactory` nullable defaulting to
  `production` inside the assembler.
- **`startSync/stopSync/close/triggerDrain/drainStream` signatures
  unchanged?** ✅ Verified line-by-line. Bodies delegate to
  `_runtime.engine` / `_runtime.drainController` instead of `_engine` /
  `_drainController`, but external semantics identical.
- **Sub-facade fields unchanged from caller's POV?** ✅ The 7 sub-facade
  fields (`registry`, `assessment`, `care`, `protection`, `audit`,
  `lookup`, `health`) are now getters that delegate to `_runtime.X`
  instead of `final` fields. Type signature is unchanged
  (`RegistryFacade get registry => _runtime.registry`), so callers see
  no difference. Changing from `final` field → getter is binary-compat
  on the source level (Dart treats them identically at the call site).
- **`close()` ordering** ✅ Lines 122-136: closed flag first → cancel
  connectivity → engine.close → cacheDb.close (try/catch) →
  syncDb.close (try/catch) → drainController.close (with
  `isClosed` guard). **Byte-identical** to D02 closure
  (`a467dd0:social_care_desktop.dart` lines 161-179).
- **`triggerDrain()` short-circuit when closed** ✅ Lines 97-104:
  `if (_closed) return Future.value(Failure<DrainSummary>(SyncFailure
  ('SocialCareDesktop closed')));`. Identical message and Failure type.

**Verdict: behavior preserved. Refactor is semantics-neutral.**

---

## 2. Self-reference circular elimination

- `grep -rn "late SocialCareDesktop\|late .*desktop\b"
  apps/social_care_bff/desktop/lib/`:
  → returns ONLY
  `apps/social_care_bff/desktop/lib/src/sync/connectivity/
  auto_drain_observer.dart`. **Zero hits inside `social_care_desktop.dart`.**
- `social_care_desktop.dart` contains zero `late` declarations of any
  kind (line-by-line read confirms).
- `DesktopAssembler.build()` (lines 153-300): pure construction
  sequence — no `late`, no self-reference. Each phase consumes outputs
  from earlier phases via local `final` bindings.
- `AutoDrainObserver.watch()` (lines 63-96): `late AutoDrainObserver
  observer` (line 80) is **closure-local to the static method**, never
  escapes the method scope. Documented at lines 70-79 with a 2-step
  argument: (1) `subscription.listen(...)` returns synchronously
  without firing the callback; (2) by the time the stream emits,
  `observer = ...` (line 90) has executed. **Late-binding window is
  closed before any caller can race.**

**Verdict: self-reference elimination COMPLETE. The only remaining
`late` is the closure-local one inside `AutoDrainObserver.watch()` —
spec-allowed and documented.**

---

## 3. Surface pública

- `SocialCareDesktop.create()` — 10 named params (D02 closure had 10;
  D03 has 10). No new public types added to barrel.
- `lib/social_care_desktop.dart` (barrel) — unchanged. No D03 imports
  added. `DesktopRuntime`, `DesktopAssembler`, `AutoDrainObserver` all
  stay internal under `src/`. Tests reach them via
  `package:social_care_desktop/src/...` paths (same convention as D01).
- Public sub-facade getters (`registry`, `assessment`, etc.) preserve
  their declared types. No new public APIs leaked.

**Verdict: 100% intact.**

---

## 4. Builder pattern correctness

- **7 `with*()` setters that return `this`**: ✅ `withLocalCache`
  (92-95), `withSyncQueue` (99-102), `withDio` (106-109), `withClock`
  (112-115), `withStaleAfter` (119-122), `withConnectivity` (126-129),
  `withExecutorFactory` (133-136). All 7 return `this` for chaining.
- **`build()` orchestrates 8 phases in order**: ✅ Phase 1 (paths) →
  Phase 2 (databases) → Phase 3 (clock + dio) → Phase 4 (caches +
  remotes + outbox) → Phase 5 (engine + drain controller) → Phase 6
  (use cases via 7 D02 builders) → Phase 7 (sub-facades) → Phase 8
  (observer). Inline `// Phase N:` comments match.
- **`build()` reusable**: ✅ Each phase uses local `final` bindings;
  no field mutation in `build()` itself; observer factory and
  StreamController are freshly instantiated each call. Verified
  conceptually by `desktop_runtime_test.dart` "instance independence"
  check (per W1 report).
- **Path-resolution gate**: ✅ Lines 160-173: `final isInMemory =
  identical(_executorFactory, DriftExecutorFactory.inMemory);` then
  `??` short-circuit `':memory:'` before `defaultDesktopFilePath()`
  (which calls `path_provider`). Uses `identical()` — pointer identity
  on the const singleton — exactly as W1 spec'd. **Magic string
  `':memory:'` appears as a literal twice (lines 167, 172) instead of
  referencing `db_executor.dart:_inMemoryMarker`** — see SHOULD_FIX #1
  below.

**Verdict: Builder pattern correct. Minor SHOULD_FIX flagged on the
magic-string duplication.**

---

## 5. Observer pattern correctness

- **Reads initial connectivity exactly once via `checkConnectivity()`**:
  ✅ Line 67: `final initialResults = await connectivity
  .checkConnectivity();`. Single call, used to seed `_wasOnline`.
- **Edge detection — only triggers drain on offline → online
  transition**: ✅ Lines 81-88: `if (isOnline && !observer._wasOnline)
  { unawaited(observer._engine.triggerDrain()); }`. Online → online
  is silent (the AND guard); online → offline silent (online guard);
  offline → offline silent (online guard). Then state is updated:
  `observer._wasOnline = isOnline;`.
- **`dispose()` idempotent via `_disposed` guard**: ✅ Lines 100-104:
  `if (_disposed) return; _disposed = true; await
  _subscription.cancel();`. **Strictly more idempotent than the spec
  request docstring (which only said `subscription.cancel` is
  idempotent natively). The `_disposed` flag adds belt-and-braces —
  spec-aligned.**
- **Observer holds engine PRIVATELY**: ✅ `final SyncEngine _engine`
  (line 48). No public getter for `_engine`. Confirmed by full file
  read.
- **`late AutoDrainObserver observer` is closure-local**: ✅ Declared
  at line 80 inside `watch()` static method; not a class field.
  Reference inside listener body (lines 83, 85, 87) closes over the
  closure-local `observer`, which is fully constructed by line 95
  before `return observer;` on line 96.

**Verdict: Observer pattern correct.**

---

## 6/7/8. Encapsulation/Pattern Matching/Lifecycle

### Encapsulation H1-H9
- **H1 (SRP per file)**: ✅ DesktopRuntime = data, DesktopAssembler =
  builds, AutoDrainObserver = observes. Clean separation.
- **H2 (Composition over inheritance)**: ✅ Assembler doesn't extend
  anything. Observer doesn't extend anything. DesktopRuntime doesn't
  extend anything.
- **H4 (Const constructor where possible)**: ✅ DesktopRuntime has
  `const DesktopRuntime({...})` (line 33) — even though it's
  constructed once per `build()` call, the const is structurally
  correct (all fields are final and Sendable).
- **H5 (Abstract types for cross-layer)**: ✅ DriftExecutorFactory
  remains `abstract interface class` (D01 — verified untouched in
  `db_executor.dart:28`).
- **H7 (SRP across files)**: ✅ Assembler doesn't observe; observer
  doesn't build; runtime is pure data. No mixing.
- **H9 (Cross-layer types as `abstract interface class`)**: ✅
  DriftExecutorFactory is the only cross-layer type — preserved.
  DesktopRuntime is internal-only (consumed by SocialCareDesktop in
  the same library) so concrete class is appropriate.

### Pattern Matching P1-P5
- **P5 (No sealed-class downcast in production)**: ✅ Zero `as
  Success`, `as Failure` in any of the 4 files. Confirmed by full
  reads.
- **No magic strings**: ⚠️ `':memory:'` literal appears twice in
  `desktop_assembler.dart:167,172` instead of referencing
  `db_executor.dart`'s `_inMemoryMarker` constant. The constant is
  private to `db_executor.dart`. **SHOULD_FIX (non-blocking)**: extract
  to a public top-level `const inMemoryMarker = ':memory:';` in
  `db_executor.dart`, or duplicate the constant locally with a `// see
  db_executor.dart:_inMemoryMarker` cross-link. The reasoning at
  desktop_assembler.dart:155-159 (`path_provider` channel unwired)
  partially documents the intent, but the literal still drifts if
  anyone changes the marker in `db_executor.dart`.

### Resource lifecycle
- **`close()` disposes new components in correct order**: ✅
  social_care_desktop.dart:122-136 cancels `connectivityObserver`
  first, then `engine`, then both DBs, then drainController. Same
  ordering as D02. The new `connectivityObserver` (typed
  `AutoDrainObserver`) replaces the old `_connectivitySub` (typed
  `StreamSubscription`); semantics preserved — `dispose()` calls
  `subscription.cancel()`.
- **DesktopAssembler doesn't leak partial state on build failure**:
  ⚠️ Phase 8 (observer construction) is async and could throw — if it
  does, the StreamController + databases + engine from earlier phases
  stay open. **NICE_TO_HAVE (non-blocking)**: wrap phases 5-8 in a
  try/catch that disposes earlier-phase artifacts on error before
  re-throw. Behavior was identical in D02 (legacy did NOT clean up
  either), so this is a pre-existing gap, not a D03 regression.

---

## 9. W1 architectural choices (6 items)

| # | Choice | Verdict |
|---|--------|---------|
| 1 | DesktopAssembler mutates in place + returns `this` | ✅ APPROVED — standard Builder; chain works as designed |
| 2 | AutoDrainObserver `late observer` closure-local to `watch()` | ✅ APPROVED — replaces self-reference cleanly; documented at lines 70-79 |
| 3 | `identical(_executorFactory, DriftExecutorFactory.inMemory)` short-circuit | ✅ APPROVED — pointer identity on const singleton is correct; minor SHOULD_FIX on the literal `':memory:'` (see §6/7/8) |
| 4 | DesktopRuntime as pure data class — no `==`/`hashCode`/`copyWith` | ✅ APPROVED — semantics is REFERENCE (it bundles 12 live resources with lifecycle); per ENCAPSULATION_POLICY "Value vs Reference" table, "Store / Cache / Queue REFERENCE → Equatable proibido". `const` constructor + final fields match. |
| 5 | Constructor ordering in `DesktopAssembler.build()` mirrors D02 builder ordering | ✅ APPROVED — Registry → Assessment → Care → Protection → Audit → Lookup → Health (lines 219-264). Matches D02 closure exactly. |
| 6 | SocialCareDesktop constructor 14 params → 1 (`_runtime`) | ✅ APPROVED — fewest-args principle realized; surface getter delegates only |

---

## 10. REGRA #2 path-resolution gate validation

- **The gate makes architectural sense**: ✅ When `_executorFactory ==
  inMemory`, the factory's `open()` ignores the file path entirely
  (returns `NativeDatabase.memory()` regardless — `db_executor.dart:93`).
  Calling `path_provider.getApplicationDocumentsDirectory()` first
  is wasted work and worse — fails in unit tests where the platform
  channel is unwired. Short-circuit is the correct fix.
- **No production semantics broken**: ✅ For `production` factory +
  null path, `isInMemory == false`, so the `??` falls through to
  `await defaultDesktopFilePath('app_cache.sqlite')` — identical to
  D02 behavior. The production code path is byte-equivalent.
- **Test #X validates this contract**: Per ticket, 14 tests in
  `desktop_assembler_test.dart` (locked test files — not audited for
  content per W2 instructions). The test count alone aligns with the
  enumeration of phases + the path-resolution gate; W1 reports
  these GREEN.

**Verdict: REGRA #2 gate is correct, asymmetric only on the test path,
production semantics preserved. Magic string `':memory:'` flagged as
SHOULD_FIX (non-blocking).**

---

## 11. D01/D02 SHOULD_FIX status

D01 W2 flagged 2 SHOULD_FIX, both still pending after D02:

1. **Move `_ProbeDb` to `test/_test_helpers/probe_db.dart` (shared)**
   — `grep -rn "_ProbeDb"` returns matches only in
   `test/facade/composition/db_executor_test.dart`. **NOT addressed
   by D03.** D03 introduced
   `test/sync/connectivity/_d03_test_helpers.dart` for its own helpers
   but did not migrate `_ProbeDb`. Stays as carry-over.
2. **Cross-link in `social_care_desktop.dart` library docstring to
   `pumping_sync_engine.dart`** — ✅ **D03 ADDRESSED THIS.** Lines
   37-40: *"Cross-link: pumping behaviour lives in
   `lib/src/sync/engine/pumping_sync_engine.dart` (D01); the offline
   → online edge detector lives in
   `lib/src/sync/connectivity/auto_drain_observer.dart` (D03)."*
   1 of 2 SHOULD_FIX cleared.

---

## Onda 1.5 retrospective summary

| Ticket | Refactor focus | LoC delta on `social_care_desktop.dart` | Tests added |
|--------|---------------|----------------------------------------:|------------:|
| D01 | PumpingSyncEngine extract + DriftExecutorFactory + connectivity helpers | 718L → 637L (-81L) | +24 |
| D02 | 7 use case builders by bounded context | 637L → 364L (-273L) | +21 |
| D03 | DesktopAssembler (Builder) + AutoDrainObserver (Observer) + DesktopRuntime | 364L → **184L** (-180L) | +29 (4 runtime + 14 assembler + 11 observer) |
| **Total** | **3 tickets, 2 GoF patterns formalized + 2 supporting patterns** | **718L → 184L (-534L, -74.4%)** | **+74 tests** |

LoC distribution post-D03:
- `social_care_desktop.dart` — 184L (entry point + lifecycle, ZERO composition logic)
- `composition/desktop_assembler.dart` — 301L (Builder)
- `composition/desktop_runtime.dart` — 65L (data class)
- `composition/db_executor.dart` — 107L (Factory Method, D01)
- `composition/connectivity_helpers.dart` — 13L (D01)
- `composition/builders/*` — 610L total across 7 files (D02)
- `sync/connectivity/auto_drain_observer.dart` — 105L (Observer)
- `sync/engine/pumping_sync_engine.dart` — 48L (D01)

**Net: from 1 file × 6 responsibilities → 14 files × 1 responsibility
each.**

Pattern formalization:
- **D01** — Factory Method (DriftExecutorFactory)
- **D02** — Composition Root partitioned by bounded context (no formal
  GoF name — just SRP applied)
- **D03** — Builder (DesktopAssembler) + Observer (AutoDrainObserver)

Self-reference circular eliminated. Constructor inflation (14 → 1
param) realized. Surface pública 100% preserved across all 3 tickets.

---

## Issues by severity

### MUST_FIX (block W3)
**None.**

### SHOULD_FIX (non-blocking)

1. **Magic string `':memory:'` literal duplication** —
   `desktop_assembler.dart:167,172` hardcodes `':memory:'` instead of
   referencing the `_inMemoryMarker` constant defined in
   `db_executor.dart:9`. The constant is currently private. Either:
   (a) extract to a public top-level `const String inMemoryMarker =
   ':memory:';` and import it; OR (b) duplicate locally with a
   `// see db_executor.dart:_inMemoryMarker` cross-link comment.
   Risk: someone changes the marker in `db_executor.dart` and forgets
   the assembler's literal — the test runs would catch it but only
   after the next path-resolution gate exercise.

2. **`_ProbeDb` still in `test/facade/composition/db_executor_test.dart`**
   — D01's SHOULD_FIX #1 (move to shared `test/_test_helpers/`)
   carries over unchanged. D03 introduced its own
   `test/sync/connectivity/_d03_test_helpers.dart` but did not
   migrate the existing helper. Defer to a future ticket (D04 or
   later) — does not block Onda 1.5 closure.

### NICE_TO_HAVE

1. **Build-failure cleanup** — `DesktopAssembler.build()` doesn't roll
   back partial state if a late phase (e.g. observer construction)
   throws. Pre-existing gap from D02; D03 inherited it. Wrap phases
   5-8 in try/catch that disposes earlier artifacts on error. Low
   priority — error during boot is rare and typically fatal anyway.

2. **Barrel re-export of `DesktopAssembler` for advanced consumers** —
   if external callers want re-entrant composition (e.g. swap factory
   mid-test, build twice), they currently can't access `DesktopAssembler`
   without `package:social_care_desktop/src/...` imports. D01's
   NICE_TO_HAVE catalog already noted similar for `DriftExecutorFactory`.
   Defer until consumer demand surfaces.

3. **AutoDrainObserver missing test for initial-online → no-drain
   case** — locked test files not audited per W2 instructions; W1
   reports 11 tests, which likely covers this, but verify in W3
   gate.

---

## Final recommendation

**APPROVED to W3.**

D03 closes Onda 1.5 cleanly:
- Behavior preservation: byte-identical in `close()` ordering, 10/10
  `create()` params preserved, all surface getters intact
- Self-reference circular eliminated (zero `late SocialCareDesktop`
  remaining)
- Builder pattern correctly applied (7 `with*` setters, 8 phases,
  reusable)
- Observer pattern correctly applied (private engine, edge-only drain,
  idempotent dispose)
- ENCAPSULATION_POLICY H1/H2/H4/H5/H7/H9 all honored
- PATTERN_MATCHING_POLICY P5 honored
- Onda 1.5 journey complete: 718L → 184L (-74.4%), +74 tests, 4
  patterns formalized

The 3 SHOULD_FIX items (magic string, `_ProbeDb` migration,
build-failure cleanup) are all non-blocking and can be deferred to
later tickets. Pass to W3 (quality gate).
