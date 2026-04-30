# A18a-v2 W2 — Code Review (flutter-code-reviewer)

## Verdict

**APPROVED** — Round 1 of 3. Findings: **0 MUST_FIX, 0 SHOULD_FIX, 2 NICE_TO_HAVE (A18b/c follow-ups).**

Independently verified W1's claims:
- `flutter test test/sync/` → `52/52 All tests passed!`
- `flutter test` (full Desktop suite) → `286/286 All tests passed!` (zero regression on A16/A17)
- `dart analyze bff/social_care_desktop/` → `No issues found!`

## Audit checklist (14/14 PASS)

### 1. Header docstring (CRITICAL) — PASS
`sync_database.dart:1-11` verbatim match against STATE.md spec.

### 2. Physical separation invariant — PASS
- `grep "lib/src/cache\|cache_database\|CacheDatabase" lib/src/sync/` → only `sync_database.dart:5` (warning docstring, not import)
- `grep "lib/src/sync\|sync_database\|SyncDatabase" lib/src/cache/` → only `cache_database.dart:4` (reciprocal warning)

Zero actual cross-imports. Two databases live in independent compilation units.

### 3. SyncDatabase isolation — PASS
`sync_database.dart:23` declares `@DriftDatabase(tables: [Outbox])`. Cache tables not leaked.

### 4. Composite index — PASS
`outbox_table.dart:13` declares `@TableIndex(name: 'outbox_status_created_idx', columns: {#status, #createdAt})`. Status first → SQLite serves drain query without sort.

### 5. 27 mutations + sealed exhaustiveness — PASS
- `grep -c "^final class .*Mutation extends SyncMutation"` → **27**, matches W0 discriminator table.
- `SyncMutation.fromOutboxEntry` switch covers all 27 with `default:throw StateError`.
- `AdmitPatientMutation`, `ApproveLookupRequestMutation`, `RejectLookupRequestMutation` confirmed without `request` field.
- `RemoveFamilyMemberMutation` carries `memberId: String`.
- Lookup admin mutations carry both `tableName: String` AND `request: <Dto>`; payload merges with `_tableName` synthetic key, stripped on round-trip.

### 6. SyncEngine `_dispatch` — PASS
`sync_engine.dart:189-268` is sealed switch over `SyncMutation` (no `default:` arm). Compiler enforces exhaustiveness. Sample arms verified for RegisterPatient, AdmitPatient, RemoveFamilyMember, UpdateLookupItem, ApproveLookupRequest. `_voidOnId`/`_voidOnStandard` helpers preserve `error`/`stackTrace`.

### 7. State-machine correctness — PASS
- Pre-`start()` drain → `Success(DrainSummary(processed: 0, ...))`, queue not touched (`sync_engine.dart:107-118`)
- Post-`close()` drain → `Failure<DrainSummary>(SyncFailure('SyncEngine closed'))` (`sync_engine.dart:102-106`)
- Single-flight via `_inFlight` Future + `whenComplete` reset (`sync_engine.dart:119-124`)
- Retriable check uses `entry.attemptCount + 1` correctly (next-attempt allowance)
- "Max attempts reached: " prefix preserved on retriable→dead demotion

### 8. RetryPolicy math — PASS
- `nextDelay(0)` = 1s, `(10)` = 1024s, `(11)` = 30min (capped)
- Exponent clamped to `min(attemptCount, 30)` (defensive against overflow)
- `shouldRetry` matches spec; default `maxAttempts=10`

### 9. ConflictResolver mapping — PASS
- 409 → `DeadDecision('OPTIMISTIC_LOCK_CONFLICT: ...')`
- 5xx → `RetriableDecision`
- 4xx other → `DeadDecision`
- DioException network/timeout → `RetriableDecision`
- Unknown → `RetriableDecision` (conservative)

### 10. Result<T> + try/catch boundary — PASS
All public methods return `Future<Result<T>>`. try/catch only at Drift boundary. No nested try/catch, no swallowing. `_ready` warmup mirrors A17 cache convention.

### 11. `_toJsonClean` REGRA #2 normalizer — ACCEPTABLE
`sync_mutation.dart:7-15` documents rationale inline. Honors declared `Map<String, dynamic>` contract. Tests use `m.toPayload()` directly (bypassing SQL round-trip), so without write-side normalization fixtures would fail with `type 'DiagnosisDraftDto' is not a subtype of type 'Map<String, dynamic>'` — test catches a real foot-gun. Write-side normalization is conservative call.

### 12. Library exports — PASS
`social_care_desktop.dart:24-39` exports public sync types. `DriftOutboxRepository` and `SyncDatabase` library-private as required for A18c facade.

### 13. Pubspec — PASS
`path_provider: ^2.1.0` + `connectivity_plus: ^7.0.0`. Bump from W0 spec ^6.0.0 justified by constraint solver matching `packages/network` pin.

### 14. Test result — PASS
W1's 286/286 GREEN claim confirmed independently.

## NICE_TO_HAVE (non-blocking, A18b/c follow-ups)

1. **`markFailedRetriable` read-then-update race** (`outbox_repository.dart:219-243`): safe today (single-flight drain) but future concurrent producers (write use cases enqueueing while drain is mid-cycle, or D5 β isolate evolution) could observe stale counts. Wrap in Drift `transaction` when A18b adds concurrent write paths.

2. **`_toJsonClean` performance**: `jsonDecode(jsonEncode(...))` round-trip on every `toPayload()` adds modest overhead. Healthcare-scale rates make this irrelevant; profiling marker if A18b throughput tests show payload serialization on hot path.

## Conclusion

**Verdict: APPROVED.** All 14 audit checks pass, all STATE.md acceptance criteria satisfied, zero analyzer noise, full BFF Desktop suite GREEN. Pipeline advances to A18a close, then A18b dispatch.
