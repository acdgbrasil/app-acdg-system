# A16-v2 W0 — RED Tests (test-writer)

**Status:** RED complete (2026-04-29). Hand-off to flutter-bff-implementer (W1).

## Summary

7 thin remote classes (one per sub-contract) will live under `bff/social_care_desktop/lib/src/remote/`. W0 produced **153 RED tests** across 7 files plus shared helpers. Analyzer reports exactly 21 errors, all expected RED-signal kind (`uri_does_not_exist`, `undefined_class`, `undefined_function`).

## Files created

### Shared helpers
| File | LoC |
|---|---:|
| `bff/social_care_desktop/test/_test_uuids.dart` | 64 |
| `bff/social_care_desktop/test/remote/_mock_dio.dart` | 204 |

### Remote test files
| File | Tests | LoC | Coverage |
|---|---:|---:|---|
| `test/remote/registry_remote_test.dart` | 52 | 906 | 11/11 RegistryContract |
| `test/remote/assessment_remote_test.dart` | 30 | 583 | 7/7 AssessmentContract |
| `test/remote/care_remote_test.dart` | 11 | 191 | 2/2 CareContract |
| `test/remote/protection_remote_test.dart` | 13 | 260 | 3/3 ProtectionContract |
| `test/remote/audit_remote_test.dart` | 6 | 147 | 1/1 AuditContract |
| `test/remote/lookup_remote_test.dart` | 36 | 712 | 8/8 LookupContract |
| `test/remote/health_remote_test.dart` | 5 | 79 | 2/2 HealthContract |
| **Total** | **153** | **2 878** | **34/34 methods** |

## Test axes per method

1. HTTP path correctness (path interpolation incl. patientId/itemId).
2. Body / query mapping (`request.toJson()` matches body; query params asserted).
3. Success parsing (`Result<StandardResponse<…>>`, `PaginatedList<…>`, `StandardIdResponse`, `void`).
4. BackendError propagation (non-2xx with `error` key → `Failure(BackendErrorResponse)`).
5. Network failure path (Dio throwing → `Failure(e)`).

## Validation

```
$ dart analyze test/remote/ test/_test_uuids.dart
21 errors:  7 × uri_does_not_exist  +  7 × undefined_class  +  7 × undefined_function
~99 warnings: dead_code (downstream of URI errors — vanish in GREEN)
   7 infos:  depend_on_referenced_packages (cosmetic — pubspec dep added in W1)
```

Zero contract / DTO / syntax mismatches.

## REGRA #2 ambiguities (defaults locked in tests)

### 1. `LookupContract.getLookupsBatch` — no backend endpoint exists
- **Verdict:** implementation choice.
- **Default in tests:** fan-out N parallel `GET /api/v1/dominios/{name}` calls; assemble `LookupsBatchResponse` client-side. Per-table failure surfaces as `Failure`.

### 2. `addFamilyMember`'s `cpf` parameter
- **Verdict:** legacy hook with no current effect.
- **Default in tests:** accept the parameter, ignore on the wire (`'optional cpf does not change path or body'`).

### 3. `StandardResponse<void>` synthesis on 204 (lookup admin/governance)
- **Verdict:** synthesize `ResponseMeta(timestamp: DateTime.now().toIso8601String())` on empty body.
- **Default in tests:** timestamp-agnostic assertions (only `isA<Success<StandardResponse<void>>>`).

## Hand-off to W1

- **Constructor convention:** `class FooRemote implements FooContract { FooRemote({required Dio dio}) : _dio = dio; final Dio _dio; }`. Tests inject MockDio.
- **RemoteBase shape (impl detail):** extract helpers from legacy `social_care_bff_remote.dart` lines 41-87 — `backendFailure<T>`, `wrapResponse<T>`, `extractIdResponse`. Composition or inheritance — implementer's choice.
- **Path conventions preserved from legacy** — see ticket STATE.md §"HTTP path conventions".
- **Library exports:** remove `social_care_bff_remote.dart` export; add 7 new remotes (or expose via facade in A18-v2).
- **Pubspec:** consider adding direct `core_contracts: { path: ../../packages/core_contracts }` to eliminate info-level lints.
