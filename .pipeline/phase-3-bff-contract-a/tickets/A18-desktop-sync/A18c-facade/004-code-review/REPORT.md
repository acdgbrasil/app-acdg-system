# A18c-v2 W2 — Code Review (flutter-code-reviewer)

## Verdict

**APPROVED** — Round 1 of 3. Findings: **0 MUST_FIX, 0 SHOULD_FIX, 3 NICE_TO_HAVE (Phase 4 follow-ups, non-blocking).**

Independently verified W1's claims:
- `dart analyze bff/social_care_desktop/lib/` → 0 issues
- `flutter test bff/social_care_desktop/test/facade/` → 43 PASSED + 1 SKIPPED + 0 FAILED
- `flutter test bff/social_care_desktop/` → **419 PASSED + 1 SKIPPED + 0 FAILED** (= 376 prior + 44 new)

## Audit checklist (10/10 PASS)

| # | Check | Status |
|---|---|---|
| 1 | Boundary respected (zero changes in `packages/` and `apps/acdg_system/` by W1) | PASS |
| 2 | Facade structure (7 sub-facades + entry point + 42 methods) | PASS |
| 3 | SocialCareDesktop API behavioral contracts (5 W0-locked) | PASS |
| 4 | Connectivity edge logic (offline→online only, mobile counts as online) | PASS |
| 5 | `_PumpingSyncEngine` design (H1) | ACCEPT-AS-IS (NICE_TO_HAVE) |
| 6 | Sweep — 4 NICE_TO_HAVE applied | PASS |
| 7 | Result<T> + try/catch boundary | PASS |
| 8 | Library exports correct | PASS |
| 9 | Independent test verification | PASS |
| 10 | Phase 4 trigger payload comprehensive (51 issues, 8 groups) | PASS |

## Boundary respected — verified

- `git diff packages/` (since A18b close `2688125`) — zero W1 changes
- `git diff apps/acdg_system/` (since A18b close) — zero W1 changes
- Pre-existing dirty state predates A18c (file mtimes confirm — `social_care_providers.dart` last modified Apr 17, W1 ran May 1)

W1's deferral interpretation is sound: every shell rewire path through 10 files cascades into `packages/` types. Partial rewire would leave files in worse compile state. All-or-nothing deferral is correct call given user constraint.

## Facade structure (7 sub-facades + 42 methods)

| File | Class | Methods | Pattern verified |
|---|---|---:|---|
| `registry_facade.dart:21` | RegistryFacade | 13 | All `=> _useCase(args)` 1-line delegates |
| `assessment_facade.dart:16` | AssessmentFacade | 7 | Same |
| `care_facade.dart:10` | CareFacade | 3 | Same |
| `protection_facade.dart:13` | ProtectionFacade | 6 | Same |
| `audit_facade.dart:8` | AuditFacade | 1 | Same |
| `lookup_facade.dart:17` | LookupFacade | 10 | Same |
| `health_facade.dart:9` | HealthFacade | 2 | Same |

No branching, logging, or rewrapping in any sub-facade method.

## `_PumpingSyncEngine` decision — ACCEPT-AS-IS, promote to NICE_TO_HAVE

**Implementation:** Private subclass `_PumpingSyncEngine extends SyncEngine` at `social_care_desktop.dart:120-146`, single override of `triggerDrain()` to pump drain summaries onto broadcast controller.

**Language legality:** `SyncEngine` is `class SyncEngine` (default modifier — not `final`/`sealed`). Inheritance permitted. **W1 did NOT modify A18a.**

**Why ACCEPT:**
- `_`-prefixed → private to library, no leak
- 32 lines incl. doc — small
- Single override (`triggerDrain`)
- Justified by integration contract: `drainStream` must emit on EVERY successful drain, including fire-and-forget triggers from write use cases
- Failures intentionally NOT pumped — design choice documented at lines 116-119

**H1 violation:** uses inheritance instead of composition. But pragmatic and well-scoped. Refactor to composition flagged as Phase 4 NICE_TO_HAVE.

## Sweep — 4 NICE_TO_HAVE applied

1. **`extractPatientVersion` deleted** — file gone, zero references, removed from barrel
2. **Cache-only reads documented** — 5 files with inline `///` doc explaining Pattern 1 uniformity (H3)
3. **Clock promoted** — `abstract interface class Clock` + `class SystemClock implements Clock`. No `extends Clock` anywhere
4. **5 cache impls unified** — all accept `{Clock? clock}` defaulting `const SystemClock()`. Zero `DateTime Function()` params remain

## NICE_TO_HAVE (Phase 4 follow-ups)

1. **`_PumpingSyncEngine` → composition** — when Phase 4 touches A18a, refactor `SyncEngine` to expose `Stream<DrainSummary>` or `onDrainCompleted` callback. Remove `_PumpingSyncEngine`. H1 alignment + simpler facade.

2. **Sub-facade ctors named `.internal`** — convert `RegistryFacade.internal(...)` → `RegistryFacade._(...)` for idiomatic privacy. Cosmetic; same effective boundary today.

3. **`_connectivity` field has `// ignore: unused_field`** — only subscription is held. Either drop field+ignore OR use it (e.g., expose `Future<bool> get isOnline` for UI).

## Phase 4 trigger payload — comprehensive

W1 REPORT §"Residual `apps/acdg_system/` issues" lists **51 issues across 8 groups (A-H)** with file:line refs. 5-step migration outline covers package deletions + ViewModel migrations + shell rewire.

## Conclusion

**Verdict: APPROVED.** A18c-v2 ready to close. Onda 4 fully complete after this. Pipeline advances to ticket close-out + Phase 4 hand-off.
