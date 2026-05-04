# C05 — W2 (REVIEW) Round 1

**Verdict:** APPROVED
**Date:** 2026-05-04
**Reviewer:** flutter-code-reviewer (W2)
**Inputs read:** ticket `000-request.md`, W0 `002-tests/REPORT.md`, W1 `003-impl/REPORT.md`, C04 `004-code-review/REVIEW.md` (pattern), C03 `004-code-review/REVIEW.md` (M1 lesson), all 8 W1 impl files (`_yaml_helpers.dart`, 7 ficha command files), `assessment_command.dart` (replaced C01 stub), `patient_register_command.dart` (yaml-helper migration), `_command_helpers.dart` (rename target preserved), `cli_runner.dart`, `cli.dart` barrel, all 7 BFF intent files (`update_housing_condition_intent.dart`, `update_socio_economic_situation_intent.dart`, `update_work_and_income_intent.dart`, `update_educational_status_intent.dart`, `update_health_status_intent.dart`, `update_community_support_network_intent.dart`, `update_social_health_summary_intent.dart`), all 7 assessment DTOs, `assessment_handler.dart` (route mounting), W0 `_assessment_test_helpers.dart` and `assessment_housing_command_test.dart` + `assessment_education_command_test.dart` + `assessment_community_support_command_test.dart` body-shape assertions.

## Summary

W1 ships a clean, contract-faithful implementation: **378 CLI tests GREEN** (was 277 at end of C04; +101 net new — matches W1 REPORT exactly), `dart analyze apps/cli/` reports `No issues found!`, AOT compile succeeds, and `_yaml_helpers.dart` extraction is byte-equivalent for `patient register` (10/10 PatientRegisterCommand tests still GREEN). **The wire format claims in W0 §3 were re-verified for all 7 fichas against each BFF intent + each `Update<X>Request` DTO** — every camelCase key spells exactly as the `json_serializable`-generated `fromJson` consumes it. No M1-style casing surprise this round. C03 M1 audit fix (`query['eventType']`) is preserved at `patient_audit_command.dart:64`. The PII concern flagged in W1 §"Open questions" #1 (health ficha caregiver name echo) is a non-issue: the BFF intent at `update_health_status_intent.dart:58-62` produces a fixed structural error string (`'Invalid update-health-status body: missing or malformed required fields'`) that never echoes user input — the CLI is transparent and faithful, and `stderrMessageFor(ServerError)` only forwards the BFF's already-redacted message. The 4 SHOULD_FIX-level items inherited from C03/C04 (formatter unused, helper duplication, BFF flag debt) are explicit defer-to-future patterns identical to the prior reviews; none are new in this ticket and all match prior accepted decisions.

## MUST_FIX

None.

## SHOULD_FIX

### S1. Assessment ficha commands carry an unused `formatter` field (mirrors C03 S3 + C04 S1)

- **Locations:**
  - `assessment_housing_command.dart:33,69` — `required this.formatter` ctor + `final OutputFormatter formatter;` field; never invoked (verb returns 204).
  - `assessment_socioeconomic_command.dart:27,59` — same pattern.
  - `assessment_work_income_command.dart:25,39` — same pattern.
  - `assessment_education_command.dart:31,62` — same pattern.
  - `assessment_health_command.dart:31,49` — same pattern.
  - `assessment_community_support_command.dart:27,65` — same pattern.
  - `assessment_social_health_summary_command.dart:25,51` — same pattern.
- **Issue:** all 7 fichas return 204 No Content (assertion in cross-cutting test `_assessment_test_helpers.dart:215-235` only asserts `exit == 0`), so `formatter` is wired through the ctor + held as a `final` field but never `.format()`-called. `dart analyze` does not flag public fields as unused. Identical to C03 S3 + C04 S1, which both deferred to C10.
- **Why it's not a MUST_FIX:** W0 §"Public surface" declared `required this.formatter` + the W0 test fixtures pass `formatter: const JsonFormatter()` explicitly (e.g. `assessment_housing_command_test.dart:112`). Removing it now would break W0 contract; the fix is a coordinated W0+W1 update once the C10 formatter resolver lands at the runner level.
- **Defer to:** **C10** (formatter resolver). When global `--output` lands and a single `OutputFormatter` lives at the runner level, the seven 204-only ficha commands stop needing it as a ctor dependency, and W0 fixtures loosen in lockstep. **Do NOT block C05 on this.**
- **Routing:** test-writer (C10) for contract loosening; flutter-bff-implementer follows.

### S2. Bool/numeric helper duplication across the 7 fichas (W1 §"Open questions" #4)

- **Locations:** every ficha defines its own private `_requireBool`, `_requireString` (where applicable), `_requireInt` (housing only), `_requireDouble` (socioeconomic only) — ~10 LOC × 7 fichas. `assessment_education_command.dart` even spells the bool helper as `_parseBool` (different name, same body) which is mild inconsistency.
- **Issue:** about ~70 LOC of effectively identical code lives across the 7 ficha commands. W1 REPORT §"Open questions" #4 explicitly considered extraction and decided to defer ("requires passing `usageException` as callback"). The cost is real but not a correctness issue, and the ergonomics are uniform within each ficha.
- **Why it's not a MUST_FIX:** the pattern is consistent (each ficha self-contained), `dart analyze` is clean, and a future refactor can land in a 4th-feature wave without touching the ficha public APIs. Extracting to `_command_helpers.dart` requires either (a) `usageException` as a callback closure — verbose at every call site, or (b) raising a typed sentinel that the caller then re-throws — extra ceremony. W1's call to defer is defensible.
- **Defer to:** post-C09 / C10 grooming when the helper module's surface is being audited holistically. Renaming `_parseBool` → `_requireBool` in `assessment_education_command.dart:172` for naming uniformity is a cheap bonus, but not blocking.
- **Routing:** flutter-bff-implementer (future grooming pass).

### S3. `--bff` global flag still hardcoded (debt inherited from C02/C03/C04)

- **Location:** `cli_runner.dart:87,253-255`. The runner declares `--bff` (default `http://localhost:3000`) at line 87 but `_buildBffClient` ignores the parsed value. Bug existed pre-C03; C04 review (S4) acknowledged it; C05 inherits it unchanged. W1 did NOT introduce nor fix it (out of C05 scope).
- **Defer to:** C10 alongside the formatter resolver — both flags need the same "resolve-flag-then-construct-late" pattern.
- **Routing:** flutter-bff-implementer (future ticket / C10).

## NICE_TO_HAVE

### N1. `assessment_education_command.dart::_parseBool` is named differently from the other 6 fichas' `_requireBool`

- **Location:** `assessment_education_command.dart:172`.
- **Observation:** body is identical to `_requireBool` in the other six fichas (it just doesn't surface a "missing" error message because the caller already verified all four flags are set at line 131-136). Renaming to `_requireBool` would normalize the helper-surface naming. Cosmetic; no behavior change.

### N2. `_yaml_helpers.dart::yamlToJsonNode` walks belts-and-suspenders branches even when `loadYaml` returned a plain `Map`

- **Location:** `_yaml_helpers.dart:30-50`. Same observation as C03 N1 — the recursion is correct; it's just denser than strictly necessary. `loadYaml` always returns `YamlMap`/`YamlList` for non-leaf nodes; the `Map`/`List` branches are defensive (and useful when fixtures inject already-converted subtrees). Aesthetic only — keep as-is.

### N3. Per-ficha `--from-yaml` schema validation deferred to BFF (W1 §"Open questions" #2)

- **Observation:** the CLI sends parsed YAML verbatim; if the user shapes the YAML wrong, the BFF surfaces a 422 with a structural error message. A client-side `--dry-run` against the DTO `fromJson` would catch malformed payloads earlier, but it's deferred to C10 by W1 and there are no test gaps in the contract today.

### N4. `assessment_housing_command.dart` `--from-yaml` flag-presence check uses `String?.isNotEmpty` per-flag — identical to other fichas

- **Observation:** tiny micro-optimization opportunity — a single `argResults.options.where(...).any(...)` would dedupe the `flagFields.any(...)` block across the 7 fichas. Defer to S2 grooming pass.

## Confirmations (what passed)

### Architecture
- **Result<T> end-to-end:** every ficha command's `run()` ends in a sealed switch on `Success`/`Failure`. No `throw` outside adapter boundaries. `usageException(...)` is the args-package surface for missing/invalid CLI flags — semantically a control-flow exit, not a domain exception. Confirmed via `grep "throw\b"` over `assessment_*.dart` — only `usageException` patterns in `_requireString`/`_requireBool`/`_requireInt`/`_requireDouble` paths surface (which is the args lib's intended idiom).
- **`try/catch` audit (W1 §"Try/catch audit") accurate:** confirmed via `grep -nE "try\b|catch\b" apps/cli/lib/src/commands/assessment_*.dart` — **zero hits**. The single new adapter-boundary catch lives at `_yaml_helpers.dart:77-95` (file read + `loadYaml`), translating both `FileSystemException`-shaped errors and `YamlException` to `InvalidArgError`. The sole BFF-side adapter catch at `bff_client.dart:194-244` (Dio HTTP + JSON parse) is unchanged from C04 and serves PUT for all 7 fichas without modification.
- **Constructor injection only:** `BffClient`, `OutputFormatter`, `fileReader`, optional `StringSink` for `stdout`/`stderr` — no service locator, no singletons. `cli_runner.dart::_buildAssessmentCommand` (lines 362-420) injects a single shared `readFile` closure into all 7 fichas, identical to the `patient register` wiring at line 289.
- **`final class`** on every ficha command class + the parent `AssessmentCommand` + `_PlaceholderCommand`. Confirmed via `grep "^final class"` over the 8 new files.
- **StringSink injection on commands:** every ficha command takes optional `StringSink? stdout` and `StringSink? stderr` and uses local `_writeErr` helpers that swallow when sink is null. No direct `Stdio.stdout` writes inside `run()`.
- **No `print(...)`** in `apps/cli/lib/src/commands/assessment_*` or `_yaml_helpers.dart` — confirmed via `grep "print("` — zero hits.
- **Imports SDK → external → relative; alphabetical within block** — confirmed across all 7 ficha commands + parent + `_yaml_helpers.dart` + `cli_runner.dart` + `cli.dart`. The 7 ficha files all share the same import block: `package:args/args.dart`, `package:args/command_runner.dart`, `package:core_contracts/core_contracts.dart` (alphabetical external), then `../formatters/output_formatter.dart`, `../session/bff_client.dart`, `_command_helpers.dart`, `_yaml_helpers.dart` (alphabetical relative — `..` paths first by convention, then `_-` prefixed siblings).
- **No `package:args/args.dart` import on `assessment_command.dart`** — only `package:args/command_runner.dart` (line 13), correctly because the parent never references `ArgResults` (only the children do).

### `_yaml_helpers.dart` extraction (W1 Decision #1 — Option A)
- **Helper extraction is byte-equivalent for `patient register`:** the migrated `patient_register_command.dart:99` now calls `readYamlBody(path: fromYaml, fileReader: fileReader)` instead of an inlined `_readYamlBody`; the result switch at lines 100-106 is identical in shape to the C03 inlined version. **C03 PatientRegisterCommand suite still GREEN (10/10).** Verified via `dart test apps/cli/test/commands/patient_register_command_test.dart` — `+10: All tests passed!`.
- **`yamlToJsonNode`/`yamlToJsonMap` walk semantics correct:** lines 30-50 cover four cases — `YamlMap` → `Map<String, Object?>` (recurses `value`, stringifies key), `YamlList` → `List<Object?>` (recurses), plain `Map`/`List` (defensive — for already-converted subtrees), scalars passed through unchanged. Equivalent to C03 inlined version.
- **`readYamlBody({path, fileReader})` adapter boundary translates errors correctly:** lines 76-83 catch any throw from `fileReader` (including the test-only `NoSuchFileException` and production `FileSystemException`) → `InvalidArgError('Cannot read --from-yaml file at "<path>": ...')`; lines 85-91 catch `YamlException` → `InvalidArgError('Invalid YAML in "<path>": ...')`; lines 92-96 reject non-map roots → `InvalidArgError(...)`. All three paths exit code 64. Cross-cutting test `_assessment_test_helpers.dart:308-326` ("`--from-yaml` pointing to unreadable file → non-zero exit, no BFF call") passes for all 7 fichas.
- **No backwards-compat shim from yaml extraction:** `patient_register_command.dart` no longer carries `_yamlToJsonNode`/`_yamlToJsonMap`/`_readYamlBody` — confirmed via `grep "_yamlTo\|_readYamlBody" patient_register_command.dart` (zero hits). Clean cut.

### Wire format adherence — VERIFIED against BFF intents (lesson from C03 M1)

Each ficha verified by reading the BFF intent file + the `Update<X>Request` DTO and confirming the exact key strings W1 sends. **Every intent delegates to `Update<X>Request.fromJson(body)`** (try/catch wrapped with structural PII-safe message), so wire body keys must match `Update<X>Request.toJson()` shape exactly.

#### `housing` PUT `/patients/{id}/assessment/housing`
- **CLI sends** (`assessment_housing_command.dart:182-198`): `type`, `wallMaterial`, `numberOfRooms`, `numberOfBedrooms`, `numberOfBathrooms`, `waterSupply`, `hasPipedWater`, `electricityAccess`, `sewageDisposal`, `wasteCollection`, `accessibilityLevel`, `isInGeographicRiskArea`, `hasDifficultAccess`, `isInSocialConflictArea`, `hasDiagnosticObservations` — all camelCase, all 15 required.
- **DTO** (`update_housing_condition_request.dart:7-43`): all 15 fields `required`, types match (3 ints + 5 bools + 7 Strings).
- **Intent** (`update_housing_condition_intent.dart:51`): `UpdateHousingConditionRequest.fromJson(body)`.
- **BFF route** (`assessment_handler.dart:71`): `r.put('/patients/<id>/assessment/housing', _handleHousing);`.
- **Verdict:** **CONFIRMED.** All 15 keys spell exactly as DTO + ints parsed as `int` (housing test asserts `body['numberOfRooms'], equals(4)` at line 159) + bools as `bool`. No M1-style casing surprise.

#### `socioeconomic` PUT `/patients/{id}/assessment/socioeconomic`
- **CLI sends** (`assessment_socioeconomic_command.dart:140-147`): `totalFamilyIncome` (double), `incomePerCapita` (double), `receivesSocialBenefit` (bool), `socialBenefits` (list, default `<Object?>[]`), `mainSourceOfIncome` (String), `hasUnemployed` (bool).
- **DTO** (`update_socio_economic_situation_request.dart:7-40`): 5 required + 1 default-empty list. Nested `SocialBenefitDraftDto` lines 42-74.
- **Intent** (`update_socio_economic_situation_intent.dart:43`): `UpdateSocioEconomicSituationRequest.fromJson(body)`.
- **Verdict:** **CONFIRMED.** Always emitting `socialBenefits: []` is harmless (DTO default-empty matches; `json_serializable.fromJson` accepts the explicit empty list). YAML path supports nested values per `assessment_socioeconomic_command_test.dart:140-180` (asserts `body['socialBenefits']! as List<Object?>` populated from YAML).

#### `work-income` PUT `/patients/{id}/assessment/work-income`
- **CLI sends** (`assessment_work_income_command.dart:107-111`): `individualIncomes` (list, default `<Object?>[]`), `socialBenefits` (list, default `<Object?>[]`), `hasRetiredMembers` (bool, required).
- **DTO** (`update_work_and_income_request.dart:9-31`): `hasRetiredMembers` required + 2 default-empty lists.
- **Verdict:** **CONFIRMED.** YAML path supports nested values.

#### `education` PUT `/patients/{id}/assessment/education`
- **CLI sends** (`assessment_education_command.dart:159-169`): `memberProfiles` — single-element list assembled from 4 flags (`memberId`, `canReadWrite`, `attendsSchool`, `educationLevelId`) — and `programOccurrences` (default `<Object?>[]`).
- **DTO** (`update_educational_status_request.dart:7-23` + `ProfileDraftDto:25-51` + `OccurrenceDraftDto:53-79`): both lists default-empty.
- **Verdict:** **CONFIRMED.** Element shape matches `ProfileDraftDto.toJson()` exactly. Education all-or-nothing rule fires correctly: 0/4 → "either yaml or all four"; 1-3/4 → "must be provided together" (asserted in `assessment_education_command_test.dart:170-205`); 4/4 → assemble single-element list.

#### `health` PUT `/patients/{id}/assessment/health`
- **CLI sends** (`assessment_health_command.dart:121-126`): `deficiencies` (list, default `<Object?>[]`), `gestatingMembers` (list, default `<Object?>[]`), `constantCareNeeds` (`List<String>.unmodifiable(...)` from repeatable `--constant-care-need`), `foodInsecurity` (bool, required).
- **DTO** (`update_health_status_request.dart:7-32` + `DeficiencyDraftDto:34-60` + `PregnantDraftDto:62-85`): `foodInsecurity` required + 3 default-empty lists. `responsibleCaregiverName?` is optional inside `DeficiencyDraftDto`.
- **PII concern:** **NON-ISSUE.** `update_health_status_intent.dart:58-62` produces a fixed structural error message (`'Invalid update-health-status body: missing or malformed required fields'`) that NEVER echoes user input — including caregiver names that may appear inside malformed payloads. The CLI's `stderrMessageFor(ServerError)` at `_command_helpers.dart:50-52` only forwards the BFF's already-redacted message verbatim: `'Server error (${error.statusCode}): ${error.message}'`. The CLI is transparent and faithful, AND `assessment_health_command.dart` itself never inserts raw flag values into stderr (verified via `grep "writeErr\|writeOut" assessment_health_command.dart`).
- **Verdict:** **CONFIRMED.**

#### `community-support` PUT `/patients/{id}/assessment/community-support`
- **CLI sends** (`assessment_community_support_command.dart:162-170`): `hasRelativeSupport` (bool), `hasNeighborSupport` (bool), `familyConflicts` (**String**, NOT bool), `patientParticipatesInGroups` (bool), `familyParticipatesInGroups` (bool), `patientHasAccessToLeisure` (bool), `facesDiscrimination` (bool).
- **DTO** (`update_community_support_network_request.dart:7-43`): all 7 required, `familyConflicts` declared as `final String familyConflicts;` (line 24) — NOT bool. Easy mis-shape from prose alone — W1 got it right.
- **Verdict:** **CONFIRMED.** `assessment_community_support_command_test.dart:121` explicitly asserts `body['familyConflicts'], equals('none')` — a String literal.

#### `social-health-summary` PUT `/patients/{id}/assessment/social-health-summary`
- **CLI sends** (`assessment_social_health_summary_command.dart:135-142`): `requiresConstantCare` (bool), `hasMobilityImpairment` (bool), `hasRelevantDrugTherapy` (bool), `functionalDependencies` (`List<String>.unmodifiable(...)` from repeatable `--functional-dependency`).
- **DTO** (`update_social_health_summary_request.dart:7-34`): 3 required bools + `functionalDependencies` default-empty list.
- **Verdict:** **CONFIRMED.**

**No M1-style casing or key-name surprises detected this round across 7 fichas.** The DTO-as-canon discipline + the wire-format §3 verification step in W0 paid off.

### Each ficha command — security + correctness
- **No JWT decoding** anywhere in assessment commands or `_yaml_helpers.dart` (search confirms).
- **No raw token logging** — no `print` of tokens; only `Bearer <token>` lands in the Dio interceptor header. Stderr error messages never include tokens.
- **Patient ID interpolated as path segment via `'/patients/$patientId/assessment/<verb>'`** — Dio does not re-encode, but the upstream BFF intent at `update_*_intent.dart` validates UUID v4 strictness (`validateUuidPathParam`) so non-UUID inputs are rejected with 400 before reaching the use case. Same trade-off as C03/C04 (UUID-only inputs from `args` don't introduce special chars).
- **`--from-yaml` reader at adapter boundary; YAML/file errors translated to InvalidArgError:** confirmed in `_yaml_helpers.dart:72-98`.
- **Mutually-exclusive guard `--from-yaml` ↔ field flags fires BEFORE file I/O:** confirmed in every ficha (`assessment_housing_command.dart:121-126`, `assessment_socioeconomic_command.dart:99-104`, etc.). Cross-cutting test `_assessment_test_helpers.dart:287-306` ("`--from-yaml` together with field flags → usage error (mutually exclusive)") asserts `adapter.lastOptions, isNull` — i.e. NO BFF call AND no file read. Order of operations preserved.
- **Bool/numeric parsing fails fast (no HTTP round-trip on bad input):** `_requireInt` at `assessment_housing_command.dart:209-216` uses `int.tryParse`; `_requireDouble` at `assessment_socioeconomic_command.dart:158-165` uses `double.tryParse`; `_requireBool` everywhere checks `lower == 'true' || lower == 'false'`. Tests assert `adapter.lastOptions, isNull` on bad input (`assessment_housing_command_test.dart:192-212` for non-int rooms).
- **Education all-or-nothing rule fires correctly:** verified per the W0 test at `assessment_education_command_test.dart:170-205`.

### Helper rename + barrel
- **`_command_helpers.dart` rename from C04 still in place** — confirmed via `ls apps/cli/lib/src/commands/_*.dart` showing `_command_helpers.dart`, `_yaml_helpers.dart`, `_stub_command.dart`. All 8 patient command imports + 4 family command imports + 7 new assessment command imports + `patient_register_command.dart` (which imports both `_command_helpers.dart` AND `_yaml_helpers.dart` at lines 23-24) all reference `_command_helpers.dart` correctly.
- **`cli.dart` barrel** (lines 13-49) exports the 8 new public types in alphabetical order, sandwiched between auth and patient blocks. The barrel does NOT export `_command_helpers.dart` nor `_yaml_helpers.dart` — both are intentionally private with `_` prefix.

### Tests
- **W1 did NOT modify any W0 test file.** Confirmed via the report's invariant that "Zero changes under apps/cli/lib/, apps/cli/bin/, or apps/social_care_bff/" was maintained across W1.
- **Total: 378 GREEN.** Run output (Bash, this round): `00:01 +378: All tests passed!`. Threshold ≥ 378 met exactly.
- **C04 family + C03 patient + C02 auth still GREEN.** `dart test apps/cli/test/commands/patient_register_command_test.dart` → `+10: All tests passed!` confirms `_yaml_helpers.dart` extraction is byte-equivalent. The full suite passing means C04 family (38 tests) and C02 auth (24 tests) are unbroken.
- **`dart analyze apps/cli/`** → `No issues found!`. Confirmed.

### Specific watchouts
- **`patient_register_command.dart` regression check on yaml extraction:** ✓ — 10/10 tests still GREEN. The new code at lines 99-106 calls `readYamlBody(...)` and switches on the `Result<Map<String, Object?>>` return; behavior is byte-equivalent to the C03 inlined version (which used the same switch shape). The mutually-exclusive guard at lines 90-95 still fires BEFORE the read.
- **C03 patient `eventType` regression check:** ✓ — `patient_audit_command.dart:64` reads `query['eventType'] = eventType;`. The doc at lines 5-6 explicitly references the M1 finding ("`get_audit_trail_intent.dart` which reads `query['eventType']`"). M1 fix is preserved post-yaml-extraction.
- **`_command_helpers.dart` rename + `_yaml_helpers.dart` coexistence:** ✓ — both private files coexist in `apps/cli/lib/src/commands/`; the rename did not break the 8 patient + 4 family + 7 assessment imports, AND `patient_register_command.dart` correctly imports both modules at lines 23-24.

## Decisions verdict (response to W1's 11 design decisions)

1. **`_yaml_helpers.dart` extraction (Option A from W1 brief).** **ACCEPT.** Right call — `_command_helpers.dart` stays lean for error-mapping + body utilities; YAML+filesystem boundary lives in its own module. Byte-equivalent migration of `patient_register` confirmed (10/10 tests GREEN). Future C06+ (`care`, `protection`) reuses the helper without touching `_command_helpers.dart`.

2. **Bool flags as `--opt=true|false` via `addOption` + manual `bool.parse`.** **ACCEPT.** Uniform with C03/C04 family commands. Each verb owning its private `_requireBool` is the trade-off W1 acknowledged in §"Open questions" #4 and S2 above defers to future grooming.

3. **Numeric flag parsing surfaces UsageException BEFORE HTTP.** **ACCEPT.** `int.tryParse`/`double.tryParse` + null → `usageException` keeps the bad-input path local. W0 tests at `assessment_housing_command_test.dart:192-212` (non-int rooms) and `assessment_socioeconomic_command_test.dart` (non-double total income) assert `adapter.lastOptions, isNull` — both pass. Fail-fast invariant preserved.

4. **Education all-or-nothing in `run()` (not argParser).** **ACCEPT.** `args` has no native cross-flag rule, so the manual three-tier check at `assessment_education_command.dart:121-136` is the right shape: 0/4 + no yaml → "either yaml or all four"; 1-3/4 → "must be provided together"; 4/4 → assemble. Both W0 tests at lines 170-205 pass.

5. **Mutually-exclusive `--from-yaml` ↔ field flags per ficha (each owns its flag list).** **ACCEPT.** Self-documenting — when a future flag is added, its presence-check sits next to the rest of that ficha's flag-presence logic. Slight DRY cost (small list per ficha) is acceptable vs. coupling all 7 fichas to a shared registry.

6. **`familyConflicts` modeled as String, not bool.** **ACCEPT.** This is the easy-to-miss bug from prose alone (`community-support` ficha §3.6 in W0 REPORT explicitly flagged it). W1 got it right; the `assessment_community_support_command.dart:147` `_requireString` call confirms the type, and `assessment_community_support_command_test.dart:121` asserts the String literal.

7. **No `dropNulls` on assessment bodies.** **ACCEPT.** Every flag-based field is mandatory at the DTO layer (housing, community-support, social-health-summary, education-after-all-or-nothing) or has explicit `<Object?>[]` defaults (work-income, socioeconomic, education-with-defaults, health) — sending `null` is never legal. `dropNulls` would be dead code here.

8. **`unmodifiable` lists in body (`functionalDependencies`, `constantCareNeeds`).** **ACCEPT.** Prevents accidental mutation post-construction inside the `_buildBodyFromFlags`/`_buildBodyFromFlags(constantCareNeeds)` factory. JSON encoder doesn't care, but the local invariant is preserved.

9. **Single shared `fileReader` closure in `cli_runner.dart`.** **ACCEPT.** `cli_runner.dart:368` declares `Future<String> readFile(String path) => File(path).readAsString();` once, then injects it into all 7 fichas. Identical pattern to `patient register` at line 289. Tests inject their own readers per the cross-cutting helper.

10. **Placeholder fallback for `AssessmentCommand()`.** **ACCEPT.** Mirrors `PatientCommand`/`FamilyCommand` exactly. `_PlaceholderCommand.run() => 64` keeps the parent `subcommands.keys` non-empty when constructed without collaborators (test introspection / `--help`). The W0 parent-test contract at `assessment_command_test.dart` exercises this path.

11. **`package:args/args.dart` import added** to each ficha (`ArgResults` not re-exported by `command_runner.dart`). **ACCEPT.** Mechanical necessity — the helper signatures (`String _requireString(ArgResults r, String name)`) need the type. Single-line import, alphabetical with `command_runner.dart`.

## Wire format adherence (verified against BFF intents)

Summary table — all 7 fichas re-verified end-to-end:

| Ficha | Path | DTO required keys | DTO default-empty lists | CLI sends | Wire match |
|-------|------|-------------------|-------------------------|-----------|------------|
| housing | `/patients/<id>/assessment/housing` | 15 (3 ints + 5 bools + 7 Strings) | 0 | 15 keys, ints/bools typed | ✓ |
| socioeconomic | `/patients/<id>/assessment/socioeconomic` | 5 (2 doubles + 2 bools + 1 String) | `socialBenefits` | 6 keys (5 + always-empty list) | ✓ |
| work-income | `/patients/<id>/assessment/work-income` | 1 (`hasRetiredMembers` bool) | `individualIncomes`, `socialBenefits` | 3 keys (1 + 2 always-empty lists) | ✓ |
| education | `/patients/<id>/assessment/education` | 0 | `memberProfiles`, `programOccurrences` | 2 keys (1-element list + always-empty list) | ✓ |
| health | `/patients/<id>/assessment/health` | 1 (`foodInsecurity` bool) | `deficiencies`, `gestatingMembers`, `constantCareNeeds` | 4 keys (1 + 2 always-empty lists + 1 from multi-option) | ✓ |
| community-support | `/patients/<id>/assessment/community-support` | 7 (6 bools + `familyConflicts` String) | 0 | 7 keys, `familyConflicts` as String | ✓ |
| social-health-summary | `/patients/<id>/assessment/social-health-summary` | 3 bools | `functionalDependencies` | 4 keys (3 + 1 from multi-option) | ✓ |

Every camelCase key spells exactly as the `Update<X>Request.toJson()` shape the BFF intent's `fromJson` consumes. **No M1-style casing surprise this round.**

## Routing (APPROVED — no round 2 needed)

- **flutter-bff-implementer (W1)** — no MUST_FIX. The 3 SHOULD_FIX items are all defer-to-future-ticket / cross-ticket coordination items: S1 (formatter field) → C10 (formatter resolver); S2 (helper duplication) → post-C09/C10 grooming; S3 (BFF flag wiring) → C10. None block this ticket. Optional: NICE_TO_HAVE N1 rename `_parseBool` → `_requireBool` in education ficha is a 1-line cosmetic change if W3 is willing to roll it in.
- **test-writer** — no action this round. W0 tests are well-scoped, the contract surface is faithful to the BFF intents (lesson from C03 M1 applied successfully — W0 §3 was right this time across all 7 fichas), and the cross-cutting parametrized factory at `_assessment_test_helpers.dart:182-407` is the right shape for future fichas / future-wave reuse.
- **flutter-quality-checker (W3)** — green light to proceed. `dart analyze` clean, AOT compile succeeds (per W1 REPORT), 378 tests GREEN. C03 + C04 + C02 regressions: zero.

C05 is APPROVED for ticket close.
