# C04 — W2 (REVIEW) Round 1

**Verdict:** APPROVED
**Date:** 2026-05-04
**Reviewer:** flutter-code-reviewer (W2)
**Inputs read:** ticket `000-request.md`, W0 `002-tests/REPORT.md`, W1 `003-impl/REPORT.md`, C03 `004-code-review/REVIEW.md` (M1 lesson), all 6 W1 impl files (`bff_client.dart`, `_command_helpers.dart`, 4 `family_*_command.dart`), the parent `family_command.dart`, `cli_runner.dart`, `cli.dart` barrel, all 5 W0 test files (4 family + extended `bff_client_test.dart`), the 4 BFF intents (`add_family_member_intent.dart`, `remove_family_member_intent.dart`, `assign_primary_caregiver_intent.dart`, `update_social_identity_intent.dart`), `patient_audit_command.dart` (regression check on M1).

## Summary

W1 ships a clean, contract-faithful implementation: 277 tests GREEN (was 219 at end of C03; +58 net new C04 tests, of which 57 from W0), `dart analyze apps/cli/` reports `No issues found!`, AOT compile succeeds, `_attempt`/`_refreshAndRetry` generalization scales smoothly to PUT and DELETE without touching the GET/POST paths, and the helper rename was executed cleanly (no shim, all 8 patient command imports updated, C03 patient + C02 auth suites still GREEN). **Critically, the C03 M1 audit casing fix (`query['eventType']`) is preserved post-rename** at `patient_audit_command.dart:64` — no regression. The wire format claims in W0 §3 were re-verified against each of the 4 BFF intents and **all 4 verbs match camelCase keys exactly** — no C03-style M1 surprise this round.

W1 also opportunistically resolved C03 SHOULD_FIX items S1 (the dead `loadDiscovery` param on `_buildBffClient`) and S2 (the import order in `cli_runner.dart`) — the new factory signature at `cli_runner.dart:240` is `_buildBffClient({required CredentialStore credentialStore})` only, and the import block is alphabetical and clean.

## MUST_FIX

None.

## SHOULD_FIX

### S1. Family commands carry an unused `formatter` field (mirrors C03 S3)

- **Locations:**
  - `family_add_command.dart:44,80` — `required this.formatter` ctor + `final OutputFormatter formatter;` field; never invoked.
  - `family_remove_command.dart:19,30` — same pattern; verb returns 204.
  - `family_assign_caregiver_command.dart:22,33` — same pattern.
  - `family_update_identity_command.dart:31,47` — same pattern.
- **Issue:** all 4 verbs return 204 No Content (or no formatted output at all), so `formatter` is wired through the ctor + held as a `final` field but never called. `dart analyze` does not flag public fields as unused, so this stays GREEN. Identical to C03 S3 which deferred to C10.
- **Why it's not a MUST_FIX:** W0 §"Public surface" declared the `required this.formatter` shape and the family test fixtures pass it explicitly (`formatter: const JsonFormatter()`). Removing it now would break W0 contract; the fix is a coordinated W0+W1 update once the C10 formatter resolver lands at the runner level.
- **Defer to:** **C10** (formatter resolver). When global `--output` lands and a single `OutputFormatter` lives at the runner level, the four 204-only commands stop needing it as a ctor dependency, and W0 fixtures loosen in lockstep. **Do NOT block C04 on this.**
- **Routing:** test-writer (C10 / next ticket) for contract loosening; flutter-bff-implementer follows.

### S2. `--member-cpf` ↔ `--member-person-id` mutual-exclusion not guarded client-side

- **Location:** `family_add_command.dart:60-69,121-122`.
- **Issue:** the help text on `--member-person-id` says "Existing person id; mutually exclusive with --member-cpf", but the `run()` method does not enforce it — both flags can be set simultaneously and the BFF resolves precedence (W1 REPORT §"Open questions" #1). Same pattern that C03 W2 ACCEPTED for `patient register` (mutually-exclusive `--from-yaml` + flag-set check at `patient_register_command.dart:91-96`) — there it WAS enforced; here it is NOT.
- **Why it's not a MUST_FIX:** the BFF's intent (`add_family_member_intent.dart:80`) takes `memberPersonId` as the source of truth (defaults to `''`), and the AddFamilyMemberUseCase resolves CPF → person id when present. So the user gets a deterministic outcome — the precedence is just a server-side fait accompli. W0 has no test asserting client-side rejection, so the contract is permissive.
- **Defer to:** next family-add iteration (or C10 when client-side validation pass becomes uniform). Cheap to add (~5 lines mirroring `patient_register_command.dart:91-96`).
- **Routing:** flutter-bff-implementer (future ticket); test-writer optional tightening.

### S3. `--required-document` accepts arbitrary strings without lookup validation

- **Location:** `family_add_command.dart:73-76,124-125`.
- **Issue:** the multi-option is forwarded verbatim to the BFF, which delegates lookup validation to the upstream Registry contract. No client-side allow-list. W1 REPORT §"Open questions" #2 explicitly defers this. Same trade-off as C03 — server-side validation is the canonical authority.
- **Why it's not a MUST_FIX:** intentional design decision; lookup tables live server-side and a stale client allow-list would create drift. W0 has no test demanding client-side validation.
- **Defer to:** if a CLI-level lookup cache is ever introduced (post C09 / C10).
- **Routing:** flutter-bff-implementer (future).

### S4. `--bff` global flag still hardcoded (debt inherited from C02/C03)

- **Location:** `cli_runner.dart:101,240-242`.
- **Issue:** the runner declares `--bff` (default `http://localhost:3000`) at line 80 but `_buildBffClient` ignores the parsed value. Bug existed in C02 and C03; C04 inherits it. W1 did NOT fix it (out of C04 scope) — same advisory as C03 S4.
- **Defer to:** C10 alongside the formatter resolver — both flags need the same "resolve-flag-then-construct-late" pattern. STATE.md should carry a debt note.
- **Routing:** flutter-bff-implementer (future ticket).

## NICE_TO_HAVE

### N1. `family add` saga 5xx UX hint hardcodes the `acdg patient get` recovery command

- **Location:** `family_add_command.dart:151-157`.
- **Observation:** the recovery hint says "check via 'acdg patient get $patientId' or retry." — fine today, but if the executable name ever changes (`acdg` → `conecta-raros` etc.), the hint goes stale. The runner exposes `_executableName` at `cli_runner.dart:60` as a single source of truth — a future iteration could thread it through. Minor; not worth a fix today.

### N2. The `formatter` import in family commands is dead weight today

- **Locations:** `family_add_command.dart:36`, `family_assign_caregiver_command.dart:14`, `family_remove_command.dart:11`, `family_update_identity_command.dart:23`.
- **Observation:** companion to S1 — the import only exists to satisfy the field type. When S1 lands, these imports go away too. No action needed.

### N3. Saga 5xx hint copy is permissive ("500" substring) — could be tightened

- **Location:** `family_add_command_test.dart:323` asserts `stderr.toString().contains('500')`. That literal exists in both the standard error message ("Server error (500): ...") AND the saga hint ("HTTP 500."). The saga-specific hint isn't directly asserted by any test, so a future regression that drops the hint won't fire RED. W1 REPORT §"Decisions" #7 acknowledges this. If the hint matters, a stronger assertion (e.g. `contains('partially modified')`) would tighten the contract — defer to next family iteration if the recovery hint copy stabilizes.

## Confirmations (what passed)

### Architecture
- **Result<T> end-to-end:** every family command's `run()` ends in a sealed switch on `Success`/`Failure`. No `throw` outside adapter boundaries. `usageException(...)` is the args-package surface for missing/invalid CLI flags — semantically a control-flow exit, not a domain exception.
- **`try/catch` audit (W1 §"Try/catch audit") accurate:** confirmed via `grep "try\|catch"` over `family_*.dart` and `_command_helpers.dart` — zero hits. The single adapter-boundary catch at `bff_client.dart:202-244` (Dio HTTP + JSON parse) is unchanged from C03 and now serves PUT + DELETE too.
- **Constructor injection only:** `BffClient`, `OutputFormatter`, optional `StringSink` for `stdout`/`stderr` — no service locator, no singletons.
- **`final class`** on every family command class + the parent + `_PlaceholderCommand`. `BffClient` was already `final class` from C02.
- **StringSink injection on commands:** every family command takes optional `StringSink? stdout` and `StringSink? stderr` and uses local `_writeOut`/`_writeErr` helpers that swallow when sink is null. No direct `Stdio.stdout` writes inside `run()`.
- **No `print(...)`** in `apps/cli/lib/src/commands/family_*` or `_command_helpers.dart` — confirmed via `grep`.
- **Imports SDK → external → relative; alphabetical within block** — confirmed across all 4 family commands + `family_command.dart` parent + `cli_runner.dart` (cleanly reordered post C03 S2).

### `BffClient.put<T>` and `delete<T>` (CRITICAL)
- **PUT body serialized as JSON:** `bff_client.dart:217` sets `contentType: Headers.jsonContentType` when `body != null`. PUT path always passes `body` through.
- **DELETE has no `body` parameter on public API:** `bff_client.dart:172-175` declares only `(path, {decode})`. Internally `_attempt` is called with `body: null`. W0 test `does NOT send a body on the wire` (line 1089-1116 of `bff_client_test.dart`) asserts `adapter.lastOptions!.data` is null/empty — passes.
- **Bearer header attached on both verbs:** the `onRequest` interceptor at `bff_client.dart:56-66` runs for every Dio request regardless of method — verified by W0 tests `attaches Authorization: Bearer on PUT too` (line 805) and `attaches Authorization: Bearer on DELETE too` (line 1144).
- **401 → refresh once → retry once:** PUT path explicitly threads `body` through `_refreshAndRetry({..., body: body})` at `bff_client.dart:158-163`; DELETE threads `body: null`. W0 test `401 → refresh → retries PUT once with new bearer + same body` (line 837-903) asserts `adapter.captured[1].data` carries the original body. W0 test `401 → refresh → retries DELETE once with new bearer + same path` (line 1173-1234) asserts retry hits the same path.
- **4xx (not 401) → `Failure(ServerError)`. NO retry:** W0 PUT 422 test (line 973-1020) asserts `tokenClient.refreshCalls == 0` and `adapter.calls == 1`; W0 DELETE 404 test (line 1273-1318) asserts the same.
- **`RefreshTokenInvalidError` → clear store + AuthRequiredError:** `bff_client.dart:265-270` — same code path as C03 GET/POST. W0 tests (PUT line 905-941, DELETE line 1236-1271) both assert `await store.read() == null`.
- **NO regression to GET/POST:** C02 GET tests + C03 POST tests still GREEN. Confirmed via `dart test` → `+277: All tests passed!`.
- **Refresh path invoked AT MOST ONCE per request:** the persistent-401 test (line 1368-1419) asserts `tokenClient.refreshCalls == 1` and `adapter.calls <= 2` for DELETE. Same invariant by construction for PUT (the retry path returns Failure on second 401 at `bff_client.dart:283-285` without re-entering `_refreshAndRetry`).

### Helper rename
- **`_patient_helpers.dart` → `_command_helpers.dart`** — clean rename. `ls apps/cli/lib/src/commands/_*.dart` shows only `_command_helpers.dart` and `_stub_command.dart` (the latter is from C01, untouched). **No backwards-compat shim.**
- **All 8 patient_*_command.dart imports updated** — confirmed via `grep "_patient_helpers\|_command_helpers"` across `patient_*.dart`. All 8 files import `_command_helpers.dart`.
- **No logic changes** — the helper file still exports `exitCodeFor`, `stderrMessageFor`, `dropNulls` with byte-identical bodies (lines 28-35, 39-57, 64-67 of `_command_helpers.dart`).
- **C03 patient + C02 auth tests still GREEN** — `dart test` shows `+277: All tests passed!` (was 219 + 58 = 277 expected).
- **Was the rename allowed?** YES — W0 §"Helper extraction decision" explicitly authorized it when byte-identical, and W1 honored that constraint. The rename is the right move now (rather than later, when assessment/care/protection ship and the diff balloons).

### Family commands — security + correctness
- **No JWT decoding** anywhere in family commands (search confirms).
- **No raw token logging** — no `print` of tokens; only `Bearer <token>` lands in the Dio interceptor header. Stderr error messages never include tokens.
- **Patient ID + memberId encoded as path segments:** `family_remove_command.dart:57` interpolates as `'/patients/$patientId/family-members/$memberId'`. Same convention as C03 (Dio does not re-encode); UUID-only inputs from `args` don't introduce special chars. `Uri.encodeComponent` would be marginally safer but matches C03's accepted trade-off.
- **No query params** on any family verb — confirmed.
- **`dropNulls` handling on `update-identity`:** `family_update_identity_command.dart:75-78` builds `{typeId, description?}` and pipes through `dropNulls(...)`. W0 test at `family_update_identity_command_test.dart:136` asserts `body.containsKey('description'), isFalse` when flag absent — passes.
- **`--description-from-file` correctly NOT in this ticket** — W1 REPORT §"Open questions" defers to C10 alongside `patient register --from-yaml`-style readers.

### Tests
- **W1 did NOT modify any W0 test file.** All 5 W0 family/bff-client test files come from W0; W1 read-only. Helper rename did not require any test file edits because tests import the family commands' public API, not the private helper.
- **C02 + C03 tests still GREEN.** Auth: 24 tests; bff_client: 41 (was 32; W0 added 9 PUT + 10 DELETE = 19, but the totals reflect the merged file). Patient: 86 (52 commands + parent). Family: 38 (W0). Other: ~88 (formatters, oidc, runner, session). Total: 277.
- **Total: 277 GREEN.** Threshold ≥ 277 met exactly.

### Specific watchouts
- **`family add` saga 5xx UX:** ✓ — `family_add_command.dart:151-157` writes a saga-specific recovery hint after the standard error message when `error is ServerError && error.statusCode >= 500`. The W0 test at line 322-323 asserts `stderr.toString().contains('500')` — the standard `stderrMessageFor` line "Server error (500): ..." satisfies this, and the additional saga hint is layered on top. Both `_writeErr` calls land in the same `stderr` sink (or `stdout` fallback when stderr is null).
- **C03 patient `event_type` regression check:** ✓ — `patient_audit_command.dart:64` reads `query['eventType'] = eventType;`. The doc at lines 5-6 explicitly references the M1 finding ("BFF reads `query['eventType']`. W0 §4.3 source claim of snake_case was wrong"). M1 fix is preserved post-rename.
- **`_attempt` retry-once invariant on PUT/DELETE:** ✓ — verified via W0 `persistent 401 (refresh succeeds, retry still 401) → no infinite loop` test for DELETE (line 1368-1419). Asserts `tokenClient.refreshCalls == 1` and `adapter.calls <= 2`. Same invariant by code construction for PUT (the `_refreshAndRetry` recursion guard at `bff_client.dart:283-285` short-circuits on second 401 to `Failure(AuthRequiredError())` without recursing into `_refreshAndRetry`).

## Decisions verdict (response to W1's 10 design decisions)

1. **Helper rename `_patient_helpers.dart` → `_command_helpers.dart`.** **ACCEPT.** Right move now; renaming once early avoids a noisier diff when assessment/care/protection ship. C03 W2 explicitly anticipated this when the helper outgrew the patient namespace. All 8 patient imports updated cleanly; no shim; tests still GREEN.

2. **`_attempt` shape unchanged (`method` already accepts arbitrary verbs).** **ACCEPT.** Smaller surface, easier reasoning. PUT and DELETE drop in via the existing parameter. No regression in GET/POST tests.

3. **`delete<T>` exposes no `body` parameter on public API.** **ACCEPT.** Matches HTTP convention (DELETE bodies are advisory) and W0 §2.2 contract. Internally passes `null` to `_attempt`. W0 tests `does NOT send a body on the wire` and the 401-retry path explicitly assert this invariant.

4. **Flag `--member-id` → wire `memberPersonId` for assign-caregiver.** **ACCEPT.** UI-symmetric with `family remove --member-id`; the wire-key remap is invisible to the user and the BFF intent (`assign_primary_caregiver_intent.dart:39`) reads `memberPersonId`. W0 §4.7 endorsed this.

5. **`--full-name` over ticket-prose `--first-name`.** **ACCEPT.** DTO-as-canon. The BFF `add_family_member_intent.dart:95` reads `body['fullName']` directly. The C03 lesson (DTO is the single source of truth, ticket prose is a sketch) applies cleanly here.

6. **`update-identity` collapses to `--type-id` REQUIRED + `--description` optional.** **ACCEPT.** The BFF `update_social_identity_intent.dart:40` requires non-empty `typeId` and treats `description` as optional. Ticket prose (`--gender --pronoun`) reflected an older domain model; the DTO is current. CLI follows DTO. **dropNulls correctly omits `description` when flag absent** — W0 test asserts.

7. **5xx saga UX hint copy on `family add`.** **ACCEPT.** The hint at `family_add_command.dart:151-157` correctly fires only for `>= 500` and points the user at `acdg patient get $patientId` for inspection, plus suggests retry. Permissive copy ("contains 500") is fine for now; tightening to assert the recovery phrase is a NICE_TO_HAVE.

8. **No client-side saga rollback.** **ACCEPT.** BFF responsibility per W0 §4.6. The CLI surfaces the failure clearly; a client-side compensation would create more confusion than it solves (the partial state is already on the server side and only the BFF / the operator know what's recoverable).

9. **Permissive default flags (`is-residing`, `is-caregiver`, `has-disability` as `false`; `requiredDocuments` as `[]`).** **ACCEPT.** Sends explicit bool false / empty list rather than omitting; matches the BFF intent's `_asBool(...)` (defaults missing to `false`) and `_asStringList(...)` (defaults missing to `[]`) coercions. Wire-format symmetry confirmed at `add_family_member_intent.dart:83-88`.

10. **`stdout` confirmation line on `family remove` 204.** **ACCEPT.** Useful UX feedback that the operation completed; the W0 test asserts `stdout` is not null (permissive) which keeps the wording mutable. Could move under `--quiet` once C10 lands; deferred.

## Wire format adherence (verified against BFF intents)

Each verb verified by reading the BFF intent file and confirming the exact key strings W1 sends.

### `family add` POST `/patients/{id}/family-members`
- **CLI sends** (`family_add_command.dart:127-140`): `memberPersonId`, `relationship`, `birthDate`, `prRelationshipId`, `isResiding`, `isCaregiver`, `hasDisability`, `requiredDocuments`, `cpf`, `fullName` — all camelCase, all top-level.
- **BFF reads** (`add_family_member_intent.dart:70-95`): same keys, same casing, same top-level shape (`cpf`/`fullName` are top-level on the body, NOT nested under `request` — confirmed at lines 94-95).
- **Verdict:** **CONFIRMED.** No M1-style casing surprise.

### `family remove` DELETE `/patients/{id}/family-members/{memberId}`
- **CLI sends** (`family_remove_command.dart:56-58`): no body. Path encodes `<id>` and `<memberId>` as positional segments.
- **BFF reads** (`remove_family_member_intent.dart:37-46`): two route params (`rawPatientId`, `rawMemberId`); no body parsing.
- **Verdict:** **CONFIRMED.** DELETE no-body invariant matches.

### `family assign-caregiver` PUT `/patients/{id}/primary-caregiver`
- **CLI sends** (`family_assign_caregiver_command.dart:61-64`): `{'memberPersonId': memberId}`.
- **BFF reads** (`assign_primary_caregiver_intent.dart:38-48`): `body case {'memberPersonId': final String memberPersonId} when memberPersonId.isNotEmpty`.
- **Verdict:** **CONFIRMED.** Exact key spelling match (`memberPersonId`).

### `family update-identity` PUT `/patients/{id}/social-identity`
- **CLI sends** (`family_update_identity_command.dart:75-83`): `{'typeId': typeId, 'description'?: description}` (dropNulls).
- **BFF reads** (`update_social_identity_intent.dart:40-49`): `body case {'typeId': final String typeId} when typeId.isNotEmpty`; reads `body['description']` via `_asNullableString` (line 46 → 59-60: returns null if not a non-empty String).
- **Verdict:** **CONFIRMED.** Exact key spelling match. dropNulls behavior correctly aligns with the intent's `_asNullableString` coercion (sending `null` would also be coerced to `null`, but omission is the cleaner contract).

**No M1-style casing or key-name surprises detected this round.**

## Routing (APPROVED — no round 2 needed)

- **flutter-bff-implementer (W1)** — no MUST_FIX. The 4 SHOULD_FIX items are all defer-to-future-ticket / contract-coordination items: S1 (formatter field) → C10; S2 (mutual-exclusion guard) → next family iteration; S3 (lookup validation) → future post-C10; S4 (BFF flag wiring) → C10 alongside formatter resolver. None block this ticket.
- **test-writer** — no action this round. W0 tests are well-scoped and the contract surface is faithful to the BFF intents (lesson from C03 M1 applied successfully — W0 §3 was right this time).
- **flutter-quality-checker (W3)** — green light to proceed. `dart analyze` clean, `dart format` clean (per W1 REPORT), AOT compile succeeds, 277 tests GREEN.

C04 is APPROVED for ticket close.
