# A18b-v2 W0 — RED Tests (test-writer)

**Status:** RED complete (2026-04-30). Hand-off to flutter-bff-implementer (W1).

## Summary

90 tests across 9 files (7 contract test files + 1 fake + 1 helper). Analyzer reports 114 errors — all expected RED-signal kind.

## Files created

| File | Tests | LoC |
|---|---:|---:|
| `test/use_cases/_fakes/fake_sync_engine.dart` | — (fake) | 173 |
| `test/use_cases/_test_helpers.dart` | — (helper) | 209 |
| `test/use_cases/registry_use_cases_test.dart` | 27 | 828 |
| `test/use_cases/assessment_use_cases_test.dart` | 15 | 449 |
| `test/use_cases/care_use_cases_test.dart` | 7 | 226 |
| `test/use_cases/protection_use_cases_test.dart` | 12 | 322 |
| `test/use_cases/audit_use_cases_test.dart` | 3 | 100 |
| `test/use_cases/lookup_use_cases_test.dart` | 20 | 530 |
| `test/use_cases/health_use_cases_test.dart` | 6 | 103 |
| **Total** | **90** | **2 940** |

## RED signal verification

```
$ dart analyze test/use_cases/
114 issues, all errors:
  91 × undefined_function           (the 42 use case classes)
  20 × non_type_as_type_argument    (Cached<T> + NotFoundFailure)
   1 × implements_non_class         (Clock interface)
   1 × cast_to_non_type             (same Cached<T>)
   1 × override_on_non_overriding_member  (Clock parent)
0 warnings, 0 info.
```

All errors downstream of unimplemented `lib/src/use_cases/` module + the cascade from A17 cache contract refactor (Cached<T> wrap).

## Locked use case constructors (3 canonical templates)

```dart
// Pattern 1 — Read (cache-first, configurable staleAfter)
class FetchPatientUseCase {
  FetchPatientUseCase({
    required PatientsCache cache,
    required RegistryContract remote,
    required Clock clock,
    Duration staleAfter = const Duration(minutes: 5),
  });
  Future<Result<PatientResponse>> call(String patientId);
}

// Pattern 2 — Write (read cached version, build mutation, enqueue, optimistic update, trigger drain)
class DischargePatientUseCase {
  DischargePatientUseCase({
    required PatientsCache cache,
    required OutboxRepository outbox,
    required SyncEngine engine,
    required Clock clock,
    Uuid? uuid,
  });
  Future<Result<void>> call(String patientId, DischargePatientRequest req);
}

// Pattern 3 — Health passthrough
class CheckHealthUseCase {
  CheckHealthUseCase({required HealthContract remote});
  Future<Result<void>> call();
}
```

All 42 use cases derive from these. Specials:
- **Register-style writes** (RegisterPatient, RegisterAppointment, CreateReferral, ReportViolation, CreateLookupItem, CreateLookupRequest): no cache lookup; `expectedVersion: 0`; return `Result<StandardIdResponse>`.
- **Body-less writes** (AdmitPatient, ApproveLookupRequest, RejectLookupRequest): `payload: {}`.
- **`RemoveFamilyMember`**: `(patientId, memberId)` signature; payload `{memberId: ...}`.
- **Lookup items** (UpdateLookupItem, ToggleLookupItem): `(tableName, itemId, request)` signature; reads version from `LookupCache.findItemById`; tableName persisted via `_tableName` payload key.
- **`GetLookupsBatchUseCase`**: fan-out, returns `Result<Map<String, List<LookupItemResponse>>>`.
- **Cache-only reads** (ListAppointments, ListReferrals, ListViolationReports, FetchPlacementHistory, FindLookupRequestById): no list endpoints in their sub-contracts → cache-only with empty fallback.

## REGRA #2 — 4 ambiguities resolved

1. **`staleAfter` configurable per use case, default 5min.** Verified by registry test setting `staleAfter: 10s`, advancing clock 30s, asserting refresh.
2. **NO rollback on `failed_dead`** — A18b tests verify only the pre-enqueue boundary. If outbox enqueue fails, cache stays unchanged. Post-enqueue (engine drain dead-letter) is A18a/A18c domain.
3. **Concurrent writes preserve FIFO + monotonic version** — registry test "discharge then admit on same patient" with explicit clock advance, asserts `expectedVersion: 5` then `6`, cache version `7`, drainCount `2`.
4. **Lookup by alternate keys** — none of the 42 use cases require it; flagged as future follow-up.

## Hand-off for W1 — required new surfaces

1. **`lib/src/use_cases/_shared/cached.dart`** — generic envelope:
   ```dart
   class Cached<T> {
     const Cached({required this.dto, required this.cachedAt, required this.version});
     final T dto;
     final DateTime cachedAt;
     final int version;
   }
   ```
2. **`lib/src/use_cases/_shared/clock.dart`** — minimal interface: `class Clock { DateTime now() => DateTime.now(); }`.
3. **`lib/src/use_cases/_shared/use_case_failures.dart`** — at least `NotFoundFailure`.
4. **`lib/src/use_cases/_shared/stale_policy.dart`** + **`_shared/version_extractor.dart`**.
5. **42 use case classes** under `lib/src/use_cases/{registry,assessment,care,protection,audit,lookup,health}/...`.
6. **A17 cache contract refactor (Option a)** — refactor 5 cache contracts to return `Cached<T>` envelope. Will break A17's existing 5 cache-impl tests — W1 must update those alongside the contract change.
7. **`pubspec.yaml`** — add `uuid: ^4.x` dependency. Currently absent (verified).

## Open questions / discoveries surfaced for W1

1. **`PatientResponse` has no `copyWith`** — optimistic write-through must construct a new `PatientResponse` for each domain-specific patch. Tests assert only `cached.version` bumped to `cachedVersion + 1`, NOT inspect specific patched fields. W1 may add `copyWith` to `PatientResponse` (in `bff/shared/`) or implement private patch helpers per use case.
2. **Sub-contracts lack list endpoints** for some entities — `CareContract`, `ProtectionContract`, `LookupContract` for requests-by-id. Corresponding read use cases written as **cache-only**. W1 may accept this OR flag as follow-up to extend sub-contracts.
3. **`Cached<T>` refactor cascades to A17 cache impl tests** — ~50 spot edits expected.
4. **`uuid` dep absent** — must be added to `bff/social_care_desktop/pubspec.yaml`.
5. **REGRA #2 #2 boundary** — write use case test "outbox enqueue failure → cache UNCHANGED" closes syncDb mid-test to force outbox failure. Only boundary tested in A18b.

## What test-writer did NOT touch

- `lib/src/cache/`, `lib/src/sync/`, `lib/src/remote/` (A16/A17/A18a closed)
- A17 cache contracts (W1 refactors)
- `bff/shared/`, `packages/` (read-only)
- Existing tests under `test/cache/`, `test/sync/`, `test/remote/`
