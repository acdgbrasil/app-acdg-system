# C06 — W2 (REVIEW) Round 1
**Verdict:** APPROVED
**Date:** 2026-05-04
**Reviewer:** flutter-code-reviewer (W2)
**Inputs read:** ticket `000-request.md`, W0 `002-tests/REPORT.md`, W1 `003-impl/REPORT.md`, C03 W2 `004-code-review/REVIEW.md`, all 5 W1 impl files (`care_appointment_command.dart`, `care_intake_command.dart`, `care_command.dart`, `cli_runner.dart`, `cli.dart`), the 3 W0 test files (parent + 2 verbs), the 2 BFF intents (`register_appointment_intent.dart`, `update_intake_info_intent.dart`), `care_handler.dart` (route mounts + envelope shape), `standard_response.dart` (DTO definitions), `_command_helpers.dart` (`dropNulls`, `exitCodeFor`, `stderrMessageFor`), `bff_client.dart` (post/put/_attempt path), `patient_audit_command.dart` (C03 M1 regression check).

## Summary

W1 ships a clean, DTO-faithful, Result-end-to-end implementation of the 2 care commands with **zero MUST_FIX issues**.

- 405/405 tests GREEN (verified locally — `dart test` finishes `00:01 +405: All tests passed!`).
- `dart analyze apps/cli/` → 0 issues (verified).
- 31 W0 contract tests now GREEN (5 parent + 13 appointment + 13 intake), net +27 vs C05 baseline (4 C01 stubs retired).
- The new `StandardIdResponse` decode pattern walks `data['data']['id']` correctly and falls back to `null` defensively on shape mismatch (no throw — the C03 M1-style audit lands cleanly here).
- Wire format adherence verified against the 2 BFF intents: `appointment` body sends `professionalId` (required) + 4 optional camelCase keys exactly as `register_appointment_intent.dart:57-64` expects; `intake` body sends `ingressTypeId` + `serviceReason` (both required) + `originName`/`originContact` (optional) exactly as `update_intake_info_intent.dart:55-79` expects, with `linkedSocialPrograms` correctly NOT sent (BFF degrades absence to `const []` per intent line 95).
- C03 M1 lesson respected: `patient_audit_command.dart:64` still uses `query['eventType']` — no regression. Casing-bug pattern not repeated in care commands (only camelCase keys on the wire).
- Try/catch audit clean: zero new try/catch in care files (verified via grep). Adapter boundary preserved at `bff_client.dart::_attempt` (the only place where Dio exceptions are translated).
- StringSink injection on both verbs (`stdout`/`stderr` optional ctor params); zero `print(...)` (verified via grep).
- ISO8601 fail-fast on `--date` (appointment) runs BEFORE the HTTP call — invalid input triggers `usageException` and the BFF is never contacted (W0 test "invalid --date → no BFF call" GREEN).
- PII safety: error paths surface `Server error (<status>): <BFF message>` — they NEVER re-print user-provided `summary`/`actionPlan`/`originName`/`originContact`/`serviceReason` content. The BFF intents are documented PII-safe and the CLI reflects that contract.

## MUST_FIX

None.

## SHOULD_FIX

None.

## NICE_TO_HAVE

### N1. `OutputFormatter formatter` ctor param is unused on both care verbs

- **Locations:** `care_appointment_command.dart:42,67` (appointment surfaces id via raw `Created appointment <id>` line) and `care_intake_command.dart:48,71` (intake is void-returning and emits no stdout on success).
- **Observation:** the field is `required` and stored as a `final`, but neither `run()` body calls `formatter.format(...)`. Same standing as C03 S3 (4 patient lifecycle commands) — kept on the ctor surface so C10 can swap to a single resolver-driven injection without breaking W0 fixtures.
- **Defer to:** **C10** (output-resolver ticket). Don't block C06.

### N2. Patient ID interpolated as raw path segment

- **Locations:** `care_appointment_command.dart:116`, `care_intake_command.dart:113`.
- **Observation:** `'/patients/$patientId/appointments'` and `'/patients/$patientId/intake'` use direct interpolation. The BFF `validateUuidPathParam` rejects non-UUID inputs server-side, and `args` constrains the rest argument such that no path-breaking characters survive. `Uri.encodeComponent` would be marginally safer; carried over from C03 review (same standing — NICE_TO_HAVE, not blocking).

### N3. Stdout wording `Created appointment <id>` is human-friendly but not machine-parseable

- **Location:** `care_appointment_command.dart:123`.
- **Observation:** consistent with the C03 cursor-on-stderr standing — C10 `--output=json` will swap to `formatter.format({'id': id})`. Acceptable today.

### N4. Defensive fallback `'Appointment created'` on null-id is unreachable in production

- **Location:** `care_appointment_command.dart:127`.
- **Observation:** the BFF `_respondWithId` (`care_handler.dart:125-136`) always serializes `{data:{id: ...}}` for `Success`, so `_decodeAppointmentId` returning null only happens if the envelope is malformed (e.g. proxy or compression rewriting). The defensive fallback is correct (no throw, exit 0, non-empty stdout) but won't be exercised by W0 tests. Keep — it's belt-and-suspenders against future envelope drift.

## Confirmations (what passed)

- **Result<T> end-to-end:** every `run()` ends in a sealed `switch` on `Success`/`Failure`. No `throw` anywhere in the care files.
- **Try/catch audit (W1 §"Try/catch audit") is accurate** — verified via `grep -rn 'try\s*{' apps/cli/lib/src/commands/care_*.dart` returns no matches. The only adapter-boundary catches in the CLI live in `bff_client.dart::_attempt`, `cli_runner.dart::_openBrowser`, `cli_runner.dart::_revokeRefreshToken`, and the YAML readers — none introduced by C06.
- **Constructor injection only:** `BffClient`, `OutputFormatter`, `stdout`, `stderr` are all wired through the ctor. No service locator, no static singletons.
- **`final class`** on both `CareAppointmentCommand` (line 39), `CareIntakeCommand` (line 45), `CareCommand` (line 19), `_PlaceholderCommand` (line 55).
- **All fields `final`:** confirmed on every command class.
- **StringSink injection:** both verbs accept `StringSink? stdout` + `StringSink? stderr` and use local `_writeOut`/`_writeErr` helpers (`care_appointment_command.dart:147-155`; `care_intake_command.dart:125-128`).
- **No `print(...)`** in care commands — confirmed via grep.
- **`StandardIdResponse` decode walks `data['data']['id']`** — verified at `care_appointment_command.dart:139-145`. Three guards in sequence: outer `Map<String, Object?>` check → inner `Map<String, Object?>` check → `id is String` narrow. Returns `null` on any shape mismatch, never throws. The C03 M1-style "permissive W0 test pinning the wrong wire shape" pattern does NOT recur — wire format is verified end-to-end:
  - DTO source: `standard_response.dart:44-58` defines `IdData{id}` and `typedef StandardIdResponse = StandardResponse<IdData>`.
  - BFF response: `care_handler.dart:125-136` serializes `{'data': {'id': value.data.id}, 'meta': value.meta.toJson()}`.
  - CLI decode: `_decodeAppointmentId` walks `data['data']['id']` — match.
- **Wire format — appointment body (`care_appointment_command.dart:107-113`):** keys are `professionalId` (required), `date`/`type`/`summary`/`actionPlan` (optional, dropped when null). Matches `register_appointment_intent.dart:57,60-63` exactly.
- **Wire format — intake body (`care_intake_command.dart:105-110`):** keys are `ingressTypeId` + `serviceReason` (both required), `originName`/`originContact` (optional, dropped when null). `linkedSocialPrograms` correctly NOT sent — `update_intake_info_intent.dart:94-99` degrades absence to `const <ProgramLinkDraftDto>[]`. Match.
- **BFF route mounts (verified at `care_handler.dart:46-47`):**
  - `POST /patients/<id>/appointments` ← CLI sends `'/patients/$patientId/appointments'` (`care_appointment_command.dart:116`).
  - `PUT /patients/<id>/intake` ← CLI sends `'/patients/$patientId/intake'` (`care_intake_command.dart:113`).
  - No `/api` prefix — match.
- **ISO8601 fail-fast** at `care_appointment_command.dart:96-105`: `DateTime.tryParse` returns null → `usageException` → exit 64, no HTTP. W0 test `invalid --date → usage error, no BFF call` GREEN. The check runs BEFORE the body assembly + `bffClient.post` call.
- **Required-flag fail-fast:** `professional-id` (line 91), `ingress-type-id` (line 96 of intake), `service-reason` (line 101 of intake) all reject null + empty string → `usageException` → exit 64 BEFORE the HTTP call. W0 tests for missing flags GREEN.
- **`dropNulls` semantics:** `_command_helpers.dart:64-67` is a pure filter that strips null entries; required fields populated by upstream guards never carry null at the call site. W0 "omits optional keys when flags not provided" GREEN for both verbs.
- **Path-segment encoding:** raw interpolation. UUID-only input via BFF validator + `args` parser — same standing as C03/C04/C05.
- **No JWT decoding, no raw token logging:** `grep -rn 'JWT\|jwt\|access_token\|decode.*token' apps/cli/lib/src/commands/care_*.dart` returns no matches. Bearer header is attached transparently by `bff_client.dart`'s Dio interceptor.
- **PII safety:** error paths funnel through `stderrMessageFor(error)` (`_command_helpers.dart:39-57`), which surfaces only the BFF-provided message + status code — never echoes the user-provided body fields. Both intents are documented PII-safe (lines 23-26 of `register_appointment_intent.dart`; lines 19-22 of `update_intake_info_intent.dart`).
- **Parent `CareCommand.run() = 64` without `printUsage()`** — comment at `care_command.dart:44-48` correctly documents that calling `printUsage()` would NPE on `runner.usage` when the parent is invoked directly from a test (without a runner attached). Mirrors C03/C04/C05.
- **Placeholder fallback** (`_PlaceholderCommand`, line 55) registered when ctor called without collaborators so `--help` introspection still shows both subcommand names. W0 parent test `registers the 2 subcommands required by the ticket` GREEN.
- **Tests:**
  - W1 did NOT modify any W0 test file in semantically-meaningful ways. The W1 REPORT mentions `dart format apps/cli/lib/` reformatted 2 files (whitespace only) — care test files are untouched (W0 wrote, W1 read-only).
  - C02-C05 suites still GREEN. Total `00:01 +405: All tests passed!` (verified locally).
  - Test counts: 405 (was 378 at end of C05). 31 new W0 tests + 4 retired C01 stubs = +27 net. Math checks.
- **C03 M1 regression check:** `patient_audit_command.dart:64` still sends `query['eventType'] = eventType;` — no snake-case regression.
- **`_command_helpers.dart` rename + `_yaml_helpers.dart` extraction unbroken:** both files exist and are imported correctly by all consumers (`grep -rn "_command_helpers.dart\|_yaml_helpers.dart" apps/cli/lib/src/commands/` shows 13+10 usages; care commands import only `_command_helpers.dart` since they don't take YAML input).
- **W0 RED state delta correctly accounted for:**
  - W0 REPORT §1 declared 31 new tests (5+13+13).
  - W1 REPORT §"Test counts" claimed +27 net (378 → 405).
  - 31 added − 4 retired (C01 leaf stubs for `care` parent) = 27. Math checks.
- **Care parent ctor mirrors C04/C05** — optional `appointment`/`intake` ctor params (line 21-23), conditional `addSubcommand` (line 24-25), placeholder fallback when `subcommands.isEmpty` (line 29-32). Symmetry preserved.
- **No backwards-compat shims** — `care_command.dart` cleanly replaces the C01 stub; no old API kept around for migration.
- **Imports order (alphabetical within group):**
  - `care_appointment_command.dart:31-36`: `package:args/...` → `package:core_contracts/...` → `../formatters/...` → `../session/...` → `_command_helpers.dart`. Grouped + alphabetical.
  - `care_intake_command.dart:37-42`: same pattern.
  - `care_command.dart:13-16`: `package:args/...` → `care_appointment_command.dart` → `care_intake_command.dart`. Alphabetical.
  - `cli_runner.dart:37-39`: `commands/care_appointment_command.dart` → `commands/care_command.dart` → `commands/care_intake_command.dart`. Alphabetical, properly sandwiched between `auth_*` and `family_*`.
- **Barrel `cli.dart:22-24`** exports the 3 new types in alphabetical order.

## Decisions verdict (W1's 10 design decisions)

1. **DTO-as-canon over ticket prose.** **ACCEPT.** Ticket §Escopo wrote `--type --date --notes` and `--reason --intake-at --notes`; DTOs disagree on every count. W1 followed the DTOs (lessons C03 M1 + C04 + C05). Verified at `register_appointment_intent.dart:57-64` and `update_intake_info_intent.dart:55-79`.
2. **`StandardIdResponse` decode pattern (defensive null).** **ACCEPT** strongly. The 3-guard walk in `_decodeAppointmentId` (Map → Map → String) returns null instead of throwing — keeps the adapter-boundary discipline (no `throw` outside `_attempt`). Future ID-returning verbs should reuse this pattern.
3. **Stdout wording `Created appointment <id>`.** **ACCEPT.** Symmetric with C03 patient register's "human-friendly first, JSON when `--output=json` lands". C10 will swap.
4. **`--summary` + `--action-plan` exposed on appointment** (OQ-1). **ACCEPT.** DTO-faithful. PII-safety preserved by the BFF intent (never echoed in errors) + by the CLI's `stderrMessageFor` (surfaces only BFF message + status, never user input).
5. **`--linked-program` NOT exposed on intake** (OQ-2). **ACCEPT.** BFF intent degrades absence to `const []` (line 95). Repeatable-flag UX is non-trivial (`addMultiOption` + serialization to list-of-objects); deferring is the right call. File a debt note for `--from-yaml` if user testing flags.
6. **ISO8601 client-side validation on `--date`.** **ACCEPT.** `DateTime.tryParse` runs before HTTP (line 99-104). W0 invalid-date test asserts `adapter.lastOptions == null` — passes.
7. **`dropNulls` for optional fields.** **ACCEPT.** Same convention as C03/C04/C05. The BFF's `_asString` tolerates absent + null + non-string, but omitting is cleaner on the wire and matches the DTO `?` convention.
8. **Parent `run() = 64` without `printUsage()`.** **ACCEPT.** Matches C04/C05; production renders usage at the runner level before `run()` is invoked. Test path doesn't have a runner attached.
9. **`OutputFormatter` injected but unused.** **ACCEPT.** Same standing as the 4 C03 patient lifecycle commands (S3 there, deferred to C10). The W0 contract declared `required this.formatter`, W1 honored it. Loosening the contract is a C10 change.
10. **PII-safety in error paths.** **ACCEPT.** `stderrMessageFor` surfaces only `Server error (<status>): <BFF message>` — verified in `_command_helpers.dart:50-52`. CLI never re-prints user input on failure.

## Wire format adherence

| Field group | DTO/intent source | CLI sends? | Status |
|---|---|---|---|
| **appointment — `professionalId`** | `register_appointment_intent.dart:57` (required, non-empty `String`) | `professionalId` from `--professional-id` (line 108) | match |
| **appointment — `date`** | line 62 via `_asString` (optional `String`) | `date` from `--date` post ISO8601 validation (line 109) | match |
| **appointment — `type`** | line 63 via `_asString` (optional `String`) | `type` from `--type` (line 110) | match |
| **appointment — `summary`** | line 60 via `_asString` (optional `String`) | `summary` from `--summary` (line 111) | match |
| **appointment — `actionPlan`** | line 61 via `_asString` (optional `String`) | `actionPlan` from `--action-plan` (line 112) | match |
| **intake — `ingressTypeId`** | `update_intake_info_intent.dart:55,68` (required, non-empty `String`) | `ingressTypeId` from `--ingress-type-id` (line 106) | match |
| **intake — `serviceReason`** | line 56,69 (required, non-empty `String`) | `serviceReason` from `--service-reason` (line 107) | match |
| **intake — `originName`** | line 75 via `_asString` (optional `String`) | `originName` from `--origin-name` (line 108) | match |
| **intake — `originContact`** | line 76 via `_asString` (optional `String`) | `originContact` from `--origin-contact` (line 109) | match |
| **intake — `linkedSocialPrograms`** | line 77-79 / line 94-99 (optional `List`, defaults to `[]`) | NOT SENT — degrades to `[]` server-side | match (deferred) |

Routes:
- `POST /patients/<id>/appointments` ← `care_handler.dart:46`. CLI: `'/patients/$patientId/appointments'`. **Match.**
- `PUT /patients/<id>/intake` ← `care_handler.dart:47`. CLI: `'/patients/$patientId/intake'`. **Match.**

Response decode:
- Appointment success envelope `{'data': {'id': ...}, 'meta': {...}}` ← `care_handler.dart:128-131`. CLI walks `data['data']['id']`. **Match.**
- Intake success envelope `{'data': null, 'meta': {...}}` ← `care_handler.dart:140-143`. CLI uses `put<Object?>` without decode — `bff_client.dart:241` returns `data as T` on null body, exit 0. 204 also accepted (`bff_client.dart:233-237`: empty body → `data = null` → success). **Match.**

## Routing (APPROVED — no round 2)

- **flutter-bff-implementer (W1)** — no further work required for C06.
- **test-writer (next ticket)** — no action required.
- **flutter-quality-checker (W3)** — proceeds with C06's W3 pass; no MUST_FIX or SHOULD_FIX items pending.

Open debt notes (NOT C06 blockers; carry forward):
- `OutputFormatter` unused on care + 4 patient lifecycle commands → C10 resolver.
- `--linked-program` repeatable flag → defer; consider when intake gains `--from-yaml`.
- Refresh-on-401 CLI auto-retry → cross-cutting debt (same as C03/C04/C05). Not a C06 regression.
- 422 PII surface → BFF documented PII-safe; second-pass strip would be defense-in-depth.
