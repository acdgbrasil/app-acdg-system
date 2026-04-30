# A18b-v2 W2 — Code Review (flutter-code-reviewer)

## Verdict

**APPROVED** — Round 1 of 3. Findings: **0 MUST_FIX, 0 SHOULD_FIX, 4 NICE_TO_HAVE (non-blocking, deferred to A18c sweep).**

Independently verified W1's claims:
- `flutter test bff/social_care_desktop/test/use_cases/` → 90/90 GREEN
- `flutter test bff/social_care_desktop/` → 376/376 GREEN
- `dart analyze bff/social_care_desktop/` → zero errors zero warnings (43 info acceptable per REGRA #2)
- `grep -c "class \w*UseCase" lib/src/use_cases/**/*.dart` = 42

## Audit checklist (14/14 PASS)

| # | Check | Status | Evidence |
|---|---|---|---|
| 1 | 42 use case classes | PASS | grep count = 42 |
| 2 | Pattern fidelity (Read / Register / Patient-write / Lookup admin / Health / cache-only) | PASS | 6 spot-checks below |
| 3 | Constructor injection only | PASS | grep `Provider`/`GetIt`/`service_locator` empty |
| 4 | Result<T> end-to-end (no `throw`) | PASS | grep `^throw` in use_cases empty |
| 5 | Write order: read → build → enqueue → optimistic → trigger | PASS | 5 sites verified |
| 6 | NO rollback on failed_dead | PASS | no `subscribeTo`/drain-summary listeners |
| 7 | Cached<T> surgical refactor justified | PASS | Care/Protection/Audit don't need findById Cached<T> |
| 8 | Cached<T> location (cache layer owns) | PASS | `lib/src/cache/_shared/cached.dart:15-33` canonical |
| 9 | Clock injection cross-cutting | PASS | all 5 cache impls accept `now` |
| 10 | uuid: ^4.0.0 dep | PASS | `pubspec.yaml:29` |
| 11 | Library exports | PASS | `lib/social_care_desktop.dart:42-104` |
| 12 | A17 cache test updates | PASS | mechanical `value!.dto.field` edits |
| 13 | No god-interface refs | PASS | grep empty |
| 14 | Independent test verification | PASS | matches W1 claim exactly |

## Pattern fidelity — spot-check evidence

**Pattern 1 (Read, cache-first):** `lib/src/use_cases/registry/fetch_patient_use_case.dart:30-45` — reads `_cache.findById(patientId)`, gates by `_stale.isStale(cached.cachedAt, now: _clock.now())`, falls back to `_remote.fetchPatient`, upserts on success.

**Pattern 2 (Register-style write):** `lib/src/use_cases/registry/register_patient_use_case.dart:37-59` — no cache lookup, `expectedVersion: 0`, enqueue → `unawaited(_engine.triggerDrain())`. Failure propagates without engine touch.

**Pattern 2 (Patient-aggregate write):** `lib/src/use_cases/registry/discharge_patient_use_case.dart:43-74` — exact ordering: cached read → `NotFoundFailure` on null → mutation with `expectedVersion: value.version` → `outbox.enqueue` → `_cache.upsertPatient(value.dto, version: value.version + 1)` → `unawaited(_engine.triggerDrain())`. If enqueue fails, cache UNTOUCHED, engine NOT triggered.

**Pattern 2 (Lookup admin write):** `lib/src/use_cases/lookup/toggle_lookup_item_use_case.dart:33-70` — `(tableName, itemId, request)` signature; reads version from `_cache.findItemById(tableName, itemId)`.

**Pattern 3 (Health passthrough):** `lib/src/use_cases/health/check_health_use_case.dart:9-15` — pure delegation.

**Cache-only read:** `lib/src/use_cases/care/list_appointments_use_case.dart:18-43` — empty fallback on cache miss.

## NICE_TO_HAVE (non-blocking, deferred to A18c sweep)

1. **`extractPatientVersion` dead code** at `lib/src/use_cases/_shared/version_extractor.dart:14`. No callsite uses it (`fetch_patient_use_case.dart:40` reads `value.data.version` directly). Either inline at intended callsite or delete before A18c.

2. **5 cache-only reads accept unused `Clock` + `Duration staleAfter`** (ListAppointments, FetchPlacementHistory, ListReferrals, ListViolationReports, FindLookupRequestById). Defensible for constructor uniformity; Phase 6+ list-endpoint follow-up will use them.

3. **`Clock` is `class Clock` rather than `abstract interface class Clock`.** Tests subclass for FakeClock and could accidentally call `super.now()`. Pure code-quality nit at `_shared/clock.dart:9`.

4. **Cache-impl `now: DateTime Function()?` injection vs typed `Clock`.** Cache layer takes raw function while use case layer takes `Clock`. Unifying around `Clock` would tighten the invariant documented in `stale_policy.dart:17-22`.

None block approval.

## REGRA #2 carve-out

43 info-level `unnecessary_import` in W0-authored test files. W1 left them intact (W0 author's choice; tests GREEN; no behavioral impact). Acceptable per REGRA #2.

## Conclusion

**Verdict: APPROVED.** All STATE.md acceptance criteria satisfied. 42 use cases × 3 patterns implemented faithfully. Cached<T> surgical refactor is correct and minimal. Cache + Use Cases + Sync layers compose cleanly. Pipeline advances to A18b close, then A18c dispatch (facade + shell rewire).
