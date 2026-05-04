# C08 — W2 (REVIEW) Report

**Agent:** flutter-code-reviewer
**Wave:** 2 — REVIEW
**Date:** 2026-05-04
**Verdict:** **APPROVED**
**Round:** 1 of 3

## Summary

W1 delivers exactly what W0 contracted: 10 new lookup command files
(5 admin/read + 1 sub-parent + 4 governance leaves), `BffClient.patch<T>`
as the 5th HTTP verb, and a backward-compatible `queryParameters` extension on
`get<T>`. All 9 wire-format decisions match the BFF intents on the canon side.
`dart analyze` reports 0 issues; `dart test` reports **565/565 GREEN** (W0 baseline
of 450 + the 115 RED tests added in W0 are now all passing). C02-C07 carriers
remain GREEN — no regressions.

The two structural risks called out in the review brief (sub-parent placeholder
behavior + `get<T>` queryParameters backward-compat + PATCH retry resends body
under method=PATCH) all check out against both the W0 tests and the impl source.

No MUST_FIX issues. No SHOULD_FIX issues.

## 1. Architecture review

| Check | Result | Citation |
|---|---|---|
| `Result<T>` end-to-end | OK — every leaf returns `Result<T>` from `bffClient.*` and `switch` matches `Success`/`Failure` | e.g. `lookup_get_command.dart:50-59`, `lookup_toggle_command.dart:85-95` |
| `try/catch` only at adapter boundaries | OK — only inside `BffClient._attempt` (`bff_client.dart:288-290`) and in the `_translate` Dio mapper (`bff_client.dart:360-380`); `lookup_toggle_command.dart` uses `try/catch` for `bool.parse` which is a parser boundary, immediately rerouted via `usageException` — acceptable per ADR-019 (`lookup_toggle_command.dart:79-83`) |
| Constructor injection | OK — every leaf takes `bffClient`, `formatter`, `stdout`, `stderr` via named params (`lookup_get_command.dart:21-27`) |
| `final class` + all fields `final` | OK — every command is `final class` with `final` fields; `LookupCommand` and `LookupRequestCommand` parents are `final class` (`lookup_command.dart:32`, `lookup_request_command.dart:28`) |
| Imports order alphabetical (SDK → external → internal → relative) | OK — verified across all 10 new files plus the modified ones; e.g. `lookup_command.dart:22-29`, `lookup_get_command.dart:12-17` |
| No `print(...)` | OK in C08 surface — only pre-existing `_stub_command.dart:28` (used by C01 `team`/`health` stubs) carries a `print`; out of scope |

## 2. `BffClient` extensions

### `patch<T>` mirrors `put<T>`

`bff_client.dart:188-209` — verb body uses `_attempt('PATCH', ...)` and
`_refreshAndRetry('PATCH', ...)` with the same body+401 contract as `put<T>`
at `:159-180`. Diff vs `put` is exactly 4 method-string sites, nothing else.

`_attempt` at `:240-291` already accepts a `String method` knob (introduced in
C04 for `put`/`delete`); `'PATCH'` is forwarded verbatim to `Dio.request` via
`Options(method: method)` at `:256`. Dio dispatches PATCH lower-cased on the
wire, which is what the W0 PATCH-method test asserts (`bff_client_test.dart:1478`:
`expect(adapter.lastOptions!.method.toUpperCase(), equals('PATCH'))`).

### 401 refresh-retry-once invariant for PATCH

W0 pins this at `bff_client_test.dart:1583-1651` (`401 → refresh → retries
PATCH once with new bearer + same body`). The retry path is the
`_refreshAndRetry` invocation at `bff_client.dart:200-205` — the same
`method: 'PATCH'` + `body: body` are forwarded. After the refresh succeeds,
the `_attempt` retry at `:323-329` resends `method`, `path`, `body`, and the
optional `queryParameters` — so the retry uses `PATCH` on the wire (asserted at
`bff_client_test.dart:1648`). The W0 persistent-401 test at `:1791-1843` pins
`adapter.calls <= 2` and `tokenClient.refreshCalls == 1` — no infinite loop.

### `get<T>` queryParameters extension is backward-compatible

`bff_client.dart:99-122` — `queryParameters` is `Map<String, Object?>?` with
default `null`. When `null` (every C02-C07 caller's invocation), the call to
`Dio.request` at `:264-269` passes `queryParameters: null`, which Dio treats as
"no query string" — identical to pre-C08 behaviour. The threading is symmetric
on the retry path at `:300-329`, so the contract holds across refresh-retry.

Verified C02-C07 callers unchanged: `dart test` reports all C03 `patient`,
C04 `family`, C05 `assessment`, C06 `care`, C07 `protection` suites pass
(450/450 carrier tests stay green per `dart test` summary).

### `patient_audit_command.dart` — C03 M1 regression check

`patient_audit_command.dart:64` still uses `query['eventType']` (camelCase),
matching BFF `get_audit_trail_intent.dart`. Note: `patient_audit` builds its
query string by hand (`'?${Uri(queryParameters: query).query}'`, line 72) and
passes the resulting concatenated path to the legacy single-string `get<T>`
overload. This is intentionally NOT migrated to `queryParameters:` because it
falls under "C02-C07 callers unchanged" — W1 left it alone, which the brief
explicitly listed as a watchout. No regression.

## 3. Wire format adherence (DTO-as-canon, 7th application)

| Verb | Path checked vs intent | Body checked vs intent |
|---|---|---|
| `get` | `lookup_get_command.dart:50` GET `/lookups/$tableName` ↔ `get_lookup_table_intent.dart:7-13` (path-only `tableName`) | none |
| `batch` | `lookup_batch_command.dart:81-84` GET `/lookups` + `queryParameters: {'tables': csv}` ↔ `get_lookups_batch_intent.dart:46-82` reads `queryParameters['tables']` and runs same tolerant split | none |
| `create` | `lookup_create_command.dart:82-83` POST `/lookups/$tableName` ↔ `create_lookup_item_intent.dart:37-71` parses route `tableName` + body | `{codigo, descricao}` at `lookup_create_command.dart:80` ↔ DTO `CreateLookupItemRequest({codigo, descricao})` (intent `:41-58`) |
| `update` | `lookup_update_command.dart:83-86` PUT `/lookups/$tableName/$itemId` ↔ `update_lookup_item_intent.dart:37-51` | `{codigo?, descricao?}` via `dropNulls`; **`active` not present**, asserted at `lookup_update_command_test.dart:208-213` |
| `toggle` | `lookup_toggle_command.dart:85-86` **PATCH** `/lookups/$tableName/$itemId/toggle` ↔ `toggle_lookup_item_intent.dart:48-67` | `{active: <bool>}` JSON bool (not string) at `lookup_toggle_command.dart:87`; W0 pins type at `lookup_toggle_command_test.dart:127-128` `expect(body['active'], isA<bool>())` |
| `request list` | `lookup_request_list_command.dart:41` GET `/lookup-requests` ↔ `get_lookup_requests_intent.dart:7-12` (empty value object) | none |
| `request create` | `lookup_request_create_command.dart:99-100` POST `/lookup-requests` ↔ `create_lookup_request_intent.dart:36-74` | `{tableName, codigo, descricao, justificativa?}` via `dropNulls` at `:92-97` ↔ DTO `CreateLookupRequestRequest` (intent `:54-64`) |
| `request approve` | `lookup_request_approve_command.dart:51-53` PUT `/lookup-requests/$id/approve` ↔ `approve_lookup_request_intent.dart:25-29` (path-only) | none |
| `request reject` | `lookup_request_reject_command.dart:68-70` PUT `/lookup-requests/$id/reject` ↔ `reject_lookup_request_intent.dart:25-29` (path-only) | `{reason}` if `--reason` present, else `null`. Intent has no body parser and silently ignores extra keys (W0 §4 D5 + impl :63-66). |

`batch` query encoding via `queryParameters` (NOT path interpolation) verified
at `lookup_batch_command.dart:81-84`. The W0 test at
`lookup_batch_command_test.dart:90-100` asserts `lastOptions.path == '/lookups'`
(no `?`) AND `qp['tables']` contains the CSV — both pass.

## 4. Sub-parent two-level nesting

**`LookupCommand` registers 6 entries.** Verified at `lookup_command.dart:33-61`:
when collaborators provided, 5 admin leaves + 1 `LookupRequestCommand` are
added; when ctor receives no collaborators, 5 leaf placeholders + a real
`LookupRequestCommand()` are added.

**Critical: bare `LookupCommand()` registers a real `LookupRequestCommand()`,
not a placeholder leaf.** Verified at `lookup_command.dart:53-60`: the
`subcommands.isEmpty` branch calls `addSubcommand(LookupRequestCommand())` —
NOT `_PlaceholderLeafCommand('request')`. The W0 sub-parent test at
`lookup_command_test.dart:97-110` asserts `request!.subcommands` is non-empty;
the inner `LookupRequestCommand()` (called with no args) hits its own
"empty fallback" branch at `lookup_request_command.dart:42-47` which adds 4
placeholder leaves — so `request!.subcommands` returns those 4 placeholders,
satisfying `isNotEmpty`.

`dart test test/commands/lookup_command_test.dart` and
`dart test test/commands/lookup_request_command_test.dart` both pass.

## 5. `lookup batch` cap-20

`lookup_batch_command.dart:56-79`:
1. **Missing positional** → `usageException` at `:59-62` (no HTTP).
2. **Tolerant CSV parse** at `:64-68`: `split(',') → trim → drop empty`
   matches the BFF intent at `get_lookups_batch_intent.dart:57-61` exactly.
3. **Empty after parse** → `usageException` at `:69-73` (no HTTP).
4. **`tables.length > 20`** → `usageException` at `:74-79` (no HTTP).
5. **20 boundary inclusive** is accepted because the guard is strict `> 20`.

W0 boundary tests at `lookup_batch_command_test.dart:169-181` (20 accepted)
and `:143-167` (21 rejected) both pass; `:184-215` confirm `,,,` and `   ,  ,  `
trip the empty branch with no HTTP call.

## 6. W1's 9 decisions — verdict

| # | Decision | Verdict | Citation |
|---|---|---|---|
| 1 | PATCH mirrors PUT | OK | `bff_client.dart:188-209` vs `:159-180` |
| 2 | Sub-parent two-level nesting | OK | `lookup_command.dart:53-60` + `lookup_request_command.dart:42-47` |
| 3 | `get<T>` queryParameters extension | OK; backward-compat preserved | `bff_client.dart:99-122` |
| 4 | `lookup batch` cap-20 client-side | OK | `lookup_batch_command.dart:64-79` |
| 5 | `lookup toggle --active` JSON bool | OK | `lookup_toggle_command.dart:78-87` |
| 6 | `lookup update` excludes `active` | OK; not even exposed as a flag | `lookup_update_command.dart:39-48` (no `addOption('active')`) + W0 test `lookup_update_command_test.dart:208-213` |
| 7 | `lookup request reject --reason` forwarded as body | OK; null body when absent | `lookup_request_reject_command.dart:63-66` |
| 8 | `decodeStandardIdResponse` reuse — 5 call-sites | OK; verified via `grep -rln`: care_appointment, protection_violation, protection_referral, lookup_create, lookup_request_create | `_command_helpers.dart:78-84` |
| 9 | Print verbs extract `data` from envelope | OK | `lookup_get_command.dart:53` + `lookup_batch_command.dart:87-88` + `lookup_request_list_command.dart:44` |

## 7. Code quality

- Naming: `*Command` suffix on every command (`LookupBatchCommand`,
  `LookupRequestApproveCommand`, etc.). PascalCase classes, snake_case files.
- Doc-strings: every public class is documented with the BFF intent path,
  body shape, and decision rationale. The most thorough doc-strings are on
  `lookup_toggle_command.dart` (PATCH-introduction + JSON-bool pin) and
  `lookup_command.dart`/`lookup_request_command.dart` (sub-parent rationale).
- No orphan TODO/FIXME in C08 surface.
- Code EN / UI PT-BR — error messages are EN; help text is EN; only
  user-facing prose is the placeholder description strings (`'lookup $name'`)
  which are EN — fine.

### Minor observations (NOT blocking)

- `formatter` is a required-but-unused field in `lookup_update_command.dart:51`,
  `lookup_toggle_command.dart:45`, `lookup_request_approve_command.dart:30`,
  `lookup_request_reject_command.dart:41`. Same pattern in C04
  (`family_remove_command`) and C07 — uniform constructor signature is the
  C03 W2 H3 heuristic. Acceptable.
- `_stub_command.dart` still uses `print(...)` — pre-existing C01 stub used
  by `team`/`health`, untouched by C08, out of scope.

## 8. Tests

- **W1 did NOT modify W0 test files.** `git log` on each of the 11 lookup
  test paths shows the last commit is `2d6b94d (C01)` for any pre-existing
  file (e.g. `lookup_command_test.dart` was C01-stub-replaced by W0; the
  diff is W0's contract change, NOT W1 cheating). The 10 newly-created test
  files are untracked-pre-W2 and W1 did not modify them after creation.
- **C02-C07 still GREEN.** Confirmed via `dart test`: all 565 tests pass.
- **Total ≥ 565.** Confirmed: `00:01 +565: All tests passed!`.

## 9. Specific watchouts

| Watchout | Status |
|---|---|
| C03 M1 regression — `patient_audit_command.dart:64` `query['eventType']` (camelCase) | OK — preserved at `:64`. |
| `get<T>` queryParameters backward-compat — C02-C07 callers unchanged | OK — `queryParameters` defaults to `null`; only `lookup_batch_command` uses it. C02-C07 GREEN. |
| PATCH retry path — body resent with method=PATCH on 401 retry | OK — verified at `bff_client.dart:323-329` and `bff_client_test.dart:1640-1648`. |
| Sub-parent placeholder behavior — bare `LookupCommand()` test passes | OK — `lookup_command.dart:59` instantiates a real `LookupRequestCommand()` (which fills its own 4 placeholder leaves), satisfying `request!.subcommands.isNotEmpty` at `lookup_command_test.dart:104-109`. |

## 10. Verdict

**APPROVED** — round 1 of 3.

Hand off to W3 (`flutter-quality-checker`) for final lint+coverage gate.

