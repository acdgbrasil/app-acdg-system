# A18c-v2 W1 — GREEN Implementation (flutter-bff-implementer)

**Status:** GREEN complete (2026-05-01). 43/44 facade tests + 1 skipped (path_provider gate, intentional). Full BFF Desktop suite **420/420** (419 + 1 skip). `dart analyze lib/` zero issues.

**IMPORTANT — Shell rewire deferred entirely:** Implementer interpretation of user constraint (no packages/ modifications) → since 100% of shell rewire paths cascade into `packages/social_care/` types, partial rewire would leave files in worse state. Shell stays in pre-W1 51-issue state; **all 51 issues become Phase 4 trigger payload**.

## Files created (BFF Desktop — facade layer)

### Sub-facades (private `.internal` ctor, all methods are `=> _useCase(args)`)
- `lib/src/facade/sub_facades/registry_facade.dart` (13 methods)
- `lib/src/facade/sub_facades/assessment_facade.dart` (7)
- `lib/src/facade/sub_facades/care_facade.dart` (3)
- `lib/src/facade/sub_facades/protection_facade.dart` (6)
- `lib/src/facade/sub_facades/audit_facade.dart` (1)
- `lib/src/facade/sub_facades/lookup_facade.dart` (10)
- `lib/src/facade/sub_facades/health_facade.dart` (2)

**Total: 42 surface methods.**

### Entry point + library exports
- `lib/src/facade/social_care_desktop.dart` (NEW; ~520 LoC including `_PumpingSyncEngine` private subclass)
- `lib/social_care_desktop.dart` (UPDATED — 8 facade exports + re-exports `Result`/`Success`/`Failure`)

## Sweep — 4 NICE_TO_HAVE applied

1. **`extractPatientVersion` deleted** (zero callers verified). File removed; export deleted.

2. **Cache-only read use cases — inline `///` doc** on `Clock`/`staleAfter` ctor params (Pattern 1 uniformity per H3, used in Phase 6+). Touched 5 files, no code change.

3. **Clock promoted to `abstract interface class`** (H6):
   ```dart
   abstract interface class Clock { DateTime now(); }
   class SystemClock implements Clock { const SystemClock(); @override DateTime now() => DateTime.now(); }
   ```

4. **5 cache impls** switched from `DateTime Function()? now` → `Clock? clock` (default `const SystemClock()`). Test helper updated.

## Behavioral implementation notes

- **`_PumpingSyncEngine`** (private subclass of `SyncEngine` inside `social_care_desktop.dart`) overrides `triggerDrain()` to pump every successful `DrainSummary` onto the broadcast `drainController`. Required because integration E2E test asserts that fire-and-forget triggers from write use cases also surface on `drainStream`. **Open question for W2:** is this acceptable, or should `SyncEngine` (A18a) expose an injectable `onDrainCompleted` callback per H1 (composition over inheritance)? Private + small + tightly scoped — flagging for review.

- **Connectivity wiring**: subscription created late so closure can capture constructed instance ref. Boot-time `_wasOnline` seeded from `connectivity.checkConnectivity()` so first online event after offline = edge.

- **Lifecycle teardown ordering** (`close()`): cancel connectivity sub → close engine → close cache DB → close sync DB → close drain controller. Idempotent via `_closed` flag.

- **`drainStream` is `.broadcast`** (multiple subscribers OK).

## Test result

```
flutter test test/facade/
=> 43 PASSED, 1 SKIPPED (path_provider gate), 0 FAILED

flutter test (full Desktop suite)
=> 419 PASSED, 1 SKIPPED, 0 FAILED  (= 376 prior + 44 new)
```

Skipped test: `default-paths factory uses path_provider when cacheFilePath/syncQueueFilePath are null` — explicitly skipped via `skip:` in W0; impl DOES delegate to `path_provider.getApplicationDocumentsDirectory()` when paths null.

## Analyze

- `dart analyze lib/` → **0 issues**
- `dart analyze` (incl. tests) → 0 errors, 2 warnings (test-owned `unused_import` in W0 test files — REGRA #2 forbids modifying), 108 infos (pre-existing test-only)

## Shell rewire — DEFERRED to Phase 4

### Decision rationale

Per locked constraint (memory `feedback_packages_user_owned.md`, A18c STATE 2026-05-01): "Não faça nada que seja relacionado a packages". Every shell rewire path through the 10 files cascades into `packages/social_care/` or `packages/core/core_offline.dart` types. **Partial rewire = file still broken** (group A "SocialCareBffRemote" can be replaced with `SocialCareDesktop`, but groups B-G reference packages/ types that can't be touched). All-or-nothing was the right call.

### Apps analyze count: 51 issues, IDENTICAL to pre-W1 baseline

ZERO regression, ZERO improvement. All 51 are Phase 4 trigger payload.

### Residual `apps/acdg_system/` issues — Phase 4 trigger payload

**A. `SocialCareBffRemote` (deleted in A16-v2):**
- `apps/acdg_system/integration_test/staging_integration_test.dart:104`
- `apps/acdg_system/lib/logic/di/infrastructure_providers.dart:39, 105`
- `apps/acdg_system/lib/logic/di/dependency_builders.dart:23, 56`

**B. `SocialCareContract` (god-interface in `packages/social_care/`):**
- `apps/acdg_system/lib/logic/di/infrastructure_providers.dart:78, 131`
- `apps/acdg_system/lib/logic/di/dependency_builders.dart:47`

**C. `OfflineFirstRepository` (composition wrapper in `packages/social_care/`):**
- `apps/acdg_system/lib/logic/di/infrastructure_providers.dart:99, 111`
- `apps/acdg_system/lib/logic/di/dependency_builders.dart:62`

**D. `LocalSocialCareRepository` (legacy local repo in `packages/social_care/`):**
- `apps/acdg_system/lib/logic/di/dependency_manager.dart:41, 73, 87`
- `apps/acdg_system/lib/logic/di/app_providers.dart:32`
- `apps/acdg_system/lib/logic/di/dependency_builders.dart:17, 50`

**E. `LegacyPatientService` (deprecated in `packages/social_care/`):**
- `apps/acdg_system/lib/logic/di/social_care_providers.dart:7, 9`

**F. OLD `SyncEngine` API surface (from `packages/core/core_offline.dart` — methods `status`, `pullPatients`, `refreshStatus`, `forceSyncNow`, `processQueue`):**
- `apps/acdg_system/lib/logic/router/app_router.dart:79`
- `apps/acdg_system/lib/ui/pages/home_page.dart:58`
- `apps/acdg_system/lib/ui/organisms/sync_detail_panel.dart:115, 116, 138, 139, 147, 148, 154`

**G. NEW `SyncEngine` constructor signature mismatch (apps still passes OLD-API named params):**
- `apps/acdg_system/lib/logic/di/dependency_builders.dart:30-34`
- `apps/acdg_system/lib/logic/di/infrastructure_providers.dart:59-64`

**H. Warning:**
- `apps/acdg_system/lib/logic/di/app_providers.dart:5` — `unused_import: package:social_care_desktop/social_care_desktop.dart`

### Phase 4 migration outline (for the user)

Removing the residual issues requires (in `packages/social_care/`):
1. Delete `SocialCareContract` (god-interface)
2. Delete `OfflineFirstRepository`, `BffPatientRepository`, `BffLookupRepository`, `LegacyPatientService`, `LocalSocialCareRepository`, `HttpSocialCareClient`
3. Migrate the 11+ ViewModels (`PatientRegistrationViewModel`, `FamilyCompositionViewModel`, `HealthStatusViewModel`, `HousingConditionViewModel`, etc.) to consume `SocialCareDesktop.{registry,assessment,care,protection,audit,lookup,health}` directly
4. Delete OLD `SyncEngine` from `packages/core/core_offline.dart`; migrate `SyncIndicator` + `SyncDetailPanel` to `SocialCareDesktop.drainStream` + `triggerDrain`
5. Then rewire 10 shell files in `apps/acdg_system/` (DI providers + sync_detail_panel + home_page + app_router + integration_test + pubspec)

The BFF-side surface (`SocialCareDesktop` + 7 sub-facades + 42 methods + sync state) is **READY TO BE CONSUMED** once Phase 4 lands.

## Boundary infraction audit — zero violations

- ANY file under `packages/`: NOT TOUCHED.
- ANY file under `apps/acdg_system/`: NOT TOUCHED.
- W0 test files in `bff/social_care_desktop/test/facade/`: NOT TOUCHED (REGRA #2 honored).

## REGRA #2 ambiguities surfaced

**Zero.** W0 contracts unambiguous. The single design choice (`_PumpingSyncEngine` subclass for drain stream pumping) had a clear answer per W0 integration E2E test ("emit on every drain completion") — flagged for W2 weighed-in on inheritance vs composition.

## Hand-off for W2 (reviewer)

Audit checklist:
1. Sub-facade SRP — each is N delegating methods, no branching/rewrapping/logging
2. `SocialCareDesktop` lifecycle: `create()` does NOT auto-start; `close()` cancels connectivity sub before engine close before DB close
3. Connectivity edge logic: only offline → online triggers; mobile counts as online; subscription cancelled on close
4. `_PumpingSyncEngine` design — **open question** for review (subclass vs composition per H1)
5. 4 NICE_TO_HAVE applied
6. Boundary respected: `git diff` zero changes in `packages/` and `apps/acdg_system/`
7. Tests pass: 43 facade GREEN + 1 path_provider skipped + 376 prior = 420
8. Phase 4 trigger payload is comprehensive (51 residual issues mapped with file:line)

## Final stats

- **Files: 9 new** (1 entry point + 7 sub-facades + 1 helper Clock interface)
- **+ 5 cache impls modified + 5 use cases doc-touched + 1 library barrel updated + 1 use case helper deleted**
- **Tests: 420/420 GREEN** (419 + 1 skip)
- **Desktop analyze: 0 errors, 0 warnings in `lib/`**
- **Shell analyze: 51 issues (IDENTICAL to baseline) — 100% Phase 4 trigger payload**
