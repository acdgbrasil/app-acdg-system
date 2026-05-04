# C05 — W0 (RED) Report

**Agent:** test-writer
**Wave:** 0 — RED
**Date:** 2026-05-04
**Status:** All 7 ficha test files + replaced parent + new parametrized helper are RED. `dart analyze apps/cli/test/` reports **37 errors, 0 warnings, 0 info**. C04+C03+C02 suites still GREEN (136/136).

## 1. Test files

### Replaced (C01 stub → C05 parent)
- `apps/cli/test/commands/assessment_command_test.dart` — 5 tests covering parent contract.

### New ficha tests (flat layout)
| Path | Tests | Coverage |
|------|------:|----------|
| `assessment_housing_command_test.dart` | 12 | Cross-cutting (9) + body shape + missing `--type` + non-int `--number-of-rooms` |
| `assessment_socioeconomic_command_test.dart` | 13 | Cross-cutting + body shape + nested `socialBenefits` via yaml + non-numeric `--total-family-income` |
| `assessment_work_income_command_test.dart` | 12 | Cross-cutting + body shape + nested lists via yaml + missing `--has-retired-members` |
| `assessment_education_command_test.dart` | 13 | Cross-cutting + flag-based body + nested lists via yaml + no-flags-no-yaml + partial-flag-set |
| `assessment_health_command_test.dart` | 13 | Cross-cutting + body shape + `--constant-care-need` multi + nested lists via yaml |
| `assessment_community_support_command_test.dart` | 11 | Cross-cutting + body shape (7 keys) + missing `--family-conflicts` |
| `assessment_social_health_summary_command_test.dart` | 12 | Cross-cutting + body shape + empty-list default |

**Subtotal: 86 ficha tests + 5 parent = 91 new tests.**

### New helper
- `apps/cli/test/commands/_assessment_test_helpers.dart` — fakes (`CapturingAdapter`, `ThrowingAdapter`, `NullCredStore`, `NoSuchFileException`), helpers, and `runAssessmentCommandContract(...)` parametrized factory driving 9 cross-cutting tests every ficha shares.

## 2. Public surface declared

### 2.1 `AssessmentCommand` parent
7 optional ctor params + 7 subcommand names: `housing`, `socioeconomic`, `work-income`, `education`, `health`, `community-support`, `social-health-summary`. `run()` without subcommand returns 64. Placeholder fallback when no collaborators (mirrors C03/C04).

### 2.2 The 7 ficha command classes — common signature
```dart
final class Assessment<X>Command extends Command<int> {
  Assessment<X>Command({
    required BffClient bffClient,
    required OutputFormatter formatter,
    required Future<String> Function(String path) fileReader,
    StringSink? stdout,
    StringSink? stderr,
  });
}
```

**No new BffClient methods needed** — `put<T>` from C04 covers all 7. Path always `PUT /patients/<id>/assessment/<verb-kebab>`.

## 3. Wire format §3 — DTO-as-canon

All 7 intents delegate body parsing directly to `Update<X>Request.fromJson(body)` (one try/catch per intent, e.g. `update_housing_condition_intent.dart:51`, `update_health_status_intent.dart:47`). **Wire body shape = `Update<X>Request.toJson()`** — `json_serializable`-generated. No envelope, no top-level extras (unlike `family add`).

### 3.1 `housing` — 15 fields all required
DTO `update_housing_condition_request.dart:7-43`. Required: `type`, `wallMaterial`, `numberOfRooms`, `numberOfBedrooms`, `numberOfBathrooms`, `waterSupply`, `hasPipedWater`, `electricityAccess`, `sewageDisposal`, `wasteCollection`, `accessibilityLevel`, `isInGeographicRiskArea`, `hasDifficultAccess`, `isInSocialConflictArea`, `hasDiagnosticObservations`.

### 3.2 `socioeconomic` — 5 required + 1 default-empty list
DTO `update_socio_economic_situation_request.dart:7-40`. Required: `totalFamilyIncome` (double), `incomePerCapita` (double), `receivesSocialBenefit` (bool), `mainSourceOfIncome` (String), `hasUnemployed` (bool). Optional `socialBenefits[]`. Nested `SocialBenefitDraftDto` (lines 42-74).

### 3.3 `work-income` — 1 required + 2 default-empty lists
DTO `update_work_and_income_request.dart:9-31`. Required: `hasRetiredMembers` (bool). Optional `individualIncomes[]`, `socialBenefits[]`.

### 3.4 `education` — 0 required + 2 default-empty lists
DTO `update_educational_status_request.dart:7-23`. Optional `memberProfiles[]`, `programOccurrences[]`.

### 3.5 `health` — 1 required + 3 default-empty lists
DTO `update_health_status_request.dart:7-32`. Required: `foodInsecurity` (bool). Optional `deficiencies[]`, `gestatingMembers[]`, `constantCareNeeds[]`. Nested DTOs include `responsibleCaregiverName?` (free-text PII per intent doc — error messages NEVER echo).

### 3.6 `community-support` — 7 required scalars
DTO `update_community_support_network_request.dart:7-43`. Required: `hasRelativeSupport`, `hasNeighborSupport`, `familyConflicts` (**String**, NOT bool — easy mis-shape from prose alone), `patientParticipatesInGroups`, `familyParticipatesInGroups`, `patientHasAccessToLeisure`, `facesDiscrimination`.

### 3.7 `social-health-summary` — 3 required bools + 1 default-empty list
DTO `update_social_health_summary_request.dart:7-34`. Required: `requiresConstantCare`, `hasMobilityImpairment`, `hasRelevantDrugTherapy`. Optional `functionalDependencies[]`.

## 4. Decisions taken

1. **Real BffClient + fake HttpClientAdapter** — same as C03/C04.
2. **Test factory** drives 9 cross-cutting tests every ficha shares; per-ficha files own body-shape assertions.
3. **`--from-yaml` on every ficha** + mutually exclusive with field flags.
4. **DTO-as-canon for nested-heavy fichas** (socioeconomic, work-income, education, health) — tests document flag shortcut + yaml full path. Simple fichas (housing, community-support, social-health-summary) fully flag-driven.
5. **Numeric flag parsing surfaced explicitly** — non-int `--number-of-rooms` / non-double `--total-family-income` → usage error, no BFF call.
6. **Bool flags as `--opt=true|false`** — uniform with family commands. Manual parse via `addOption` (not `addFlag` which forces `--opt`/`--no-opt`).
7. **Education "no flags, no yaml" rejected** — would otherwise PUT `{memberProfiles: [], programOccurrences: []}` (syntactically legal but almost certainly mistake).
8. **Helper does NOT depend on `OutputFormatter`** — factory takes a closure that builds the Command itself.

## 5. Open questions for W1

1. `addFlag` vs `addOption` for bools — recommend `addOption('opt') + manual bool.parse` (uniform with C03/C04).
2. Numeric parsing failure semantics — must trigger `usageException` from `run()` (args lib only knows String).
3. **YAML→JSON conversion reuse** — `patient_register_command.dart:243-263` has `_yamlToJsonNode/_yamlToJsonMap`. W1 should extract to `_command_helpers.dart` (or new `_yaml_helpers.dart`) for the 7 fichas + future C06+.
4. Education all-or-nothing flag rule — explicit guard.
5. Output on 204 — cross-cutting test asserts `exit == 0` only. UX stdout line deferred to C10.
6. PII surface (health ficha) — error messages never echo `responsibleCaregiverName`. Confirm at W2.

## 6. RED state confirmed

```
$ dart analyze apps/cli/test/
37 errors (0 warnings, 0 info):
  7× Target URI doesn't exist (assessment_<verb>_command.dart)
  30× Function 'Assessment<Verb>Command' isn't defined
```

Parent test compiles against C01 stub but RED at runtime: `subcommands.keys` empty + `run()` returns 0.

C04 + C03 + C02 GREEN: `dart test apps/cli/test/commands/family_*_test.dart apps/cli/test/commands/patient_*_test.dart apps/cli/test/commands/auth_*_test.dart` → `+136: All tests passed!`

## 7. No impl files modified

Zero changes under `apps/cli/lib/`, `apps/cli/bin/`, or `apps/social_care_bff/`. No new pubspec deps. 9 affected test files only.
