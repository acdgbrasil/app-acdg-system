# A16-v2 W1 — GREEN Implementation (flutter-bff-implementer)

**Status:** GREEN complete (2026-04-29). 153/153 tests pass. `dart analyze` clean.

## Files created (`bff/social_care_desktop/lib/src/remote/`)

| Path | LoC | Sub-contract |
|---|---:|---|
| `_shared/remote_base.dart` | 137 | shared helpers (`backendFailure`, `wrapResponse`, `wrapVoid`, `extractIdResponse`, `passthroughStatus`, `buildDio`) |
| `registry_remote.dart` | 282 | RegistryContract (11 methods) |
| `assessment_remote.dart` | 113 | AssessmentContract (7 methods) |
| `care_remote.dart` | 51 | CareContract (2 methods) |
| `protection_remote.dart` | 72 | ProtectionContract (3 methods) |
| `audit_remote.dart` | 47 | AuditContract (1 method) |
| `lookup_remote.dart` | 235 | LookupContract (8 methods, fan-out batch) |
| `health_remote.dart` | 35 | HealthContract (2 methods) |
| **Total** | **972** | 7 sub-contracts, 34 methods |

`RegistryRemote` and `LookupRemote` exceed the 80-LoC target because each method needs its own `try/catch` shell. Both internalize private helpers (`_postLifecycle`, `_governanceTransition`, `_putFicha`) so the variation per method is one path/slug per public API.

## Files deleted (option a — full break-change cleanup)

- `lib/src/remote/social_care_bff_remote.dart` (916-line god class)
- `lib/src/storage/{local_cache_contract,local_social_care_repository,offline_first_repository}.dart` + empty `storage/` dir
- `lib/src/sync/sync_engine.dart` + empty `sync/` dir
- `test/social_care_bff_remote_test.dart`
- `test/storage/{local_social_care_repository,offline_first_repository}_test.dart`
- `test/sync/sync_engine_test.dart` + empty dirs

## Pubspec changes

`bff/social_care_desktop/pubspec.yaml` — added direct `core_contracts: { path: ../../packages/core_contracts }`. Was previously transitive through `shared`. Eliminates `depend_on_referenced_packages` info lints. Mirrors the pattern in `bff/shared/` and `bff/social_care_web/`.

## Library exports

`lib/social_care_desktop.dart` rewritten — exports only the 7 thin remotes; the 4 storage/sync exports removed alongside the deleted source files.

## Architectural decisions

1. **Inheritance into `abstract RemoteBase`.** Each remote `extends RemoteBase`, gets `final Dio dio` + 4 helpers + `Options.passthroughStatus`. RemoteBase carries no per-remote state.
2. **Constructor `({required Dio dio})`** matches W0 test contract exactly. Production wiring (baseUrl, X-Actor-Id, Bearer interceptor) via `RemoteBase.buildDio(...)`.
3. **`Options.passthroughStatus`** set once on `RemoteBase`, reused on every endpoint. Non-2xx surfaces as `Response`, never throws — `try/catch → Failure` reserved for genuine I/O failures.
4. **Three private helpers** keep duplication low: `RegistryRemote._postLifecycle` (admit/discharge/readmit/withdraw), `LookupRemote._governanceTransition` (approve/reject), `AssessmentRemote._putFicha` (all 7 fichas).
5. **`getLookupsBatch` fan-out** — `Future.wait` over `getLookupTable`, aggregate into `LookupsBatchResponse`. First per-table `Failure` short-circuits with original error + stackTrace.
6. **`addFamilyMember`'s `cpf` parameter inert on the wire** (REGRA #2 ambiguity #1, pre-resolved in W0). Inline docstring documents the legacy decision.
7. **`StandardResponse<void>` synthesis on 204** via `wrapVoid()` (REGRA #2 ambiguity #3, pre-resolved). Used by 4 lookup admin/governance methods.

## Test result

```
flutter test test/remote/
00:00 +153: All tests passed!
```

Per file: health 5/5 · audit 6/6 · care 11/11 · protection 13/13 · assessment 30/30 · lookup 36/36 · registry 52/52 · **= 153/153 GREEN**.

## dart analyze

```
$ dart analyze (bff/social_care_desktop/, full)
Analyzing social_care_desktop...
No issues found!
```

## SocialCareContract / SocialCareBffRemote scan

```
$ grep -rn "SocialCareContract\|SocialCareBffRemote" bff/social_care_desktop/lib/
lib/social_care_desktop.dart:6:                              /// the deleted `SocialCareContract` god-class.
lib/src/remote/_shared/remote_base.dart:13:                  /// `SocialCareBffRemote` (god-class deleted in A16-v2). Each concrete
```

Both are docstring-only references explaining historical context. Zero symbol-level references in any `lib/` file.

## REGRA #2 ambiguities surfaced in W1

Zero new. The 3 pre-resolved by W0 were all implemented to spec.

## Out-of-scope follow-ups

`apps/acdg_system/` consumers (DI providers, sync_detail_panel, integration tests) will fail to compile against the new exports. **Authorized per master STATE.md** ("Desktop não está em produção — pode quebrar"). Shell rebuild follows A18-v2 facade restoration. Not in A16-v2's acceptance criteria.

## Hand-off for W2 (reviewer) — spot-check priorities

1. `_shared/remote_base.dart` — helpers match legacy contract; `RemoteBase` carries no per-remote knowledge.
2. `registry_remote.dart` — 11 methods, mixed return types; lifecycle helper preserves status-code acceptance lists.
3. `lookup_remote.dart` — `getLookupsBatch` fan-out short-circuits on first failure with stack preserved.
4. `addFamilyMember` — `cpf` parameter inert on the wire (test name `'optional cpf does not change path or body'`).
5. `wrapVoid()` only used for the 4 `StandardResponse<void>` lookup methods.
6. No `SocialCareContract` symbol references; only docstring mentions remain.
7. Each public method has exactly one outer `try/catch` mapping to `Failure(e, stackTrace: stackTrace)`.
8. No god-class re-emergence — every remote `implements <Single>Contract`.
