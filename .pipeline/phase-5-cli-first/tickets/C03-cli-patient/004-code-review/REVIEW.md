# C03 — W2 (REVIEW) Round 1

**Verdict:** REJECTED — see MUST_FIX section
**Date:** 2026-05-04
**Reviewer:** flutter-code-reviewer (W2)
**Inputs read:** ticket `000-request.md`, W0 `002-tests/REPORT.md`, W1 `003-impl/REPORT.md`, all 9 W1 impl files (`bff_client.dart`, `_patient_helpers.dart`, 8 `patient_*_command.dart`), `cli_runner.dart`, `cli.dart`, all 9 W0 patient test files, `bff_client_test.dart`, the 4 BFF Registry DTOs (`admit/discharge/readmit/withdraw_patient_request.dart`), `register_patient_request.dart`, BFF audit handler + intent (`registry_family_handler.dart:60`, `get_audit_trail_intent.dart`).

## Summary

W1 ships a clean Result-end-to-end implementation: 219 tests GREEN, `dart analyze` clean, AOT compile succeeds, `_attempt`/`_refreshAndRetry` generalization is correct and the GET path is regression-free. DTO-faithful body shapes are right, ISO8601 fail-fast works, mutually-exclusive guard fires before file I/O, and the body-resend-on-retry invariant is preserved by explicit parameter passing (not closure-only). However, **one production correctness bug** blocks approval: the audit `event-type` filter is sent on the wire as `event_type` (snake_case) but the BFF intent reads `query['eventType']` (camelCase) — the filter is silently dropped end-to-end. The W0 test is permissive (accepts either), so the bug compiles + passes tests but breaks in production. Two SHOULD_FIX items (one dead param in `_buildBffClient`, one out-of-order import in `cli_runner.dart`) round out the round.

## MUST_FIX (REJECT triggers)

### M1. Audit `event-type` query param sent as snake_case but BFF reads camelCase — filter silently dropped in production

- **Location:**
  - CLI sends: `apps/cli/lib/src/commands/patient_audit_command.dart:61` — `query['event_type'] = eventType;`
  - BFF reads: `apps/social_care_bff/web/lib/src/intents/get_audit_trail_intent.dart:42` — `eventType: _coerce(query['eventType']),`
  - BFF tests confirm casing: `apps/social_care_bff/web/test/intents/get_audit_trail_intent_test.dart:82,100,134` all use `'eventType'` literal.
- **Issue:** W1 followed the W0 REPORT §4.3 claim that "BFF reads `request.url.queryParameters['event_type']`". That claim is **factually wrong** — the actual BFF intent code at `get_audit_trail_intent.dart:42` reads the camelCase key. `Uri.queryParameters` is a case-sensitive `Map<String, String>`; shelf forwards verbatim. So `acdg patient audit <id> --event-type=patient.admitted` will hit the BFF with `?event_type=patient.admitted`, the intent parser will see `query['eventType'] == null`, and the audit trail will be returned UNFILTERED. No error, no warning — silent semantic drop.
- **Why W0 missed it:** the W0 audit test asserts `qp['event_type'] ?? qp['eventType']` (line 113-115 of `patient_audit_command_test.dart`) — permissive. The test passes regardless of which casing the impl chose.
- **Two ways to fix (W1 picks):**
  1. Send camelCase from the CLI: change line 61 of `patient_audit_command.dart` to `query['eventType'] = eventType;`. Single-line fix, matches what the BFF actually parses today, and W0 stays GREEN.
  2. Change the BFF intent to read snake_case (or accept both). This is a cross-package change — out of scope for C03 (touches `apps/social_care_bff/web/`). NOT recommended for this ticket.
- **Recommendation:** option 1 — flip the CLI to send `eventType` and update W1 REPORT decision §5 to reflect "BFF reads camelCase, W0 §4.3 was wrong".
- **Routing:** flutter-bff-implementer (W1). One-line code change + REPORT correction.

## SHOULD_FIX (advisory, doesn't block on its own)

### S1. `_buildBffClient(loadDiscovery: ...)` accepts a parameter it never uses

- **Location:** `apps/cli/lib/src/cli_runner.dart:233-238`.
  ```dart
  BffClient _buildBffClient({
    required CredentialStore credentialStore,
    required Future<Result<OidcDiscovery>> Function() loadDiscovery,
  }) {
    return BffClient(baseUrl: _defaultBffUrl, credentialStore: credentialStore);
  }
  ```
- **Issue:** `loadDiscovery` is `required` but not referenced inside the body. W1 REPORT §10 + §"Open questions" calls this out explicitly: "kept the param to preserve future-wiring shape". Today it's dead surface — callers must construct a discovery loader they know will be ignored. The contract lies about its dependencies.
- **Defer to:** this round preferred (one-line drop + matching update at the call site `cli_runner.dart:97-100`). Otherwise, defer to C04 when refresh-on-401 actually wires the runner-level token client. If kept now, document the no-op inline (a `// ignore: unused_element_parameter`-style comment is not appropriate; a doc-string saying "reserved for C04 — currently no-op" is).
- **Routing:** flutter-bff-implementer (W1).

### S2. Import order broken in `cli_runner.dart` — `errors/cli_error.dart` interleaved between `commands/`

- **Location:** `apps/cli/lib/src/cli_runner.dart:43-46`.
  ```
  import 'commands/protection_command.dart';
  import 'errors/cli_error.dart';                  // ← out of place
  import 'commands/team_command.dart';             // ← should sit with other commands
  import 'config/oidc_config.dart';
  ```
- **Issue:** within the relative-imports group, alphabetical order is violated: `commands/...` should be a contiguous run, then `config/...`, then `errors/...`, then `formatters/...`, etc. CLAUDE.md (frontend/CLAUDE.md §"Convencoes — Codigo") says "Imports: SDK -> external -> internal -> relative" — implicit alphabetic within the relative group is the dart_format default, but `dart format` does NOT reorder imports. `dart analyze` doesn't flag this either; it's a manual hygiene issue.
- **Defer to:** this round (10-second fix). Otherwise the W3 quality pass will catch it.
- **Routing:** flutter-bff-implementer (W1).

### S3. Patient lifecycle commands carry an unused `formatter` field

- **Locations:** `patient_admit_command.dart:35`, `patient_discharge_command.dart:33`, `patient_readmit_command.dart:30`, `patient_withdraw_command.dart:32`.
- **Issue:** these four endpoints return 204 No Content / empty body and never call `formatter.format(...)`. The constructor still requires it and stores it as a `final` field, so memory + ctor surface are wasted. `dart analyze` doesn't flag public fields as unused, hence GREEN.
- **Why it's not a M*FIX:** W0 §2.3 explicitly declared the "common shape" with `required this.formatter`; W1 followed the contract. Removing it would break W0 — the proper path is W2 → next ticket → W0 contract correction.
- **Defer to:** **C10** (the formatter-resolver ticket) — when global `--output` lands and a single `OutputFormatter` lives at the runner level, the four 204 commands stop needing it as a ctor dependency at all, and the four W0 contract fixtures can be loosened in lockstep. **Do NOT block C03 on this.**
- **Routing:** test-writer (next ticket / C10) for contract loosening; flutter-bff-implementer follows.

### S4. `--bff` global flag parsed at the runner but never read by `_buildBffClient`

- **Location:** `apps/cli/lib/src/cli_runner.dart:76,237`. The runner declares `--bff` (default `http://localhost:3000`) and `_buildBffClient` constructs `BffClient(baseUrl: _defaultBffUrl, ...)` — ignoring the parsed value.
- **Issue:** identical bug already present at end of C02 (the BFF URL was hardcoded then too); C03 inherits it. User cannot override the BFF endpoint at runtime, contradicting the help text.
- **Why it's not a regression for C03:** the bug existed pre-C03; W1 didn't introduce it.
- **Defer to:** C04 or C10 alongside the formatter resolver — both flags need the same "resolve-flag-then-construct-late" pattern. File a debt note in STATE.md.
- **Routing:** flutter-bff-implementer (future ticket).

## NICE_TO_HAVE

### N1. `_yamlToJsonNode` walks the whole tree even when `loadYaml` returned a plain `Map`

- **Location:** `patient_register_command.dart:243-263`.
- **Observation:** `loadYaml` always returns `YamlMap`/`YamlList` for non-leaf nodes (the `Map`/`List` branches are defensive belts-and-suspenders). The recursion is correct; it's just denser than needed. A single `_$YamlMapToJsonMap()` could replace the four-branch dispatcher with a delegating `if (node is YamlNode) return node.value;` plus recursion only at container types. Aesthetic only — keep as-is.

### N2. `_PlaceholderCommand.run() => 64` is silent — no message

- **Location:** `patient_command.dart:79-90`.
- **Observation:** when the runner falls into a placeholder (test-only path), `run()` returns 64 with no stderr. This is fine because the placeholder path is unreachable in production. Leave as-is.

### N3. Cursor surfacing format `"Next page cursor: <value>"` is human-friendly but not machine-parseable

- **Location:** `patient_list_command.dart:70`. C10 should consider an optional `--cursor-out=<file>` or a structured `meta` line (e.g. JSON-on-stderr) once pagination automation is needed. Not in scope today.

## Confirmations (what passed)

- **Result<T> end-to-end:** every command's `run()` ends in a sealed switch on `Success`/`Failure`. No `throw` outside adapter boundaries.
- **`try/catch` audit (W1 §"Try/catch audit") is accurate:**
  - `bff_client.dart:142-184` — Dio request + JSON parse, translates to `_Attempt.failure`.
  - `patient_admit_command.dart:92-100` — `DateTime.parse` for ISO8601 validation, returns bool.
  - `patient_register_command.dart:217-240` — `fileReader` + `loadYaml`, both translated to `InvalidArgError`.
  - One additional adapter-boundary catch lives at `cli_runner.dart:308-323` (`_openBrowser`) — out of scope for C03 but consistent with the rule.
- **Constructor injection only:** no service locator, no singletons. `BffClient`, `OutputFormatter`, `fileReader` are all wired through ctors.
- **`final class`** on every command class + `_PlaceholderCommand`. `BffClient` was already `final class` from C02.
- **StringSink injection on commands:** every patient command takes `StringSink? stdout` and `StringSink? stderr` and uses local `_writeOut`/`_writeErr` helpers — no direct `Stdio.stdout` writes inside `run()`.
- **No `print(...)`** in `apps/cli/lib/src/commands/patient_*` or `_patient_helpers.dart` — confirmed via `grep`.
- **`BffClient.post<T>` correctness:**
  - Body serialized as JSON (`bff_client.dart:157` sets `contentType: Headers.jsonContentType` when body is non-null).
  - Bearer header attached on POST via the existing interceptor (no second interceptor needed; W0 test "attaches Authorization: Bearer on POST too" passes).
  - 401 → refresh once → retry once. Body resent verbatim via explicit param plumbing in `_refreshAndRetry({..., body: body})` (NOT closure-only — survives the retry path).
  - 4xx (not 401) → `Failure(ServerError)`. No retry. The 422 W0 test asserts `tokenClient.refreshCalls == 0` and `adapter.calls == 1` — both pass.
  - `_Attempt<T>` recursion guard: the retry path's `_refreshAndRetry` cannot recurse — it calls `_attempt`, then a second 401 short-circuits to `Failure(AuthRequiredError())` at line 224 without re-entering `_refreshAndRetry`.
  - `_attempt` generalization does not regress GET — the C02 401-refresh-retry tests are still GREEN (verified by running `dart test test/session/bff_client_test.dart` → 41 passing).
  - `RefreshTokenInvalidError` on POST → store cleared at line 208 + `Failure(AuthRequiredError())` at line 210. W0 POST test asserts `await store.read() == null`.
- **Patient-command correctness:**
  - No JWT decoding anywhere in patient commands (search confirms).
  - No raw token logging (no `print` of tokens; only `Bearer <token>` lands in the Dio interceptor header).
  - Patient ID interpolated as path segment via `'/patients/$patientId/admit'` — Dio does not re-encode, but the upstream `args` parser does not allow special characters that would break URL semantics in the rest position; for safer paths, `Uri.encodeComponent` would be marginally better (NOT a MUST_FIX given UUIDs only).
  - Query params assembled via `Uri(queryParameters: {...}).query` (lines 56-57 of `patient_list_command.dart`, lines 67-69 of `patient_audit_command.dart`) — safe against injection.
  - `--admitted-at` validation via `DateTime.parse` runs BEFORE any HTTP call (W0 test `--admitted-at not ISO8601 → no BFF call` asserts `adapter.lastOptions == null`).
  - `--from-yaml` mutual-exclusivity check at `patient_register_command.dart:91-96` runs BEFORE file I/O (W0 test `flag set + --from-yaml together → BFF must NOT have been called` asserts `adapter.lastOptions == null`).
  - `dropNulls` (`_patient_helpers.dart:60-63`) is a pure filter; required fields never carry `null` because the upstream code (`_buildBodyFromFlags`, the explicit `personId`/`prRelationshipId` strings) populate them with non-null values before `dropNulls` runs. The test `omits notes when not provided` (discharge, withdraw) passes — required fields are not stripped.
- **Contract divergence handling (W0 §4.1) implemented as documented:**
  - `discharge` body: `{reason, notes?}` — no `discharged-at`. ✓
  - `readmit` body: `{notes?}` only — no `reason`. ✓
  - `withdraw` body: `{reason (required), notes?}`. ✓
  - W0 audit query: `event_type` (snake_case) — implemented; **but the BFF actually wants `eventType` (camelCase) — see M1**.
  - Routes: `/patients`, NOT `/api/patients`. ✓ (BFF mounts `/patients/*` directly per `app_router.dart:84`).
- **Tests:**
  - W1 did not modify any W0 test file. Confirmed via `git diff` — `patient_command_test.dart` shows W0's stub→parent migration; `bff_client_test.dart` shows W0's additive `post<T>` group only (no `-` lines deleting C02 fixtures); the 8 new patient command test files are untracked (W0 wrote, W1 read-only).
  - C02 tests still GREEN (24 auth + 32 bff_client lines). All 219 tests pass.

## Decisions verdict (response to W1's 10 design decisions)

1. **`_attempt` generalization (single `method`/`body` params).** **ACCEPT.** Smaller surface, easier reasoning, both verbs share the retry-once invariant by construction. No regression in GET tests.
2. **`Object?` body type.** **ACCEPT.** Matches Dio's `data` and lets callers send `Map`, `List`, or already-encoded JSON string. Stronger typing (e.g. `Map<String, Object?>`) would need a serializer hop.
3. **`_patient_helpers.dart` accepting `Object`, not `CliError`.** **ACCEPT.** `Result.error` is statically `Object`; sealed-class downcast (`error as CliError`) is forbidden by `acdg_lints/no_sealed_class_downcast`. Internal `is` narrowing is the right pattern.
4. **Cursor on stderr with `"Next page cursor: <value>"` prefix.** **ACCEPT.** Keeps stdout pipe-clean; downstream `acdg patient list | jq ...` still works. Format is mutable (see N3).
5. **`event_type` (snake_case) on the wire.** **REJECT — see M1.** The W0 §4.3 source claim was wrong. BFF reads `eventType` (camelCase). One-line fix.
6. **YAML→JSON recursive walk.** **ACCEPT.** N1 has a minor refactor sketch but the current code is correct + readable.
7. **Mutually-exclusive guard before file I/O.** **ACCEPT.** Order is right; W0 contradiction test passes.
8. **`PatientCommand.run() = 64` without `printUsage()`.** **ACCEPT.** Test invokes `cmd.run()` directly without a `CommandRunner`; `printUsage()` would NPE on `runner.usage`. Production routes through the runner's `UsageException` path which renders before invoking `run()`.
9. **DTO-faithful body shapes (W0 §4.1).** **ACCEPT** strongly. The DTO is the single source of truth — ticket prose is a sketch. W1 chose correctly.
10. **`_buildBffClient` does NOT wire `tokenClient`/`discovery` yet.** **ACCEPT FOR C03, FLAG FOR C04.** Today `acdg patient list` cannot auto-refresh expired sessions — a 401 surfaces `AuthRequiredError` and the user runs `acdg auth refresh` manually. This is OK for the C03 ticket scope (the W0 401 tests assert the no-token-client path explicitly via `_NullStore`). But: it is the **biggest open-ended debt in C03** — file an explicit STATE.md / C04 entry: "wire `BffClientFactory` with discovery cache + tokenClient so patient verbs auto-refresh." See also S1 (the dead `loadDiscovery` param).

## Contract adherence

- **Spike + W0 §4.1:** all four DTO divergences honored:
  - `discharge_patient_request.dart`: `{reason: required, notes?: optional}` — CLI sends matching shape, no timestamp. ✓
  - `readmit_patient_request.dart`: `{notes?: optional}` only — CLI sends matching shape. ✓
  - `withdraw_patient_request.dart`: `{reason: required, notes?: optional}` — CLI marks `--reason` required + sends matching shape. ✓
  - `admit_patient_request.dart`: `{reason: required, admittedAt: required, notes?: optional}` — CLI sends matching shape. ✓
- **Routes** mounted directly under `/` per `app_router.dart` Cascade — no `/api` prefix. CLI uses `/patients` paths. ✓
- **Audit query param**: **DOES NOT MATCH WIRE — see M1.** `event_type` ≠ `eventType`.

## Routing (REJECTED — round 2 plan)

- **flutter-bff-implementer (W1)** — fix M1 (one line in `patient_audit_command.dart:61`), update W1 REPORT decision §5 to reflect the BFF's actual casing, and re-run `dart test apps/cli/`. Optionally fold S1 (drop `loadDiscovery` param OR document its no-op status) and S2 (reorder imports in `cli_runner.dart:43-46`) into the same round to clear all SHOULD_FIX items at once.
- **test-writer (C10 / next ticket)** — no action this round. The W0 audit test is *permissive* (`qp['event_type'] ?? qp['eventType']`) — that's correct contract-level behavior; it just didn't happen to surface the casing bug. Optional tightening to `qp['eventType']` only would be advisory; deferred.
- After M1 fix, expected state is APPROVED — the rest is polish.
