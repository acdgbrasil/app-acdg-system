# C07 — W0 (RED) Report

**Agent:** test-writer
**Wave:** 0 — RED
**Date:** 2026-05-04
**Status:** All 4 protection command test files RED. 49 new tests (5 parent + 15 violation + 15 referral + 14 placement-history). C02-C06 GREEN.

## 1. Test files

| Path | Tests |
|------|------:|
| `apps/cli/test/commands/protection_command_test.dart` (replaced) | 5 |
| `apps/cli/test/commands/protection_violation_command_test.dart` | 15 |
| `apps/cli/test/commands/protection_referral_command_test.dart` | 15 |
| `apps/cli/test/commands/protection_placement_history_command_test.dart` | 14 |

## 2. Public surface declared

### 2.1 `ProtectionCommand` parent
3 optional ctor params (`violation`, `referral`, `placementHistory`). Subcommand names `{'violation', 'referral', 'placement-history'}`.

### 2.2 `ProtectionViolationCommand` (POST → StandardIdResponse)
- Required: `<patient-id>` positional, `--victim-id` (UUID), `--violation-type`, `--description-of-fact`.
- Optional: `--violation-type-id`, `--report-date` (ISO8601), `--incident-date` (ISO8601), `--actions-taken`.
- Wire: POST `/patients/<id>/violations`; decode `StandardIdResponse` → surface `data.id`.

### 2.3 `ProtectionReferralCommand` (POST → StandardIdResponse)
- Required: `<patient-id>` positional, `--referred-person-id` (UUID), `--destination-service`, `--reason`.
- Optional: `--professional-id` (UUID), `--date` (ISO8601).
- Wire: POST `/patients/<id>/referrals`; decode `StandardIdResponse`.

### 2.4 `ProtectionPlacementHistoryCommand` (PUT void, YAML-only)
- Required: `<patient-id>` positional, `--from-yaml=<path>` (only way to drive).
- Constructor: `fileReader: Future<String> Function(String path)`.
- Wire: PUT `/patients/<id>/placement-history`; void (200 envelope OR 204).

## 3. Wire format — DTO-as-canon (5th application)

### 3.1 `violation` body (POST `/patients/<id>/violations`)
**Required (3):** `victimId`, `violationType`, `descriptionOfFact`. **Optional (4):** `violationTypeId`, `reportDate`, `incidentDate`, `actionsTaken`. Source: `report_rights_violation_intent.dart:65-90` + DTO `report_rights_violation_request.dart:7-29`.

**Ticket-vs-DTO divergence:** Ticket pedia `--type --reported-at --description`; DTO requer `victimId`+`violationType`+`descriptionOfFact`. CLI segue DTO.

### 3.2 `referral` body (POST `/patients/<id>/referrals`)
**Required (3):** `referredPersonId`, `destinationService`, `reason`. **Optional (2):** `professionalId`, `date`. Source: `create_referral_intent.dart:53-79` + DTO `create_referral_request.dart:7-25`.

**Ticket-vs-DTO divergence:** Ticket pedia `--institution --reason --referred-at`; DTO requer `referredPersonId`+`destinationService`+`reason`. Não tem `referredAt`; closest `date` (optional). CLI segue DTO.

### 3.3 `placement-history` body (PUT `/patients/<id>/placement-history`)
**Top-level all optional with defaults:**
- `registries: List<RegistryDraftDto>` (default `[]`)
- `collectiveSituations: CollectiveDraftDto?`
- `separationChecklist: SeparationDraftDto?`

**`RegistryDraftDto` required:** `memberId`, `startDate`, `reason`. **Optional:** `endDate`.
**`CollectiveDraftDto` (both optional):** `homeLossReport`, `thirdPartyGuardReport`.
**`SeparationDraftDto` (both default `false`):** `adultInPrison`, `adolescentInInternment`.

Source: `update_placement_history_intent.dart:58-66` + DTO `update_placement_history_request.dart:7-87` (3 nested DTOs).

## 4. Flag naming decision

**Use `--from-yaml=<path>` (NOT ticket's `--history-yaml`)** — uniform with C03 patient register + C05 assessments. Reuses `_yaml_helpers.readYamlBody` C05-extracted. Ticket prose was prescriptive on concept, not spelling.

## 5. Decisions taken

1. **DTO-as-canon** — 5th application of C03 M1 lesson.
2. **ISO8601 client-side validation** for `--report-date`, `--incident-date`, `--date`. Invalid → exit 64 (no HTTP).
3. **`StandardIdResponse` decode + print** — reuses C06 pattern.
4. **`dropNulls` semantics** for optional fields.
5. **`placement-history` YAML-only** — nested-DTO shape explodes flag surface; BFF intent uses P2b try/fromJson.
6. **`fileReader` injection** mirrors C03 + C05.
7. **PII-safety** — CLI propagates BFF's sanitized error; never echoes user input on failure.

## 6. Open questions for W1

| ID | Question | Suggested |
|----|----------|-----------|
| OQ-1 | Expose all 4 optional flags on violation? | YES — DTO-faithful, PII-safe |
| OQ-2 | Expose `--professional-id` + `--date` on referral? | YES |
| OQ-3 | Stdout wording? | Either; symmetry C03/C06 |
| OQ-4 | Formatter full `StandardIdResponse` or `{id}`? | Implementation choice |
| OQ-5 | placement-history stdout on 204? | Permissive |
| OQ-6 | YAML helper SeparationDraftDto `false` defaults? | Defer to BFF (DTO ctor defaults) |

## 7. RED state

47 errors: 3× Target URI doesn't exist + 44× Function 'Protection<Verb>Command' isn't defined.

Parent test compiles but fails at runtime (subcommands empty + run() returns 0 against C01 stub) — intentional.

C02-C06: 67/67 GREEN sampled (care, assessment, family, patient register).

## 8. No impl files modified

Zero changes under `apps/cli/lib/`, `apps/cli/bin/`, or `apps/social_care_bff/`. No new pubspec deps.
