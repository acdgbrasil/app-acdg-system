# C08 — W0 (RED) Report

**Agent:** test-writer
**Wave:** 0 — RED
**Date:** 2026-05-04
**Status:** RED CONFIRMED. 127 analyzer errors. ~110 new tests across 12 files. C02-C07 GREEN (387 passes).

## 1. Test files

11 test command files (1 replaced + 10 new) + bff_client_test.dart appended:

| Path | Tests |
|------|------:|
| `lookup_command_test.dart` (replaced) | 5 |
| `lookup_get_command_test.dart` | 8 |
| `lookup_batch_command_test.dart` | 11 |
| `lookup_create_command_test.dart` | 11 |
| `lookup_update_command_test.dart` | 13 |
| `lookup_toggle_command_test.dart` (PATCH) | 12 |
| `lookup_request_command_test.dart` (sub-parent) | 5 |
| `lookup_request_list_command_test.dart` | 6 |
| `lookup_request_create_command_test.dart` | 11 |
| `lookup_request_approve_command_test.dart` | 9 |
| `lookup_request_reject_command_test.dart` | 10 |
| `bff_client_test.dart` (PATCH group appended) | +10 |

**~110 new tests.**

## 2. Public surface declared

CLI shape (NESTED — D1):
```
acdg lookup
├── get <table>
├── batch <a,b,c,...>          (cap 20 client-side)
├── create <table> --code --label
├── update <table> <id> [--code] [--label]
├── toggle <table> <id> --active=true|false       (PATCH)
└── request                                       (sub-parent, singular)
    ├── list
    ├── create <table> --code --label [--justificativa]
    ├── approve <id>
    └── reject <id> [--reason]
```

11 new Command classes + `BffClient.patch<T>`.

## 2.5 `BffClient.patch<T>` contract

```dart
Future<Result<T>> patch<T>(
  String path, {
  Object? body,
  T Function(Object? data)? decode,
});
```

Mirrors `put<T>`: same Bearer interceptor, same 401 refresh-retry-once, same body-resend on retry, same 4xx/5xx/network mapping, same persistent-401 no-loop. 10 tests pin every aspect.

## 3. Wire format — DTO-as-canon (7th application)

| Verb | HTTP | Path | Body | Response |
|---|---|---|---|---|
| `get` | GET | `/lookups/<tableName>` | none | `StandardResponse<List<LookupItemResponse>>` |
| `batch` | GET | `/lookups?tables=a,b,c` | none, query CSV cap 20 | `StandardResponse<LookupsBatchResponse>` |
| `create` | POST | `/lookups/<tableName>` | `{codigo, descricao}` | `StandardIdResponse` |
| `update` | PUT | `/lookups/<tableName>/<id>` | `{codigo?, descricao?}` (NO `active`) | `StandardResponse<void>` |
| `toggle` | PATCH | `/lookups/<tableName>/<id>/toggle` | `{active: bool}` REQUIRED JSON bool | `StandardResponse<void>` |
| `request list` | GET | `/lookup-requests` | none | `StandardResponse<List<LookupRequestResponse>>` |
| `request create` | POST | `/lookup-requests` | `{tableName, codigo, descricao, justificativa?}` | `StandardIdResponse` |
| `request approve` | PUT | `/lookup-requests/<id>/approve` | none | `StandardResponse<void>` |
| `request reject` | PUT | `/lookup-requests/<id>/reject` | none; `--reason` is CLI sugar | `StandardResponse<void>` |

Local 400 codes asserted in stderr tests: `INVALID_LOOKUPS_BATCH_QUERY`, `INVALID_CREATE_LOOKUP_ITEM_BODY`, `INVALID_UPDATE_LOOKUP_ITEM_BODY`, `INVALID_TOGGLE_LOOKUP_ITEM_BODY`, `INVALID_CREATE_LOOKUP_REQUEST_BODY`, `INVALID_APPROVE_LOOKUP_REQUEST_PARAMS`, `INVALID_REJECT_LOOKUP_REQUEST_PARAMS`.

## 4. Decisions taken

- **D1: NESTED single-sub-parent shape.** Final UX is `acdg lookup request list` (singular `request`). Two parents per pluralization would confuse.
- **D2: DTO-as-canon translation.** `--code → codigo`, `--label → descricao`. RED tests pin wire body MUST carry DTO names.
- **D3: `lookup toggle --active=true|false` REQUIRED.** BFF demands JSON `bool`; CLI can't read prior state.
- **D4: `lookup update --active` REJECTED on wire.** DTO `UpdateLookupItemRequest` is `{codigo?, descricao?}` only.
- **D5: `--reason` for reject is CLI-sugar only.** DTO has no `reason` field. W1 forwards as body OR drops; tests permissive.
- **D6: Cap-20 enforced client-side for batch.** 21 → usage error, no HTTP. 20 boundary inclusive accepted.

## 5. Open questions for W1

1. `--reason` on reject: forward or drop? Recommendation: forward (extra keys ignored).
2. `lookup toggle --active`: `addOption` parses `true|false` string → bool.
3. `lookup batch` query encoding via `Dio queryParameters: {'tables': 'a,b,c'}`.
4. `tableName` literal pass-through (no UUID gate).
5. PATCH body `Object?` for future PATCH endpoints.

## 6. RED state confirmed

- `dart analyze` 12 affected files: **127 errors / 0 info**.
- `dart test`: **413 GREEN, 14 RED files** (10 missing-impl test loads + bff_client_test for PATCH + lookup_command_test for parent shape).
- C02-C07 isolated: **387 GREEN, 0 regressions.**

## 7. No impl files modified

Only the 12 test paths created/edited. `apps/cli/lib/**`, `apps/social_care_bff/**` untouched.
