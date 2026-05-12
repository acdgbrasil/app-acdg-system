# Flutter-Expert Audit — BFF Comprehensive (2026-05-01)

## Executive summary
- **Overall verdict: STRONG (with focused gaps before A19 gate)**
- **Total findings: 1 CRITICAL, 7 MAJOR, 9 MINOR**
- **Top 3 highlights**
  1. Sealed-class discipline is exemplary across both BFFs — zero `as Success<T>`/`as Failure<T>` downcasts in production lib code; the analyzer rule (`acdg_lints/no_sealed_class_downcast`) is wired in `social_care_web` and the codebase passes it organically. P5 is a lived rule, not a slogan.
  2. P2 / P2b / flatMap-chained intent parsing is consistent across all 50 web intents. UUID gates short-circuit cleanly via `Result.flatMap`. The REGRA #2 retro fix in `team_handler` (test cheating in A15 → genuine 400 INVALID_GET_TEAM_MEMBER_PARAMS contract) is documented in the test source itself with an in-place mea culpa — exactly the cultural signal the policy aims for.
  3. Cross-layer Clock injection (H5) is faithfully applied through every desktop read/write use case, the 5 Drift caches, and the use-case staleness check. `abstract interface class Clock` (H6) prevents `super.now()` fallback bugs in fakes. `_ready = db.customSelect('SELECT 1').get()` in cache + outbox impls is a strong defensive pattern documented inline.

- **Top 3 concerns**
  1. **Dead production files referencing a deleted type.** `social_care_web/lib/src/handlers/health_handler.dart`, `social_care_web/lib/src/handlers/handler_utils.dart`, and `social_care_web/lib/src/remote/social_care_api_client.dart` (905 lines) all reference `SocialCareContract` which was deleted in A05. They are not exported from `social_care_web.dart` but they remain inside `lib/`, so the analyzer must be skipping them somehow OR they are actually broken and `melos run analyze` is masking them. Either way they need to go before A19.
  2. **`AppRouter` requires an `OidcServerClient` it never stores.** Constructor parameter is unused — DI smell + dead-code smell. Likely a leftover from a wiring iteration; the OIDC client is wired separately in `bin/server.dart`.
  3. **Lint discipline is uneven across the 3 packages.** `social_care_web` and `shared` enforce `empty_catches`, `exhaustive_cases`, `no_default_cases`, `unnecessary_lambdas`, `avoid_catching_errors`, `use_rethrow_when_possible`, plus `acdg_lints/no_sealed_class_downcast`. `social_care_desktop`'s `analysis_options.yaml` is the unmodified `package:lints/recommended.yaml` template. This is why the desktop facade can ship `} catch (_) {}` (close swallowing) without CI catching it. Onda 5 should harmonize.

---

## Methodology
- **Skill applied:** flutter-expert (`.claude/skills/flutter-expert/SKILL.md` — 25 non-negotiable rules) + ACDG handbook (Encapsulation H1–H9, Pattern Matching P1–P5/P2b, Concurrency C1–C3, Decision Heuristics H1–H6).
- **Files audited:** 347 non-generated Dart source files across the 3 packages — `bff/social_care_desktop/lib` (105 files), `bff/social_care_web/lib` (115 files), `bff/shared/lib` (127 files). 218 `*_test.dart` files surveyed (line counts + sampled patterns).
- **Approach:** structural sampling — read kernel + facade + every "shape-defining" file (sub-contracts, RemoteBase, every cache impl signature, SyncEngine, OutboxRepository, 6+ representative use cases per pattern, 6 representative intents, 4 handlers, 2 middlewares, OIDC client, session store). Then targeted greps for known anti-patterns: `as Success`, `as Failure`, `valueOrNull!`, `errorOrNull!`, `catch (_)`, `Impl`, `dynamic`, `DateTime.now()` in non-adapter layers, mocktail/`when(...)` test patterns, `mocktail` import, sealed-class subclasses, dead refs to `SocialCareContract`. No code modifications made.

---

## Findings

### CRITICAL (must fix before A19 gate)

#### C1 — Three production files in `social_care_web/lib/` import a deleted type (`SocialCareContract`)
**Files:**
- `bff/social_care_web/lib/src/handlers/health_handler.dart:10` — `typedef HealthContractFactory = SocialCareContract Function(Session session);`
- `bff/social_care_web/lib/src/handlers/handler_utils.dart:13` — `typedef ContractFactory = dynamic Function(Session session);` (also `dynamic` violation; see also M1)
- `bff/social_care_web/lib/src/remote/social_care_api_client.dart:14` — `class SocialCareApiClient implements SocialCareContract { ... }` (905 lines)

**Verification:** `grep -rn 'SocialCareContract' bff/shared packages/core_contracts` returned zero hits — the type was deleted in A05 (per `STATE.md` Onda 2 entry: "A05 — SocialCareContract god-interface deletada"). `social_care_web.dart` line 23 even acknowledges these files: *"Legacy handlers remain in-tree but are NOT exported — they depend on the removed `SocialCareContract` and will be migrated by A09–A15."* Onda 3 (A09–A15) is **closed**. The migration described did happen — but the dead files were never removed.

**Impact:** If these files compile (analyzer skipping them somehow, e.g., not exported), they are still dead weight that confuses future maintainers reading `lib/src/`. If they don't compile, then `melos run analyze` is currently broken or misconfigured for this package — which means an A19 "dart analyze zero issues" claim is unverifiable.

**Severity rationale: CRITICAL** — A19's gate is "dart analyze bff/ clean + delete legacy". This is the legacy. It cannot ship to A20 (Contract A doc) or A21 (final cleanup) with these still in tree.

**Remediation:** Delete the 3 files outright. They have no callers (the `app_router.dart` wires its own `_liveHandler/_readyHandler` directly and `buildAuthHandler` etc. compose from new use cases). Confirm `melos run analyze` is clean afterward.

---

### MAJOR (should fix in Onda 5 / Phase 4)

#### M1 — `AppRouter` requires an `OidcServerClient` parameter it never stores or uses
**File:** `bff/social_care_web/lib/src/server/app_router.dart:87`

```dart
AppRouter({
  required ServerConfig config,
  required SessionStore sessionStore,
  required OidcServerClient oidcClient, // <-- parameter, never stored
  required AuthContract authContract,
  ...
})
```

The constructor's `:` initializer list assigns 9 of the 10 `required` parameters into private fields; `oidcClient` is silently dropped. Caller in `bin/server.dart:19` constructs the client and threads it through. `AuthContract` (the wrapper around it) is what the auth handler uses.

**Severity rationale: MAJOR** — DI smell. Clients reading the constructor have to guess whether the `oidcClient` is being used or not. The Dart analyzer flags `unused_field` on private fields but does NOT flag unused constructor parameters that never become fields, so the lint chain never catches this.

**Remediation:** Drop the `OidcServerClient oidcClient` parameter from `AppRouter`. The wiring in `bin/server.dart` should keep building the client and use it where actually needed (inside the `AuthContract` impl construction).

---

#### M2 — Lint configuration drift across the three sub-packages
**Files:**
- `bff/social_care_web/analysis_options.yaml` — strict (empty_catches, exhaustive_cases, no_default_cases, unnecessary_lambdas, avoid_catching_errors, use_rethrow_when_possible, +`custom_lint`/`acdg_lints/no_sealed_class_downcast`)
- `bff/shared/analysis_options.yaml` — strict (same flags as web minus `custom_lint`)
- `bff/social_care_desktop/analysis_options.yaml` — **default template only** (no extras, no `custom_lint`)

**Concrete consequence:** the `} catch (_) {}` swallows on `bff/social_care_desktop/lib/src/facade/social_care_desktop.dart:244,247` (DB close error swallowing in `SocialCareDesktop.close()`) would be caught by `empty_catches` if applied. `social_care_web` only has 1 catch-with-rationale in `social_care_api_client.dart:50` (already destined for deletion per C1). `shared` has 1 in `time_stamp.dart:29` (string parsing, ISO8601 format) — also legitimately P2 territory but uses bare `catch (_)`.

**Severity rationale: MAJOR** — uneven lint floor means that the same bug class CAN ship in desktop but CANNOT ship in web. This is a process gap that A19 "dart analyze bff/" should harmonize. Single project-level analysis_options is the canonical fix per Dart guidance.

**Remediation:** Promote `bff/social_care_web/analysis_options.yaml` (or extract its `linter.rules` block into a shared yaml) and `include:` it from all three packages. `acdg_lints` plugin should also be wired in `social_care_desktop` so `no_sealed_class_downcast` enforces there too.

---

#### M3 — `SyncEngine` is a plain `class` while H6 prescribes `abstract interface class` for substitutable types
**Files:**
- `bff/social_care_desktop/lib/src/sync/engine/sync_engine.dart:42` — `class SyncEngine { ... }`
- `bff/social_care_desktop/lib/src/facade/social_care_desktop.dart:120` — `class _PumpingSyncEngine extends SyncEngine { ... }`
- `bff/social_care_desktop/test/use_cases/_fakes/fake_sync_engine.dart:35` — `class FakeSyncEngine extends SyncEngine { ... }`

**Concrete consequence:** `FakeSyncEngine` inherits SyncEngine's parent constructor — to build it, the test ships 6 `_Throwing*Contract` `noSuchMethod`-fakes just to satisfy the parent's `required` deps. The `triggerDrain`/`start`/`stop`/`close` overrides bypass the parent, but the bug-trap is real: any future test or production subclass that accidentally calls `super.triggerDrain()` will hit the real Drift queue. H6 was authored in DECISION_HEURISTICS.md *exactly* to prevent this.

**Severity rationale: MAJOR** — this is the canonical example H6 cites (`Clock`); the doc was added on 2026-04-30 right after A18b-v2. The same fix should apply to SyncEngine. Production's `_PumpingSyncEngine` already smells like a Decorator candidate (composition over inheritance — H1 rationale).

**Remediation:** Two paths.
- **Surgical (H1 inverse — eager refactor warranted because the pattern is canonical):** convert `SyncEngine` to `abstract interface class SyncEngine` with a `RealSyncEngine implements SyncEngine` (current body) and let `_PumpingSyncEngine` and `FakeSyncEngine` `implements SyncEngine` instead of `extends`. The 6 throw-away fakes go away (each composes directly).
- **Smaller (H1 surgical — keep ext for production but block extension in tests):** mark `SyncEngine` as `base class` and provide an `interface SyncEngineApi` for tests. Less idiomatic.

The first option is canonical Dart 3 + matches the Clock precedent.

---

#### M4 — `bff/social_care_desktop` declares `mocktail: ^1.0.4` in `dev_dependencies` but no test file imports it
**File:** `bff/social_care_desktop/pubspec.yaml:36`

**Verification:** `grep -rln 'package:mocktail' bff/social_care_desktop/test` returned zero hits. The codebase is consistently fake-first (FakeSyncEngine, FakeConnectivity, MockDio-via-noSuchMethod, in-memory Drift). The `mocktail` declaration is dead.

**Severity rationale: MAJOR** — Skill rule #8 ("Fakes for tests — never magic mocks", ADR-013). Having mocktail in pubspec is a temptation surface — a future contributor pulls it in, and the policy is undermined by precedent. Cleanup before A19 keeps the policy literal.

**Remediation:** Remove `mocktail` from `social_care_desktop/pubspec.yaml`. Run `dart pub get` to confirm nothing actually needed it.

---

#### M5 — Legacy `infrastructure/` exports remain in `shared/lib/shared.dart` and pull dead code into the public API
**Files:**
- `bff/shared/lib/shared.dart:39-46` — re-exports `patient_remote.dart`, `patient_overview.dart`, `patient_translator.dart`, `people_context_client.dart`
- `bff/shared/lib/src/infrastructure/mappers/{assessment_mapper,care_mapper,registry_mapper,protection_mapper,json_helpers}.dart` — exist but **NOT exported from `shared.dart`** and **not imported by any web/desktop file**
- The export comments themselves call this out: *"// Remote Models (legacy — to be replaced by contract DTOs)"*

**Verification:** `grep` confirms zero usage of `patient_translator/patient_remote/patient_overview/PatientOverview` from `bff/social_care_*` lib code. `packages/social_care/` (the Flutter app side) DOES still consume them — and per `git status`, packages/social_care has just deleted its own copies of `assessment_mapper`, `family_mapper`, `intervention_mapper`, `registry_mapper`. Phase 4 will finish the migration.

**Severity rationale: MAJOR (from BFF perspective) / DEFERRED (Phase 4 actually closes it)** — Onda 5 gate is "BFF clean"; the legacy export keeps `Cpf`, `Patient`, etc. legacy types exposed even where no caller uses them. The 5 `infrastructure/mappers/*.dart` files exist with no callers anywhere — pure dead code.

**Remediation in Onda 5:**
- Delete the 5 `infrastructure/mappers/*.dart` files (zero callers anywhere).
- Mark the 4 `infrastructure/dtos|patient_translator|people_context_client` exports as `@Deprecated('Phase 4 will replace via contract DTOs')` so app-side migration shows a yellow squiggle.
- Document in CONTRACT_A_PUBLIC_API.md (the A20 deliverable) that these exports are temporary.

---

#### M6 — `Cpf.create` error messages echo the input back to the caller (PII leak risk)
**File:** `bff/shared/lib/src/domain/kernel/cpf.dart:64,77,87,96`

```dart
return Failure(_buildError('CPF-005', "O CPF '$trimmed' contém caracteres inválidos."));
return Failure(_buildError('CPF-002', "O CPF '$trimmed' possui ${digits.length} dígitos. Esperado: 11."));
return Failure(_buildError('CPF-003', "O CPF '$trimmed' possui todos os dígitos iguais."));
return Failure(_buildError('CPF-004', "O CPF '$trimmed' possui dígitos verificadores inválidos.", ...));
```

**Concrete consequence:** PII discipline elsewhere (`pii_mask.dart`, `UuidPathParamError`, `_UpdateHousingConditionParseError`) is *strict* — never echo raw input. But `Cpf.create` echoes the raw (potentially-valid-but-tampered) CPF in `AppError.message`, and that message is observable via `AppError.toString()`, which in turn is plausibly serialized to logs/responses by adapters that haven't set up PII filtering. Today this is only called from tests + legacy `infrastructure/`, but if Phase 4 migrations adopt `Cpf.create` for client input validation, the leak surfaces immediately.

**Severity rationale: MAJOR (latent, time-bombed)** — the BFF web has a PII canon and this VO predates it. The adapter-to-API path doesn't currently invoke `Cpf.create` so the leak is theoretical today, but the consistent pattern would be to fix the source.

**Remediation:** Strip the raw `$trimmed` from CPF-002/CPF-003/CPF-004/CPF-005 messages. Use `maskCpf` from `social_care_web/observability/pii_mask.dart` (or move that helper to `shared`). The CPF code field already conveys *which* validation rule failed; the raw number adds nothing operationally.

---

#### M7 — `OutboxRepository` impl uses raw `DateTime.now()` for `lastAttemptAt` (H5 invariant gap)
**File:** `bff/social_care_desktop/lib/src/sync/outbox/outbox_repository.dart:235,252`

```dart
lastAttemptAt: Value(DateTime.now()),  // H5: should use injected Clock
```

The same impl receives no `Clock` in its constructor — the entire Clock injection chain (cache impls, use cases) bypasses the outbox. Today `lastAttemptAt` is **only stored, never read for staleness/retry decisions**, so the bug is dormant. But A18a's `RetryPolicy` doc in `retry_policy.dart` mentions using attempt count + (eventually) cooldown — when that lands, `lastAttemptAt` will be compared to `now()`, and a `FakeClock`-driven test will *seem* to pass while the impl uses wall clock.

**Severity rationale: MAJOR (latent — H5 gap that masks a future-bug, blocks deterministic backoff testing)** — the H5 doc spells out *exactly* this scenario (writer uses real clock, reader uses fake). The whole point of H5 is "if two layers compare timestamps, both produce them via the SAME injected clock".

**Remediation:** Add `Clock _clock` to `DriftOutboxRepository`, default `const SystemClock()`. Replace both `DateTime.now()` calls. Wire `effectiveClock` from the facade. (Same surgical edit pattern as the cache impls.)

---

### MINOR (nice-to-have, defer if low ROI)

#### m1 — `dynamic` typedef in `handler_utils.dart`
**File:** `bff/social_care_web/lib/src/handlers/handler_utils.dart:13` — `typedef ContractFactory = dynamic Function(Session session);`

`dynamic` is forbidden by the Skill ("No `any` — use `unknown` with narrowing" — analogous in TS, but the Dart equivalent is `Object?`). Resolved automatically when C1 deletes the file.

---

#### m2 — IIFE pattern in switch arms is repeated 50+ times in `social_care_web` use cases
**Files:** `discharge_patient_use_case.dart:34,43`; `login_use_case.dart:30,34`; many more.

```dart
return switch (result) {
  Success() => () {
    obs.breadcrumb('foo.completed');
    return Success<X>(...);
  }(),
  Failure(:final error) => () {
    obs.breadcrumb('foo.failed', data: ...);
    return Failure<X>(error);
  }(),
};
```

Equivalent imperative form would be:
```dart
switch (result) {
  case Success():
    obs.breadcrumb('foo.completed');
    return Success<X>(...);
  case Failure(:final error):
    obs.breadcrumb('foo.failed', data: ...);
    return Failure<X>(error);
}
```

Imperative is shorter, matches the rest of the codebase (handlers use imperative switch), avoids the `() { ... }()` syntactic hop.

**Severity rationale: MINOR** — purely stylistic; both compile to the same bytecode. But it's a 50+-callsite pattern ripe for unification with a small `tearOffSwitch` helper or just imperative switches. Note for A21 cleanup.

---

#### m3 — `RemoteBase.wrapResponse` and `extractIdResponse` use raw `DateTime.now()` for `meta.timestamp`
**File:** `bff/social_care_desktop/lib/src/remote/_shared/remote_base.dart:111,121,134`

The synthesized `ResponseMeta(timestamp: DateTime.now().toIso8601String())` is for a payload envelope, not a staleness decision — H5 not violated semantically. But the `RemoteBase` extends to all 7 remotes; threading a `Clock` through (or letting the use case provide it post-call) would make the response deterministic in tests.

**Severity rationale: MINOR** — currently no test asserts on `meta.timestamp`, so the gap is hypothetical. Defer to A21.

---

#### m4 — `_PumpingSyncEngine.triggerDrain` swallows `Failure(DrainSummary)` from `drainStream`
**File:** `bff/social_care_desktop/lib/src/facade/social_care_desktop.dart:140-145`

```dart
@override
Future<Result<DrainSummary>> triggerDrain() async {
  final result = await super.triggerDrain();
  switch (result) {
    case Success<DrainSummary>(:final value):
      if (!_drainController.isClosed) _drainController.add(value);
    case Failure<DrainSummary>():
      break; // intentionally not pumped
  }
  return result;
}
```

Documented intent: success-only stream, "so a flapping connection doesn't spam the UI with `Failure` events". Reasonable, but the policy is buried in a comment — not testable. UI consumers that *want* failure visibility have no hook. Consider an opt-in `Stream<Result<DrainSummary>>` or a separate `errorStream` rather than silently dropping.

**Severity rationale: MINOR** — design choice with rationale; not wrong but limits observability.

---

#### m5 — `RegisterPatientUseCase` calls `maskCpf(cpf);` (line 149) purely "to satisfy the lint"
**File:** `bff/social_care_web/lib/src/use_cases/register_patient_use_case.dart:148-149`

```dart
// Reference maskCpf to satisfy the "PII helpers are exercised" contract
// even when we don't log the CPF on the happy path — keeps the lint
// and the test import honest. No-op at runtime when cpf is null.
maskCpf(cpf);
```

Calling a function purely for its symbolic presence is a code smell. The lint should be neutralized differently — either remove the lint requirement, OR add an actual breadcrumb that emits `cpfMask: maskCpf(cpf)` so the masking is also exercised on the happy path.

**Severity rationale: MINOR** — cosmetic. Documents intent explicitly which is good. But it's the kind of thing future readers stumble over.

---

#### m6 — `time_stamp.dart` uses bare `catch (_)` for ISO parsing
**File:** `bff/shared/lib/src/domain/kernel/time_stamp.dart:29`

```dart
static Result<TimeStamp> fromIso(String iso) {
  try {
    final parsed = DateTime.parse(iso).toUtc();
    return Success(TimeStamp._(parsed));
  } catch (_) {
    return Failure(_buildError('TS-001', 'Formato de data inválido. Esperado ISO8601.', 'invalidDate', context: {'value': iso}));
  }
}
```

This is technically a P2/P2b boundary (parser of external string into VO). Per ADR-019 / P2b, the form should be `catch (e, st)` + (optional) observability call. Today this catches & loses the cause silently. The error message has the raw `iso` value in `context` though, which doubles as M6's PII concern (any string can be passed, including PII the dev intended to format).

**Severity rationale: MINOR** — `DateTime.parse` failures are informative for debug; not exposing the cause is a debug-friction smell, but this VO is in `domain/kernel` so the parse-error itself is rarely a security boundary.

---

#### m7 — `AddressDraftDto` constructor parameter order does not match field declaration order
**File:** `bff/shared/lib/src/contract/dto/requests/registry/register_patient_request.dart:163-205`

Constructor lists `isShelter, residenceLocation, state, city, cep, isHomeless = false, street, neighborhood, number, complement` while final fields are declared `cep, isShelter, isHomeless, residenceLocation, street, neighborhood, number, complement, state, city`. Equatable `props` follows the field order. Cosmetic but it makes review of `copyWith` (if added) error-prone.

**Severity rationale: MINOR** — pure style. Defer.

---

#### m8 — `dart_jsonwebtoken: ^3.0.0` declared in `social_care_web/pubspec.yaml` but no source file imports it
**File:** `bff/social_care_web/pubspec.yaml:29`

`grep -rn 'dart_jsonwebtoken\|JWT' bff/social_care_web/lib` returned no production hits. The OIDC client has its own JWT decoder (`parseIdTokenClaims` does manual base64 + jsonDecode). Either the dep is dead, or it's being saved for a future signature-verification path that hasn't landed.

**Severity rationale: MINOR** — unused dep is small bloat. If it's reserved for OIDC signature verification on production paths, document with a `# Reserved for ...` comment.

---

#### m9 — `Logger.root.info` direct calls in `ObservabilityContext.breadcrumb` use raw `data` map (PII discipline relies on caller)
**File:** `bff/social_care_web/lib/src/observability/observability_context.dart:119`

```dart
Logger.root.info('bc: $event requestId=$requestId data=$data');
```

`data` is `Map<String, Object?>`. Callers across handlers/use cases scrub PII (intent only emits masked fields), but if a future `breadcrumb('foo', data: {'patientCpf': cpf})` slips through, it's logged raw. Skill rule M9 territory — defense in depth. Consider wiring the existing `pii_mask.dart` helpers as a key-name-aware filter at the breadcrumb boundary (i.e., if key matches `/cpf|cns|email|name/i`, mask it).

**Severity rationale: MINOR** — current callers are disciplined. Risk mitigation only.

---

## Strengths (what's done well)

1. **Result<T> discipline is total in domain + application + use case layers.** Zero `throw` outside the OIDC adapter and 1 explicit `unreachable()` (P4-conformant). No `valueOrNull!` or `errorOrNull!` anywhere in production. Sealed-class exhaustive switching everywhere.

2. **No god-classes survive in the BFF surface.** Verified via line-counts and grep — every handler ≤ 376 lines, every use case ≤ 175 lines, every cache impl ≤ 215 lines. The 905-line `social_care_api_client.dart` is dead (see C1) — and even that one is structurally cohesive (one method per endpoint, no inheritance trees).

3. **H6 (`abstract interface class` Clock + `SystemClock implements Clock`) is faithfully applied across the desktop layer.** `Clock` is injected through every cache impl, every use case, the staleness policy, and tests use `FakeClock implements Clock`. The H6 bug-trap (accidentally `super.now()`) is structurally impossible.

4. **Drift cache impls share the exact same defensive pattern.** Every constructor fires `_ready = db.customSelect('SELECT 1').get()` and every public method `await _ready`, with a docstring explaining why (Drift's lazy-init quirk would mask DB-failure paths as `Success(null)`). This kind of *documented* invariant defense is rare and high-quality.

5. **Sealed mutation hierarchy in `sync_mutation.dart` is compiler-enforced exhaustive.** 28 mutations, each a `final class`, dispatched via switch in `SyncEngine._dispatch` — adding a 29th will break the build until the new arm is added, exactly as H4 prescribes.

6. **PII discipline in `social_care_web` is consistent.** `pii_mask.dart` (CPF, CNS, name) + `_scrubPath` for OIDC tokens in the observability middleware + private parse-error classes that never echo the input + `UuidPathParamError` carries only `fieldName` not raw input. `team_handler` test 590-614 explicitly asserts no echo. The discipline is testable, not aspirational.

7. **REGRA #2 retro fix in `team_handler_test.dart` is documented in-place** (lines 558-573). The mea culpa narrative ("the test was reshaped to pass instead of exposing the underlying invariant gap") is unique cultural signal — it teaches future contributors *why* the test exists.

8. **A23 UUID gate (`validateUuidPathParam`) + `flatMap` chaining** is consistent across all path-param-bearing intents. Strict v4 regex (rejects v1/v3/v5/NIL), trim+lowercase normalization, PII-safe error class. Single canonical entry point — exactly the H1 surgical-uniformity heuristic done right.

9. **Connectivity wiring (D5 γ) in `SocialCareDesktop.create` is contained and observable.** `FakeConnectivity` test fake exposes `hasListener` and `streamSubscriptionCount` so the contract "facade subscribes once and cancels on close" is testable. The fake even documents *why* it's a fake instead of a mocktail mock.

10. **Lint configuration in `social_care_web` and `shared` enforces P1/P2b rules** (`exhaustive_cases`, `no_default_cases`, `empty_catches`, `unnecessary_lambdas`, `acdg_lints/no_sealed_class_downcast`). The custom plugin is wired and active.

---

## Concrete recommendations for A19/A20/A21 (Onda 5 gate)

Ordered by ROI (highest first), targeting the 3 tickets:

### A19 — `dart analyze bff/` clean + delete legacy
1. **Delete C1 dead files** (`health_handler.dart`, `handler_utils.dart`, `social_care_api_client.dart`). Run `melos run analyze` and verify exit 0 across all 3 packages.
2. **Delete M5 dead mappers** (`infrastructure/mappers/{assessment,care,registry,protection,json_helpers}_mapper.dart` — zero callers anywhere).
3. **Remove M1 unused `OidcServerClient` parameter from `AppRouter`.**
4. **Remove M4 unused `mocktail` dev_dep** from `social_care_desktop/pubspec.yaml`. Optionally also m8 (`dart_jsonwebtoken` from web).
5. **Harmonize M2 lint floor** — make `social_care_desktop/analysis_options.yaml` mirror `social_care_web`'s strict block + wire `acdg_lints/no_sealed_class_downcast`. Re-run `dart analyze` and fix the (likely 2) `} catch (_) {}` close-swallows in the desktop facade.

### A20 — CONTRACT_A_PUBLIC_API doc
6. **Document M5's deprecation** — add an `## Appendix: Deprecated Re-exports (Phase 4 will remove)` section listing the 4 legacy exports and their replacement DTOs.
7. **Add an "Error code namespace contract" section** — codify what `team_handler.dart`'s dartdoc already states informally: `INVALID_*` are local-400 codes, `<PREFIX>-<NNN>` are upstream passthroughs, the two never collide.

### A21 — final cleanup
8. **Apply M3 surgically** — `SyncEngine` becomes `abstract interface class` + `RealSyncEngine`, `_PumpingSyncEngine` becomes a Decorator (`implements SyncEngine`, holds `final SyncEngine _inner`), `FakeSyncEngine` drops the 6 throw-away parent deps. This is a meaningful test-infrastructure simplification that pays back every future use-case test.
9. **Apply M7** — `Clock` injection into `DriftOutboxRepository`. Trivial in isolation, prevents a future flaky-test class.
10. **Apply M6** — strip raw CPF from `Cpf.create` error messages. This is the *one* domain-level change worth merging before Phase 4 starts consuming `Cpf.create` for client input validation.
11. **Apply m2 IIFE cleanup** — bulk replace the 50+ `() { ... }()` arms with imperative switches. Stylistic but worth one focused PR. Mechanical change; unlikely to introduce regressions.
12. **Apply m9 PII filter at breadcrumb level** — defense in depth so future undisciplined callers can't leak.

---

**Final verdict: STRONG.** Onda 4 closed at high quality. The 1 CRITICAL is a pure-deletion task, and the 7 MAJORs are all well-scoped to a single Onda 5 (A19-A21) sweep. After that sweep, the BFF will pass the gate cleanly and Phase 4 (Flutter migration) can rely on a stable, lint-clean, dead-code-free backend boundary.
