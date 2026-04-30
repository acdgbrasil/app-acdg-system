# A18a-v2 W0 — RED Tests (test-writer)

**Status:** RED complete (2026-04-30). Hand-off to flutter-bff-implementer (W1).

## Summary

6 test files in `bff/social_care_desktop/test/sync/`. **52 RED tests total.** Analyzer reports 159 errors of expected RED-signal kind, zero warnings, zero info.

## Files created

| File | Tests | LoC |
|---|---:|---:|
| `test/sync/_test_sync_db.dart` | — (helper) | 39 |
| `test/sync/outbox_repository_test.dart` | 13 | 261 |
| `test/sync/sync_mutation_test.dart` | 12 | 660 |
| `test/sync/sync_engine_test.dart` | 11 | 350 |
| `test/sync/retry_policy_test.dart` | 9 | 116 |
| `test/sync/conflict_resolver_test.dart` | 7 | 118 |
| **Total** | **52** | **1 544** |

## RED signal verification

```
$ dart analyze test/sync/
159 errors:
  54 × undefined_function           (mutation constructors)
  47 × non_type_as_type_argument    (Result<DrainSummary>, Success<OutboxEntry?>)
  28 × undefined_identifier         (OutboxStatus, SyncMutation.fromOutboxEntry)
  10 × undefined_class              (OutboxEntry, SyncMutation, OutboxRepository, SyncEngine)
  10 × const_initialized_with_non_constant_value  (const RetryPolicy())
   4 × cast_to_non_type / unchecked_use_of_nullable_value
   2 × creation_with_non_type
0 warnings, 0 info.
```

All errors downstream of unimplemented `lib/src/sync/` module. Zero analyzer noise to fix in W1.

## Locked contracts (W1 must implement EXACTLY)

### `OutboxRepository`

```dart
abstract interface class OutboxRepository {
  Future<Result<void>> enqueue(SyncMutation mutation);
  Future<Result<List<OutboxEntry>>> listByStatus(OutboxStatus status, {int? limit});
  Future<Result<OutboxEntry?>> findById(String id);
  Future<Result<void>> markInFlight(String id);
  Future<Result<void>> markCompleted(String id);
  Future<Result<void>> markFailedRetriable(String id, String error);
  Future<Result<void>> markFailedDead(String id, String error);
  Future<Result<void>> resetToPending(String id);
  Future<Result<void>> clear();
}
enum OutboxStatus { pending, inFlight, failedRetriable, failedDead, completed }
```

`OutboxEntry` is a const data class with named-parameter constructor; fields: `id`, `aggregateType`, `aggregateId`, `mutationType`, `payload (Map<String,dynamic>)`, `expectedVersion`, `createdAt`, `attemptCount`, `lastAttemptAt`, `lastError`, `status`. Impl: `class DriftOutboxRepository(SyncDatabase db) implements OutboxRepository`.

### Critical behavioral invariants (asserted by tests)

- `resetToPending` MUST preserve `attemptCount` (retry math relies on it).
- `markFailedRetriable` MUST increment `attemptCount` and set `lastAttemptAt`.
- `markFailedDead` MUST set `lastAttemptAt` + `lastError` (terminal).

### 27 SyncMutation discriminators

| `aggregateType` | `mutationType` |
|---|---|
| `patient` | `register_patient`, `add_family_member`, `remove_family_member`, `assign_primary_caregiver`, `update_social_identity`, `discharge_patient`, `readmit_patient`, `admit_patient`, `withdraw_patient`, `update_health_status`, `update_housing_condition`, `update_educational_status`, `update_socio_economic_situation`, `update_work_and_income`, `update_community_support_network`, `update_social_health_summary`, `update_intake_info`, `update_placement_history` (18) |
| `appointment` | `register_appointment` |
| `violation_report` | `report_violation` |
| `referral` | `create_referral` |
| `lookup_item` | `create_lookup_item`, `update_lookup_item`, `toggle_lookup_item` |
| `lookup_request` | `create_lookup_request`, `approve_lookup_request`, `reject_lookup_request` |

### Mutation constructor shapes

- **Most:** `request: <RequestDto>` named param.
- **`RemoveFamilyMemberMutation`:** `memberId: String` (no DTO; contract uses two path segments).
- **`AdmitPatientMutation`, `ApproveLookupRequestMutation`, `RejectLookupRequestMutation`:** NO `request` param (path-only).
- **Lookup admin (`Create/Update/ToggleLookupItemMutation`):** both `tableName: String` AND `request: <RequestDto>`.

### `SyncEngine`

Constructor named params: `outbox`, `registry`, `assessment`, `care`, `protection`, `lookup`, `retryPolicy`, `conflictResolver`. Methods: `start()`, `stop()`, `triggerDrain()` returning `Future<Result<DrainSummary>>`, `close()`. `DrainSummary { processed, completed, failedRetriable, failedDead }` — all `int`, named-param const constructor.

**Asserted behaviors:**
- Pre-start drain returns `Success(DrainSummary(processed: 0))` and does NOT touch the queue
- Single-flight: concurrent `triggerDrain` does NOT double-dispatch
- FIFO by `createdAt ASC`
- Post-`close()` returns `Failure(SyncFailure)`

### `RetryPolicy` math

- `nextDelay(0)=1s`, `nextDelay(10)=1024s`, `nextDelay(11)=30min` (capped)
- `shouldRetry(9)=true`, `shouldRetry(10)=false`
- Default ctor: `maxAttempts=10`, `maxDelay=Duration(minutes: 30)`

### `ConflictResolver` mapping

| Error class | Decision |
|---|---|
| 409 BackendError | `DeadDecision` |
| 500/502/503 | `RetriableDecision` |
| 400/401/403/404 | `DeadDecision` |
| `DioException(connectionTimeout\|connectionError)` | `RetriableDecision` |
| Arbitrary error | `RetriableDecision` (conservative) |

## Drift schema for Outbox

11 columns per STATE.md. PK `{id}`. **Composite index `(status, createdAt)` REQUIRED** for the drain query plan.

## Pubspec changes (W1)

```yaml
dependencies:
  path_provider: ^2.1.0
  connectivity_plus: ^6.0.0
```

## Codegen (W1)

After declaring `@DriftDatabase(tables: [Outbox])`:
```bash
cd bff/social_care_desktop && dart run build_runner build --delete-conflicting-outputs
```

Generates `lib/src/sync/_shared/sync_database.drift.dart`.

## Header docstring (verbatim required)

`lib/src/sync/_shared/sync_database.dart`:
```dart
/// Sync Database — MIGRATION-PROTECTED. Holds the Outbox of pending
/// mutations that have NOT yet been acknowledged by the backend.
///
/// CRITICAL: This database lives in a physically SEPARATE .sqlite file
/// from CacheDatabase (`app_sync_queue.sqlite` vs `app_cache.sqlite`).
/// A drop+recreate of the cache is safe (re-fetched from backend);
/// a drop of THIS database = Data Loss of offline mutations.
///
/// Schema changes here MUST be versioned via MigrationStrategy.
/// Increment `schemaVersion` and add migration steps; NEVER drop tables.
library;
```

## `SyncFailure`

`lib/src/sync/_shared/failures.dart` mirrors `CacheFailure`:
```dart
class SyncFailure implements Exception {
  SyncFailure(this.cause);
  final Object cause;
  @override String toString() => 'SyncFailure: $cause';
}
```

## REGRA #2 ambiguities (3 A18a-specific, 0 blockers)

The 4 master-STATE antecipadas (stale threshold / optimistic rollback / concurrent writes / alt-key lookups) all live in A18b/c — none surfaced in A18a. Three A18a-specific notes:

1. **`AdmitPatientMutation` payload** — contract takes no body but `AdmitPatientRequest` DTO exists. Tests assert discriminator only; payload shape can be empty `{}` or wrap DTO.
2. **`triggerDrain` pre-start semantics** — tests assert `Success(processed: 0)`. Loud-fail alternative (`Failure`) is acceptable but must be flagged as contract change.
3. **`OutboxStatus` SQL strings** — tests use the enum API only; suggest lowercase snake_case (`'pending'`/`'in_flight'`/etc.) for consistency.

## Open questions for W1

1. `AdmitPatientMutation` payload: empty `{}` or wrap `AdmitPatientRequest`?
2. `OutboxStatus` SQL serialization confirm: lowercase snake_case?
3. `SyncEngine` dispatch: sealed-class switch (compiler-enforced exhaustiveness, recommended) vs visitor (test doesn't observe)?

## Constraints honored

- No `mocktail` / magic mocks — only fakes from `bff/shared/lib/src/testing/` + one local `_ProgrammableRegistryFake extends FakeRegistryBff` for failure-path tests.
- No `Timer.periodic` in tests — drain tested only via direct `triggerDrain()` calls (D5 γ alignment).
- No touches to `lib/src/cache/`, `lib/src/remote/`, `bff/shared/`, `packages/`, or existing test files.
- `dart format test/sync/` applied; all 5 test files clean.
