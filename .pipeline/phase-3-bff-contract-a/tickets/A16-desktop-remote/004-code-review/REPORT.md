# A16-v2 W2 — Code Review (flutter-code-reviewer)

## Verdict

**APPROVED** — Round 1 of 3. Findings: **0 MUST_FIX, 0 SHOULD_FIX, 3 NICE_TO_HAVE.**

Independently verified W1's claims:
- `dart analyze lib/ test/remote/` → `No issues found!`
- `flutter test test/remote/` → `All tests passed!` (153/153 GREEN)
- `grep -rn "SocialCareContract\|SocialCareBffRemote" bff/social_care_desktop/` → only the 2 whitelisted docstring mentions in `lib/social_care_desktop.dart:6` and `lib/src/remote/_shared/remote_base.dart:13`. No symbol-level usage.

## Audit checklist (9/9 PASS)

### 1. Sub-contract fidelity (PASS)

| Remote | File:line | Methods | Cross-check |
|---|---|---:|---|
| `RegistryRemote` | `lib/src/remote/registry_remote.dart:13` | 11 | matches `registry_contract.dart:16-90` |
| `AssessmentRemote` | `lib/src/remote/assessment_remote.dart:12` | 7 | matches `assessment_contract.dart:12-54` |
| `CareRemote` | `lib/src/remote/care_remote.dart:7` | 2 | matches `care_contract.dart:8-21` |
| `ProtectionRemote` | `lib/src/remote/protection_remote.dart:7` | 3 | matches `protection_contract.dart:9-29` |
| `AuditRemote` | `lib/src/remote/audit_remote.dart:7` | 1 | matches `audit_contract.dart:7-18` |
| `LookupRemote` | `lib/src/remote/lookup_remote.dart:14` | 8 | matches `lookup_contract.dart:18-72` |
| `HealthRemote` | `lib/src/remote/health_remote.dart:13` | 2 | matches `health_contract.dart:4-10` |

Method signatures (positional/named/optional, return types) match exactly. No surface bleed.

### 2. No god-class regression (PASS)

- Each remote implements exactly one sub-contract.
- `RemoteBase` (`_shared/remote_base.dart:27-137`) is helper-only: `buildDio`, `passthroughStatus`, `backendFailure`, `wrapResponse`, `wrapVoid`, `extractIdResponse`. No endpoint paths, no per-context knowledge.
- LoC justified by method count: health 35, audit 47, care 51, protection 72, assessment 113, lookup 235, registry 282.

### 3. Result<T> + try/catch boundary (PASS)

Every public method shaped `try { dio call; if (2xx) return Success; return backendFailure; } catch (e, stackTrace) { return Failure<T>(e, stackTrace: stackTrace); }`. No nested try/catch; no swallowing in helpers. Verified across all 8 files.

### 4. HTTP path correctness (PASS)

Diff'd against `git show HEAD~1:bff/social_care_desktop/lib/src/remote/social_care_bff_remote.dart` — every legacy path preserved 1:1:
- Health: `/health`, `/ready` (no `/api/v1/`).
- Lookups: `/api/v1/dominios/...` (Portuguese — NOT `/lookups/...`).
- Registry lifecycle POSTs: `_postLifecycle` builds `/api/v1/patients/$id/$slug` for `discharge`, `readmit`, `admit`, `withdraw`.
- Family: POST/DELETE `/api/v1/patients/$id/family-members[/$memberId]`. PUT `/primary-caregiver`.
- Assessment: all 7 PUT to `/api/v1/patients/$id/<slug>` via `_putFicha`.

### 5. REGRA #2 lock-ins match W0 tests (PASS)

(a) **`getLookupsBatch` fan-out + short-circuit** — `lookup_remote.dart:55-79`. Uses `Future.wait(tables.map(getLookupTable))`, sealed-class switch on `Success`/`Failure`. First `Failure` returns immediately. Test `lookup_remote_test.dart:213-223` confirms.

(b) **`addFamilyMember` cpf inert on the wire** — `registry_remote.dart:130-156`. The `cpf` named param accepted (preserves contract signature) but never referenced in body/query. Docstring `:136-141` documents intent. Test `registry_remote_test.dart:444-460` asserts.

(c) **204 → `StandardResponse<void>` synthesis** — `lookup_remote.dart:117, 139, 227` (via `_governanceTransition`). All 4 call `wrapVoid()` (`remote_base.dart:118-121`). Tests `lookup_remote_test.dart:326-336, 416-425, 611+` confirm.

### 6. Library exports + pubspec (PASS)

- `lib/social_care_desktop.dart:9-15` exports the 7 remotes; storage/sync exports removed.
- `pubspec.yaml:14-15` adds direct `core_contracts: { path: ../../packages/core_contracts }`.

### 7. No leftover legacy (PASS)

Only 2 docstring hits, both whitelisted (historical context).

### 8. Analyze + tests green (PASS — independently verified)

### 9. flutter-expert skill rules (PASS)

- Code EN; PT-BR only in URL segment `dominios` (canonical Swift backend path).
- `RemoteBase.dio` is `final` (`remote_base.dart:66`).
- All 7 classes end with `*Remote` (correct suffix).
- Imports follow SDK → external → internal → relative ordering.
- `MockDio` is hand-rolled (`test/remote/_mock_dio.dart`), no mocktail magic.

## NICE_TO_HAVE (non-blocking)

1. `assessment_remote.dart:32` uses `on Object catch (e, stackTrace)` while the other 6 remotes use bare `catch (e, stackTrace)`. Equivalent in Dart but inconsistent — normalize in a future style pass.

2. `audit_remote.dart:18-22` builds a params map with collection-if + `?` then `params.isEmpty ? null : params`. Test `audit_remote_test.dart:40-61` asserts only path. Could simplify but no test demands it.

3. `extractIdResponse` (`remote_base.dart:126-136`) synthesizes a timestamp when `meta.timestamp` is missing — consistent with legacy. Future work could emit a structured warning when this fallback fires; out of scope for A16-v2.

## Conclusion

**Verdict: APPROVED.** W1's deliverable is faithful to sub-contracts, mirrors legacy paths exactly, encodes all 3 REGRA #2 lock-ins, and respects boundary discipline. Proceed to A16-v2 close: update master STATE.md and commit.
