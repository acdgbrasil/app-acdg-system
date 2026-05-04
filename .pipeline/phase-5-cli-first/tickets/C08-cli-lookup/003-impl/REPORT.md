# C08 — W1 (GREEN) Report

**Agent:** flutter-bff-implementer
**Wave:** 1 — GREEN
**Date:** 2026-05-04
**Status:** 565 / 565 CLI tests GREEN (was 450 at C07; +115). 0 analyze issues. AOT compiles.

## Files created (10)

10 lookup commands under `apps/cli/lib/src/commands/`:
- `lookup_get_command.dart`, `lookup_batch_command.dart`, `lookup_create_command.dart`, `lookup_update_command.dart`, `lookup_toggle_command.dart` (PATCH)
- `lookup_request_command.dart` (sub-parent)
- `lookup_request_list_command.dart`, `lookup_request_create_command.dart`, `lookup_request_approve_command.dart`, `lookup_request_reject_command.dart`

## Files modified (4)

- `apps/cli/lib/src/session/bff_client.dart` — added `patch<T>` (5th HTTP verb); extended `get<T>` with optional `queryParameters` map.
- `apps/cli/lib/src/commands/lookup_command.dart` — replaced C01 stub with parent (5 leaves + sub-parent).
- `apps/cli/lib/src/cli_runner.dart` — `_buildLookupCommand` factory.
- `apps/cli/lib/cli.dart` — barrel exports for 11 new types.

## Public API delta

```dart
// BffClient (session)
Future<Result<T>> patch<T>(String path, {Object? body, T Function(Object? data)? decode});
Future<Result<T>> get<T>(String path, {T Function(Object? data)? decode, Map<String, Object?>? queryParameters}); // queryParameters NEW

// 11 new Command<int> classes
LookupCommand({get, batch, create, update, toggle, request})
LookupGetCommand / LookupBatchCommand / LookupCreateCommand / LookupUpdateCommand / LookupToggleCommand
LookupRequestCommand({list, create, approve, reject})  // sub-parent
LookupRequestListCommand / LookupRequestCreateCommand / LookupRequestApproveCommand / LookupRequestRejectCommand
```

## Wire format (matches W0 §3)

| Verb | HTTP | Path | Body |
|---|---|---|---|
| `get` | GET | `/lookups/<tableName>` | none |
| `batch` | GET | `/lookups?tables=a,b,c` | none, query param via `queryParameters` |
| `create` | POST | `/lookups/<tableName>` | `{codigo, descricao}` |
| `update` | PUT | `/lookups/<tableName>/<id>` | `{codigo?, descricao?}` (no `active`) |
| `toggle` | **PATCH** | `/lookups/<tableName>/<id>/toggle` | `{active: bool}` |
| `request list` | GET | `/lookup-requests` | none |
| `request create` | POST | `/lookup-requests` | `{tableName, codigo, descricao, justificativa?}` |
| `request approve` | PUT | `/lookup-requests/<id>/approve` | none |
| `request reject` | PUT | `/lookup-requests/<id>/reject` | `{reason}` if `--reason`, else null |

## Decisions taken

1. **PATCH verb mirrors PUT.** `_attempt` already accepts `method` string. Same Bearer interceptor + 401 refresh-retry-once + body resend + 4xx/5xx mapping.

2. **Sub-parent two-level nesting.** Both `LookupCommand` and `LookupRequestCommand` register placeholder fallbacks when ctor has no collaborators. The bare `LookupCommand()` registers a real `LookupRequestCommand()` (which itself has 4 placeholder leaves), not a leaf placeholder — satisfies W0 sub-parent test.

3. **`BffClient.get<T>` extended with `queryParameters`.** W0 batch test asserts `lastOptions.path == '/lookups'` AND `lastOptions.uri.queryParameters['tables']`. Threading `queryParameters` through `_attempt` and `_refreshAndRetry` is backward-compatible (all C02-C07 callers unchanged).

4. **`lookup batch` cap-20 enforced client-side.** Mirrors `GetLookupsBatchIntent.maxTables = 20`. Tolerant CSV: split → trim → drop empties.

5. **`lookup toggle --active` REQUIRED + JSON bool.** `bool.parse(value, caseSensitive: false)`; bad value → `usageException` BEFORE HTTP.

6. **`lookup update` body excludes `active`.** DTO `UpdateLookupItemRequest` is `{codigo?, descricao?}` only.

7. **`lookup request reject --reason` forwarded as `{reason}` body when present.** BFF intent silently ignores extra keys.

8. **Reuse of `decodeStandardIdResponse`** — 2 new call-sites (`lookup_create`, `lookup_request_create`). Helper now has 5 total call-sites.

9. **Print verbs (`get`, `batch`, `request list`) extract `data` from envelope** before passing to formatter — same shape as `patient_get`/`patient_list`.

## Test counts

| Bucket | Before C08 | After C08 |
|--------|-----------:|----------:|
| `apps/cli/` total | 450 | **565** |
| Δ | — | **+115** |

## Quality gates

- `dart analyze apps/cli/` → 0 issues.
- `dart format` → clean.
- `dart compile exe` → succeeded.
- `acdg lookup --help` → 6 entries (5 admin + `request`).
- `acdg lookup request --help` → 4 leaves.
- C02-C07 GREEN.

## Open questions / blockers

(none)
