# C05 — W1 (GREEN) Report

**Agent:** flutter-bff-implementer
**Wave:** 1 — GREEN
**Date:** 2026-05-04
**Status:** All 378 CLI tests pass (was 277 at end of C04; +101 net new). 105 W0 contract tests now GREEN. `dart analyze apps/cli/` returns 0 issues. AOT compile succeeds. `acdg assessment --help` advertises all 7 fichas.

## Files created (8)

1. `apps/cli/lib/src/commands/_yaml_helpers.dart` — shared YAML→JSON conversion (`yamlToJsonNode`, `yamlToJsonMap`) + `readYamlBody({path, fileReader})` adapter helper.
2. `apps/cli/lib/src/commands/assessment_housing_command.dart` — PUT `/patients/{id}/assessment/housing` (15 required scalars).
3. `apps/cli/lib/src/commands/assessment_socioeconomic_command.dart` — PUT (5 required + default-empty `socialBenefits[]`).
4. `apps/cli/lib/src/commands/assessment_work_income_command.dart` — PUT (`hasRetiredMembers` + default-empty nested lists).
5. `apps/cli/lib/src/commands/assessment_education_command.dart` — PUT (4-flag all-or-nothing single-profile shortcut OR `--from-yaml`).
6. `apps/cli/lib/src/commands/assessment_health_command.dart` — PUT (`foodInsecurity` + repeatable `--constant-care-need`).
7. `apps/cli/lib/src/commands/assessment_community_support_command.dart` — PUT (7 required: 6 bools + `familyConflicts` String).
8. `apps/cli/lib/src/commands/assessment_social_health_summary_command.dart` — PUT (3 bools + repeatable `--functional-dependency`).

## Files modified (4)

- `apps/cli/lib/src/commands/assessment_command.dart` — replaced C01 stub with parent (mirrors `PatientCommand`/`FamilyCommand`).
- `apps/cli/lib/src/commands/patient_register_command.dart` — migrated to `_yaml_helpers.dart`. Removed inlined private `_readYamlBody`/`_yamlToJsonNode`/`_yamlToJsonMap` (byte-identical logic).
- `apps/cli/lib/src/cli_runner.dart` — added `_buildAssessmentCommand` factory + 7 ficha imports (alphabetical). Replaced C01 stub.
- `apps/cli/lib/cli.dart` — barrel exports for 8 new public types.

## Test counts

| Bucket | Before C05 | After C05 |
|--------|-----------:|----------:|
| `apps/cli/` total | 277 | **378** |
| Δ | — | **+101** |

C05 distinct: 11 cross-cutting × 7 fichas + 23 ficha-specific + 5 parent = **105**. Net +101 (4 C01 stub-style tests retired with parent rewrite).

## Quality gates

- `dart analyze apps/cli/` → 0 issues.
- `dart format apps/cli/lib/ apps/cli/test/` → clean (99 files).
- `dart compile exe apps/cli/bin/acdg.dart -o /tmp/acdg-c05-w1` → succeeded.
- `acdg assessment --help` → all 7 fichas advertised.
- `acdg assessment housing --help` → all 16 declared options.
- C04 family + C03 patient + C02 auth GREEN — yaml-helper extraction did not regress `patient register`.

## Try/catch audit

| File | Boundary |
|------|----------|
| `_yaml_helpers.dart::readYamlBody` | filesystem read + `loadYaml` (`YamlException` → `InvalidArgError`) |
| `bff_client.dart::_attempt` | unchanged from C03/C04 |

Zero new try/catch in 7 ficha command modules.

## Decisions taken

1. **`_yaml_helpers.dart` extraction (Option A from W1 brief).** `_command_helpers.dart` is lean (~20 LOC); mixing YAML+filesystem there would blur concerns. Dedicated file unblocks C06+.

2. **Bool flags as `--opt=true|false` via `addOption` + manual `bool.parse`.** Uniform with C03/C04. Each verb has private `_requireBool(r, name)`.

3. **Numeric flag parsing surfaces UsageException BEFORE HTTP.** `_requireInt`/`_requireDouble` use `tryParse`; null → `usageException`. Tests assert `adapter.lastOptions` null on failure.

4. **Education all-or-nothing in `run()`.** `args` has no native cross-flag rule. After mutex-with-yaml: 0/4 → "either yaml or all four"; 1-3/4 → "must be provided together"; 4/4 → assemble single-element `memberProfiles[]`.

5. **Mutually-exclusive `--from-yaml` ↔ field flags per ficha.** Each ficha owns its own field-flag list (self-documenting).

6. **`familyConflicts` modeled as String, not bool** (W0 §3.6). Forwarded verbatim; BFF intent + lookup table validate.

7. **No `dropNulls` on assessment bodies** — every flag-based field is mandatory at DTO layer; sending `null` never legal.

8. **`functionalDependencies` / `constantCareNeeds` wrapped in `List<String>.unmodifiable`** before serialization.

9. **Single shared `fileReader` closure in `cli_runner.dart`** — all 7 fichas + `patient register`.

10. **Placeholder fallback identical to `PatientCommand`/`FamilyCommand`.**

11. **`package:args/args.dart` import added** to each ficha (`ArgResults` not re-exported by `command_runner.dart`).

## Public API delta

### New types (exported via `cli.dart`)
`AssessmentCommand` (replaces C01 stub), `AssessmentHousingCommand`, `AssessmentSocioeconomicCommand`, `AssessmentWorkIncomeCommand`, `AssessmentEducationCommand`, `AssessmentHealthCommand`, `AssessmentCommunitySupportCommand`, `AssessmentSocialHealthSummaryCommand`.

### No new BffClient verbs
`put<T>` from C04 covers all 7.

## Open questions / TODO for W2

- PII surface in error messages — 422/5xx passes raw BFF message via `ServerError`. W2 decides strip+replace vs trust BFF redaction.
- `--from-yaml` schema validation — CLI sends parsed YAML verbatim; BFF rejects on mismatch. Client-side `--dry-run` deferred to C10.
- `education` 4-flag all-or-nothing UX — may surprise vs `housing`'s simpler "all required". Suggest `--profile-from-yaml` + flat scalar split if user testing flags.
- Bool parser duplication — `~35 LOC` across 7 fichas. Extracting requires passing `usageException` as callback. Defer to 4th feature wave.
- `functionalDependencies` / `constantCareNeeds` accept arbitrary strings client-side — lookup IDs validated server-side. Embedding lookup wouldn't survive table changes.
- `--quiet` integration — successful 0 exit produces no stdout today. C10 `--output=json` may want to print request/patient id.

## Deviation from W0 surface

None. Every option name matches W0 fixtures. yaml-helper extraction follows W0 §5.3 Option A.
