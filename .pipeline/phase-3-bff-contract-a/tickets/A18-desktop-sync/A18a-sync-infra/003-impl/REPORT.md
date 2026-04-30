# A18a-v2 W1 — GREEN Implementation (flutter-bff-implementer)

**Status:** GREEN complete (2026-04-30). 52/52 sync tests + 286/286 full BFF Desktop suite GREEN. `dart analyze` zero issues.

## Files created

| Path (under `bff/social_care_desktop/lib/src/sync/`) | LoC | Notes |
|---|---:|---|
| `_shared/failures.dart` | 17 | `SyncFailure` (mirror de `CacheFailure`) |
| `_shared/sync_database.dart` | 41 | `@DriftDatabase` + header docstring (verbatim STATE.md spec) |
| `_shared/sync_database.drift.dart` | — | codegen |
| `_shared/tables/outbox_table.dart` | 69 | 11 columns + composite `(status, createdAt)` index via `@TableIndex` |
| `_shared/tables/outbox_table.drift.dart` | — | codegen |
| `outbox/sync_mutation.dart` | 989 | sealed + 27 final classes; `_toJsonClean` normalizer |
| `outbox/outbox_repository.dart` | 302 | abstract + DriftOutboxRepository |
| `engine/sync_engine.dart` | 293 | drain logic + 27-arm sealed-switch dispatch |
| `engine/retry_policy.dart` | 44 | exponential backoff capped at maxDelay |
| `engine/conflict_resolver.dart` | 69 | error → SyncDecision mapping |
| **Total** | **1 824** | |

## Pubspec changes

Added to `bff/social_care_desktop/pubspec.yaml`:
```yaml
dependencies:
  path_provider: ^2.1.0
  connectivity_plus: ^7.0.0   # bumped from W0 spec ^6.0.0 to align with packages/network
```

(Constraint solver required `^7.0.0` to match `packages/network`'s pin.)

## Codegen

`flutter pub run build_runner build --delete-conflicting-outputs` ran successfully via PATH-curated invocation (excluding swiftly shim that breaks clang for native build hooks). Generated `sync_database.drift.dart` and `tables/outbox_table.drift.dart`.

## Resolution of W0 open questions

1. **`AdmitPatientMutation` payload:** **empty `{}`** — no `request` field. Contract method `admitPatient(String patientId)` takes path only.
2. **`OutboxStatus` SQL serialization:** **lowercase snake_case** (`pending`, `in_flight`, `failed_retriable`, `failed_dead`, `completed`) via `OutboxStatus.toSql()` and `OutboxStatus.fromSql()`.
3. **`SyncEngine` dispatch:** **sealed-class `switch`** — compiler enforces exhaustiveness over 27 mutations. Helpers `_voidOnId` and `_voidOnStandard` discard wrapped types so every dispatch returns `Result<void>`.

## REGRA #2 — `_toJsonClean` normalizer (NOT test cheating)

**4-point analysis:**

- **Intention:** `OutboxEntry.payload` contract promises `Map<String, dynamic>`. Round-trip via Outbox table SQL TEXT must preserve nested structures.
- **Failure mode:** `json_serializable`'s default `toJson()` is **shallow** — nested DTO instances aren't recursively serialized. Test fixtures construct `OutboxEntry` directly from `m.toPayload()` (bypassing the production `jsonEncode → SQL TEXT → jsonDecode` round-trip). Without normalization: `type 'DiagnosisDraftDto' is not a subtype of type 'Map<String, dynamic>'`.
- **Verdict:** contract violation in production code (not test bug). The test catches a real foot-gun for any future consumer of `entry.payload`.
- **Resolution (impl-side):** `SyncMutation._toJsonClean(Map)` does `jsonDecode(jsonEncode(map))` to force recursive normalization at enqueue time. Tests pass without modification. Contract honored literally.

**Documented inline** at `sync_mutation.dart:1-15`. Reviewer is welcome to challenge — alternative would be read-side normalization, which I rejected as it leaves the foot-gun in `payload`'s declared type.

## Constraint confirmations

- `grep -rn "SocialCareContract\|SocialCareBffRemote" bff/social_care_desktop/lib/` → empty (only A16/A17 docstring mentions remain).
- `grep -rn "lib/src/cache\|cache_database\|CacheDatabase" lib/src/sync/` → only docstring reference at `sync_database.dart:5` (the warning comment).
- `grep -rn "lib/src/sync\|sync_database\|SyncDatabase" lib/src/cache/` → only docstring reference at `cache_database.dart:4` (the reciprocal warning).
- **Physical separation enforced:** sync layer has zero `import 'package:social_care_desktop/...cache...'`; cache layer has zero `import 'package:social_care_desktop/...sync...'`.
- Header docstring on `sync_database.dart:1-9` exact-matches STATE.md.
- Composite index `@TableIndex(name: 'outbox_status_created_idx', columns: {#status, #createdAt})` declared on Outbox.

## Test result

```
flutter test test/sync/
00:00 +52: All tests passed!

flutter test (full suite)
00:01 +286: All tests passed!
```

Per file:
- outbox_repository_test: 13/13
- sync_mutation_test: 12/12
- sync_engine_test: 11/11
- retry_policy_test: 9/9
- conflict_resolver_test: 7/7

Full BFF Desktop suite (cache + remote + sync): **286/286 GREEN** (zero regressão A16/A17).

## dart analyze

```
$ dart analyze (bff/social_care_desktop/, full)
No issues found!
```

## Library exports

`lib/social_care_desktop.dart` adds:
- `SyncFailure` (from `failures.dart`)
- `SyncMutation` sealed + 27 final classes
- `OutboxRepository`, `OutboxEntry`, `OutboxStatus`
- `SyncEngine`, `DrainSummary`
- `RetryPolicy`
- `ConflictResolver`, `SyncDecision`, `CompletedDecision`, `RetriableDecision`, `DeadDecision`

`DriftOutboxRepository` and `SyncDatabase` remain library-private (A18c facade instantiates).

## Hand-off for W2 (reviewer) — spot-check priorities

1. **`sync_mutation.dart:1-15`** — `_toJsonClean` rationale (REGRA #2 documented above; reviewer welcome to challenge).
2. **`sync_engine.dart` `_dispatch`** — verify each of the 27 arms hits the correct sub-contract method shape.
3. **`outbox_repository.dart` `markFailedRetriable`** — read-then-update pattern (no race in single-flight drain; future concurrent producers may need transaction).
4. **`outbox_table.dart`** — composite index column ordering `{#status, #createdAt}` (status first for `WHERE status = ? ORDER BY createdAt ASC` query plan).
5. **Library exports** — `DriftOutboxRepository` private; A18c facade only.
6. **Header docstring** — exact match `sync_database.dart:1-9`.
7. **Physical separation** — zero cross-imports between `cache/` and `sync/`.
8. **Single-flight drain** — `_inFlightDrain` Future shared across concurrent triggers.
9. **Sealed-class exhaustiveness** — adding a 28th mutation later requires updating `_dispatch` (compiler enforces).
