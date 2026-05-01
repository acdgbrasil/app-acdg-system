# A18c-v2 W0 — RED Tests (test-writer)

**Status:** RED complete (2026-05-01). Hand-off to flutter-bff-implementer (W1).

## Summary

44 tests across 9 test files + 1 fake + 1 helper. **1657 LoC total.** Analyzer reports 46 errors, all RED-signal.

## Files created

| File | Tests | LoC |
|---|---:|---:|
| `test/facade/_fakes/fake_connectivity.dart` | — (fake) | 98 |
| `test/facade/_test_helpers.dart` | — (helper) | 140 |
| `test/facade/social_care_desktop_test.dart` | 14 | 516 |
| `test/facade/registry_facade_test.dart` | 7 | 160 |
| `test/facade/assessment_facade_test.dart` | 3 | 119 |
| `test/facade/care_facade_test.dart` | 3 | 88 |
| `test/facade/protection_facade_test.dart` | 5 | 114 |
| `test/facade/audit_facade_test.dart` | 2 | 69 |
| `test/facade/lookup_facade_test.dart` | 6 | 138 |
| `test/facade/health_facade_test.dart` | 2 | 60 |
| `test/facade/integration_end_to_end_test.dart` | 2 | 157 |
| **Total** | **44** | **1 657** |

## RED signal verification

```
$ dart analyze test/facade/
46 errors, 0 warnings, 0 info:
  23 × undefined_identifier         (SocialCareDesktop, sub-facades, helpers)
  21 × non_type_as_type_argument    (Result/Success/Failure cascade)
   2 × cast_to_non_type             (same cascade)
```

All errors downstream of unimplemented `lib/src/facade/`. `dart analyze lib/` unaffected.

## Locked contracts

### `SocialCareDesktop` (entry point)

```dart
class SocialCareDesktop {
  SocialCareDesktop._({...private internals...});

  // Public sub-facades
  final RegistryFacade registry;
  final AssessmentFacade assessment;
  final CareFacade care;
  final ProtectionFacade protection;
  final AuditFacade audit;
  final LookupFacade lookup;
  final HealthFacade health;

  Stream<DrainSummary> get drainStream;             // BROADCAST
  Future<Result<DrainSummary>> triggerDrain();

  // Lifecycle (D4 α — app-controlled, NO auto-start)
  Future<void> startSync();
  Future<void> stopSync();
  Future<void> close();                             // cancels connectivity sub

  static Future<SocialCareDesktop> create({
    required String baseUrl,
    required String actorId,
    required String? Function() tokenProvider,
    String? cacheFilePath,
    String? syncQueueFilePath,
    Dio? dio,
    Clock? clock,
    Duration staleAfter = const Duration(minutes: 5),
    Connectivity? connectivity,
  });
}
```

**Behavioral contracts asserted:**
1. `create()` does NOT auto-start sync (D4 α). Pre-`startSync` `triggerDrain` returns `Success(processed: 0)`.
2. `create()` subscribes to `connectivity.onConnectivityChanged` exactly once. `close()` cancels.
3. `drainStream` is BROADCAST; emits ONE `DrainSummary` per drain completion.
4. After `close()`, `triggerDrain` returns `Failure(SyncFailure)`.
5. `startSync` is idempotent.

### Sub-facade signatures (1-line delegating bodies)

| Sub-facade | Methods | Pattern |
|---|---:|---|
| `RegistryFacade` | 13 | `Future<Result<X>> method(args) => _useCase(args)` |
| `AssessmentFacade` | 7 | All `(String patientId, XxxRequest req) → Future<Result<void>>` |
| `CareFacade` | 3 | listAppointments + registerAppointment + updateIntakeInfo |
| `ProtectionFacade` | 6 | 3 reads + 3 writes |
| `AuditFacade` | 1 | fetchAuditTrail with filters |
| `LookupFacade` | 10 | items + tables + requests + admin |
| `HealthFacade` | 2 | checkHealth + checkReady |
| **Total** | **42** | |

## Connectivity edge logic asserted

```dart
bool _wasOnline;  // seeded from checkConnectivity() at create()

_connectivitySub = connectivity.onConnectivityChanged.listen((results) {
  final isOnline = results.any((r) => r != ConnectivityResult.none);
  if (isOnline && !_wasOnline) {
    unawaited(_engine.triggerDrain());
  }
  _wasOnline = isOnline;
});
```

## FakeConnectivity

`implements Connectivity` (legal — class is non-`final`/non-`sealed` in connectivity_plus v7+). Tests inject via `SocialCareDesktop.create(connectivity: fake)`.

## Hand-off for W1

### Order recommendation
1. **Sweep first** (mechanical): delete `version_extractor.dart`, promote `Clock`, refactor 5 cache impls
2. Build 7 sub-facades (private ctor + N delegating methods)
3. Build `SocialCareDesktop` factory + lifecycle + connectivity listener
4. Update library exports
5. `flutter test test/facade/` → 44/44 GREEN (1 skipped per path_provider binding constraint)
6. Shell rewire (10 files in `apps/acdg_system/`)
7. `flutter analyze apps/acdg_system/` — verify all remaining issues are in `packages/social_care/...`

### Sweep of 4 NICE_TO_HAVE (W1 applies; no test for sweep itself)

| # | Item | Action |
|---|---|---|
| 1 | `extractPatientVersion` dead code | DELETE `_shared/version_extractor.dart`. Remove export. |
| 2 | Cache-only reads accept unused `Clock`/`staleAfter` | DOCUMENT inline only: `/// Param accepted for Pattern 1 uniformity (H3); used when backend exposes list endpoint in Phase 6+`. |
| 3 | `Clock` should be `abstract interface class` (H6) | PROMOTE `class Clock` → `abstract interface class Clock`. ADD `class SystemClock implements Clock`. |
| 4 | Cache impls accept `DateTime Function()? now` | REFACTOR 5 cache impls to accept `Clock?` (default `const SystemClock()`). UPDATE `test/use_cases/_test_helpers.dart` to pass `clock: ctx.fakeClock` (currently `now: fakeClock.now`). |

### Shell rewire — 10 files in `apps/acdg_system/`

| File | Substitution |
|---|---|
| `lib/logic/di/social_care_providers.dart` | `LegacyPatientService` etc → `desktop.registry`/`desktop.care`/etc |
| `lib/logic/di/app_providers.dart` | `SocialCareBffRemote.create()` → `await SocialCareDesktop.create(...)` |
| `lib/logic/di/infrastructure_providers.dart` | `SocialCareContract` typed params → `SocialCareDesktop` |
| `lib/logic/di/dependency_builders.dart` | idem |
| `lib/logic/di/dependency_manager.dart` | idem |
| `lib/ui/organisms/sync_detail_panel.dart` | `engine.status` → `desktop.drainStream`. `engine.processQueue()` → `desktop.triggerDrain()` |
| `lib/logic/router/app_router.dart` | `SyncEngine.status` → `desktop.drainStream` listener |
| `lib/ui/pages/home_page.dart` | idem |
| `integration_test/staging_integration_test.dart` | Wire `SocialCareDesktop` with `:memory:` paths + `FakeConnectivity` |
| `pubspec.yaml` | No change |

### OUT OF SCOPE — `packages/social_care/` (Phase 4 user-driven)

**1 file in `packages/` that W1 MUST NOT touch:**

```
packages/social_care/lib/src/data/services/http_social_care_client.dart
```

References `SocialCareBffRemote` (deleted in A16). Residual analyze issues in `apps/acdg_system/` will trace back here — intentional Phase 4 trigger.

**Acceptance criterion:** `flutter analyze apps/acdg_system/` drops from 51 → ONLY issues whose paths begin with `packages/social_care/...`. Any new issue in `apps/acdg_system/` itself is a W1 bug.

## REGRA #2

**Zero ambiguity.** Boundary work was well-scoped.

## Test-writer self-checklist

- [x] No imports from `packages/*` in any test file (boundary respected)
- [x] FakeConnectivity is a real `implements Connectivity`
- [x] Valid UUID v4 fixtures
- [x] No `Timer.periodic` in tests — connectivity-driven only
- [x] Boundary scoping (REGRA #2 H4): tests cover facade boundary only
- [x] `dart format` clean
- [x] RED signal cascade only
- [x] All sub-facade method signatures derived from A18b use case `call()` signatures
