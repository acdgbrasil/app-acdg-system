## C09 — W2 (Code Review) Verdict

**Agent:** flutter-code-reviewer
**Wave:** 2 — REVIEW (read-only)
**Date:** 2026-05-04
**Round:** 1 / 3
**Verdict:** **APPROVED** — Onda 4 closes when this ticket closes.

---

## 1. Architecture (Result + adapter boundary + injection)

| Check | Status | Evidence |
|---|---|---|
| `Result<T>` end-to-end | OK | every leaf `switch (result) { case Success(): … case Failure(:final error): … }`; e.g. `apps/cli/lib/src/commands/team_register_command.dart:118-136`, `team_role_assign_command.dart:92-103`, `team_list_command.dart:75-84`. |
| `try/catch` only at adapter boundary | OK | the only `try/catch` in W1's surface is the `DateTime.parse` adapter in `team_register_command.dart:140-147` (boundary explicitly documented). No other team file catches. |
| Constructor injection | OK | every leaf takes `bffClient`, `formatter`, optional `stdout`, `stderr` as named params; e.g. `team_register_command.dart:45-65`. |
| `final class` declarations | OK | all 10 leaves + 2 sub-parents: e.g. `team_command.dart:37`, `team_role_command.dart:25`, `team_register_command.dart:44`. |
| Imports order (sdk → external → relative) | OK | `team_register_command.dart:35-41` is a representative sample (`package:args` → `package:core_contracts` → relatives). |
| StringSink injection (no real `Stdout`) | OK | every leaf writes via injected `stdout` / `stderr`; `_writeOut` / `_writeErr` are tiny passthroughs. No `stdout.write` / `stderr.write` to `dart:io` in any team file. |
| No `print(...)` | OK | `grep -rn "print(" apps/cli/lib/src/commands/team_*.dart` → empty. |
| No orphan TODO/FIXME/XXX | OK | only hit is the doc comment at `team_register_command.dart:140` ("DateTime.parse throws FormatException…"), which describes an adapter contract, not pending work. |

## 2. Wire format adherence (8th application of C03 M1)

Every wire line cross-checked against the BFF intent at `apps/social_care_bff/web/lib/src/intents/`:

| Verb | Impl line | BFF intent line | Verdict |
|---|---|---|---|
| `team list` GET `/team` queryParameters omit-when-absent | `team_list_command.dart:67-74` (only adds key when flag passed; sends `queryParameters: null` when all absent) | `list_team_intent.dart:43-82` (treats empty strings as null but CLI doesn't depend on that latitude) | OK |
| `team register` POST body `{fullName, birthDate, email, cpf?, initialPassword?}` | `team_register_command.dart:105-111` + `dropNulls(...)` strips optionals when null | `register_worker_intent.dart:39-63` (3 required + 2 optional, exact field names) | OK |
| `team get` GET `/team/<id>` no body | `team_get_command.dart:49` | `get_team_member_intent.dart:27-31` | OK |
| `team deactivate` PUT `/team/<id>/deactivate` | `team_deactivate_command.dart:50` | `deactivate_worker_intent.dart:22-26` | OK |
| `team reactivate` PUT `/team/<id>/reactivate` | `team_reactivate_command.dart:50` | `reactivate_worker_intent.dart:22-26` | OK |
| `team reset-password` **POST** `/team/<id>/reset-password` | `team_reset_password_command.dart:56-58` (`bffClient.post`) | route registered as POST in `team_handler.dart:92` | **OK — explicit POST, deliberate divergence from PUT** |
| `team role assign` POST `/team/<id>/roles` body `{system, role}` | `team_role_assign_command.dart:85` (`{'system': system, 'role': roleId}`) | `assign_role_intent.dart:46-65` (DTO is `system, role`) | **OK — `--role-id` → wire `role` translation is correct** |
| `team role deactivate` PUT `/team/<id>/roles/<rid>/deactivate` | `team_role_deactivate_command.dart:55-57` (two-positional, both interpolated as path segments) | `deactivate_role_intent.dart:25-35` (path-only, 2 UUIDs) | OK |
| `team role reactivate` PUT `/team/<id>/roles/<rid>/reactivate` | `team_role_reactivate_command.dart:56-58` | `reactivate_role_intent.dart` (mirrors deactivate) | OK |

**Test pin for `--role-id` → `role`:** `team_role_assign_command_test.dart:128-131` asserts both:
```
expect(body['role'], equals('social_worker'));
expect(body.containsKey('role-id'), isFalse);
expect(body.containsKey('roleId'), isFalse);
```
**Test pin for POST not PUT:** `team_reset_password_command_test.dart:81` asserts `adapter.lastOptions!.method.toUpperCase() == 'POST'`.

C03 M1 lesson — the 8th application — **lands cleanly**.

## 3. Sub-parent two-level nesting (mirror C08 lookup-request)

| Check | Status | Evidence |
|---|---|---|
| `TeamCommand` registers 7 entries (6 leaves + `TeamRoleCommand`) | OK | `team_command.dart:47-53` (wired collaborators) + fallback at `:62-69` registers `_PlaceholderLeafCommand('list')` … `('reset-password')` + `TeamRoleCommand()`. |
| Bare `TeamCommand()` registers REAL `TeamRoleCommand()` (not leaf placeholder) | OK | `team_command.dart:68` — the fallback adds `TeamRoleCommand()` (which itself self-fills 3 placeholders), so the contract test "the role entry is itself a parent command" passes. |
| `TeamRoleCommand` registers 3 sub-leaves | OK | `team_role_command.dart:31-33` wired + `:38-40` fallback `_PlaceholderCommand('assign|deactivate|reactivate')`. |
| Hand-test of nested help | OK | the W1 REPORT confirms `acdg team --help` → 7 entries; `acdg team role --help` → 3 sub-leaves (compiled binary check, §Quality gates). |

This is the **second sub-parent in the canon**, after C08 `lookup request`. The shape is identical and the placeholder fallback discipline is preserved.

## 4. Saga UX (C04 family-add-style hint)

`team_register_command.dart:128-134` — on `ServerError` with `statusCode >= 500` writes a recovery hint to stderr:
```
Worker registration failed (saga). The person record may have
been partially created; check via 'acdg team get <id>' or
contact admin.
```
The CLI does NOT attempt rollback — explicitly documented at lines 28-32. Test pin at `team_register_command_test.dart:325-349` asserts non-zero exit + stderr contains "500" (test does not assert the hint text verbatim, which is fine — hint text is UX polish, not contract).

## 5. W1's 10 decisions — verdict per item

| # | Decision | Verdict |
|---:|---|---|
| 1 | CLI `--role-id` → wire `role` translation | OK — `team_role_assign_command.dart:85` + test pin at `team_role_assign_command_test.dart:128-131` |
| 2 | `team reset-password` is POST | OK — `team_reset_password_command.dart:56` + test pin at `team_reset_password_command_test.dart:81` |
| 3 | ISO8601 validation on `--birth-date` | OK — `team_register_command.dart:94-99,139-147`. Mirror of C03 `patient admit`. |
| 4 | 5xx saga UX hint to stderr | OK — `team_register_command.dart:128-134` |
| 5 | Sub-parent two-level nesting | OK — see §3 above |
| 6 | `team list` queryParameters omit-when-absent | OK — `team_list_command.dart:67-74` (sends `queryParameters: null` when all 3 absent; only inserts key when flag is non-null AND non-empty) |
| 7 | `--active` no client-side validation | OK — `team_list_command.dart:38-41` (no `allowed:` constraint), `:65,68` forwards raw string |
| 8 | Two-positional verbs combined usage message | OK — `team_role_deactivate_command.dart:47-51` and `team_role_reactivate_command.dart:48-52` use `'Missing required positional arguments: <member-id> <role-id>'` (single message naming both) |
| 9 | `decodeStandardIdResponse` reuse — 7 call-sites | OK — confirmed via grep across `apps/cli/lib/src/commands/`: `care_appointment_command.dart:118`, `protection_violation_command.dart:164`, `protection_referral_command.dart:138`, `lookup_create_command.dart:85`, `lookup_request_create_command.dart:102`, `team_register_command.dart:116`, `team_role_assign_command.dart:90` (= 7) |
| 10 | Print verbs extract `data` from envelope | OK — `team_list_command.dart:78` (`map?['data']`) and `team_get_command.dart:52` (`value['data']`); same shape as C03 + C08 |

## 6. Specific watchouts

| Watchout | Status | Evidence |
|---|---|---|
| C03 M1 regression check — `patient_audit_command.dart:64` still uses `query['eventType']` (camelCase) | OK | confirmed at `patient_audit_command.dart:64`: `query['eventType'] = eventType;`, comment at lines 61-63 reaffirms the W2 M1 fix |
| `decodeStandardIdResponse` 7 call-sites confirmed via grep | OK | see §5 #9 above |
| `team reset-password` POST not PUT — explicit test assertion | OK | `team_reset_password_command_test.dart:81` asserts `method.toUpperCase() == 'POST'` |
| `--role-id` → `role` body translation — explicit test assertion | OK | `team_role_assign_command_test.dart:128-131` asserts `body['role'] == 'social_worker'`, `body.containsKey('role-id') == false`, `body.containsKey('roleId') == false` |

## 7. Tests state

| Check | Status | Evidence |
|---|---|---|
| Total ≥ 658 (W1 claim) | OK | `dart test` returns "All tests passed!" with `+658` summary line |
| C02-C08 GREEN (no regressions) | OK | 658 = 565 (pre-C09 from C08 close) + 97 new − 4 retired C01 stubs (= +93 net), exactly matches the W1 REPORT math |
| W1 did NOT modify W0 test files | OK | `team_command_test.dart` mtime appears post-W0 REPORT but its doc-string at lines 1-61 declares "W0 RED — `TeamCommand` parent contract under C09" + the 6 tests are exactly what W0 §1 enumerated; no leaf test mtime is after W1 impl REPORT mtime |
| `dart analyze` 0 issues | OK | local run prints "No issues found!" |

## 8. Code quality

| Check | Status | Evidence |
|---|---|---|
| Naming `*Command` suffix | OK | `TeamListCommand`, `TeamRegisterCommand`, …, `TeamRoleAssignCommand`, etc. |
| `final class` everywhere | OK | grep confirms all 10 + 2 sub-parents |
| Doc-strings present on every public class | OK | each file opens with a substantial doc-string explaining wire shape, DTO mapping, and any divergence (POST vs PUT, --role-id vs role, etc.) |
| `_PlaceholderLeafCommand` / `_PlaceholderCommand` — consistent fallback discipline | OK | same shape as C03/C04/C05/C06/C07/C08 (private leaf type, `description` is informational, `run()` returns 64) |
| `cli_runner.dart` `_buildTeamCommand` factory | OK | `cli_runner.dart:604-668` wires all 6 top-level leaves + nested `TeamRoleCommand` with its 3 sub-leaves; identical pattern to `_buildLookupCommand` |
| `cli.dart` barrel exports all 10 new commands + 2 parents | OK | `cli.dart:54-64` exports the 10 team files + `team_command.dart` + `team_role_command.dart` |

## 9. Findings — none above MUST_FIX

No issues flagged. Round 1 is clean.

## 10. Verdict

**APPROVED.**

W1 lands C09 cleanly. All 9 endpoints wired with correct verb + path + body. Sub-parent two-level nesting mirrors C08 exactly. The `--role-id` → wire `role` translation is the 8th application of the C03 M1 DTO-as-canon lesson and is double-pinned (impl + test). The `team reset-password` POST-not-PUT divergence is documented + tested. The saga UX hint surfaces on 5xx without overstepping into rollback territory. `decodeStandardIdResponse` reuse hits 7 call-sites as claimed. C02-C08 stays GREEN.

**Onda 4 closes when this ticket closes** (after W3 quality + STATE + commit + push).
