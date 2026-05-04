# C06 — W0 (RED) Report

**Agent:** test-writer
**Wave:** 0 — RED
**Date:** 2026-05-04
**Status:** All 3 care command test files RED. 31 new tests (5 parent + 13 appointment + 13 intake). C05+C04+C03+C02 suites GREEN.

## 1. Test files

| Path | Tests | Notes |
|------|------:|-------|
| `apps/cli/test/commands/care_command_test.dart` | 5 | Replaces C01 stub. Parent contract for `care` (2 subcommands). |
| `apps/cli/test/commands/care_appointment_command_test.dart` | 13 | POST + StandardIdResponse decode contract. |
| `apps/cli/test/commands/care_intake_command_test.dart` | 13 | PUT void-returning contract. |

## 2. Public surface declared

### 2.1 `CareCommand` parent
2 optional ctor params (`appointment`, `intake`). Subcommand names `{'appointment', 'intake'}`. `run()` bare → non-zero exit. Placeholder fallback when no collaborators.

### 2.2 `CareAppointmentCommand` (POST → StandardIdResponse)
- Required: `<patient-id>` positional, `--professional-id` (UUID).
- Optional: `--date` (ISO8601, validated client-side), `--type`, `--summary`, `--action-plan`.
- Wire: POST `/patients/<id>/appointments`; decode `StandardIdResponse` → surface `data.id` on stdout.

### 2.3 `CareIntakeCommand` (PUT void)
- Required: `<patient-id>` positional, `--ingress-type-id`, `--service-reason`.
- Optional: `--origin-name`, `--origin-contact`.
- Wire: PUT `/patients/<id>/intake`; void response (200 envelope `{data:null,meta:...}` OR 204).

### 2.4 NEW pattern — `StandardIdResponse` decode + print

For `appointment`, tests pin two behaviors (permissively):
1. CLI traverses BFF envelope `{data:{id:"<uuid>"}, meta:{...}}` (NOT flat `body['id']`). Verified at `care_handler.dart:127-131` + `standard_response.dart:44-58`.
2. Decoded id MUST appear in stdout (any wrapping — raw print, formatter, prefix — is W1 choice; tests assert id-substring presence).

W1 will likely use `bffClient.post<String>(path, body: ..., decode: (data) => (data as Map)['id'] as String)` or typed `StandardResponse<IdData>.fromJson`.

## 3. Wire format — DTO-as-canon

### 3.1 `appointment` body
**Required (1):** `professionalId` (DTO line 9; intent `register_appointment_intent.dart:57`).
**Optional (4) all `String?`:** `date`, `type`, `summary`, `actionPlan` (intent lines 60-63 via `_asString`).

```json
{
  "professionalId": "<uuid>",
  "date": "<iso8601>",
  "type": "<str>",
  "summary": "<str>",
  "actionPlan": "<str>"
}
```

**Response shape** (verified `care_handler.dart:127-131`): `{"data": {"id": "<generated-uuid>"}, "meta": {"timestamp": "..."}}`.

**Ticket-vs-DTO divergence:** Ticket §Escopo wrote `--type=X --date=ISO8601 [--notes=Y]` as required; DTO makes only `professionalId` required, with `type`+`date` optional. There is no `notes` field; closest are `summary`/`actionPlan`. Tests follow DTO.

### 3.2 `intake` body
**Required (2):** `ingressTypeId` (DTO line 19), `serviceReason` (DTO line 22). Both rejected when missing/empty by intent.
**Optional (3):** `originName`, `originContact` (`String?`); `linkedSocialPrograms` (List, defaults `const []`).

```json
{
  "ingressTypeId": "<uuid-or-lookup-id>",
  "serviceReason": "<text>",
  "originName": "<str-or-omitted>",
  "originContact": "<str-or-omitted>",
  "linkedSocialPrograms": []
}
```

**Response shape** (verified `care_handler.dart:138-145`): `{"data": null, "meta": {...}}`. Tests pin both 200-with-envelope and 204-no-content as success.

**Ticket-vs-DTO divergence:** Ticket wrote `--reason=X --intake-at=ISO8601 [--notes=Y]`; intent reads `ingressTypeId` (lookup id) + `serviceReason` (free text). No `intakeAt` field; no `notes` field. Tests follow DTO; no ISO8601 validation on intake.

## 4. Decisions taken

1. **DTO-as-canon over ticket prose** — both verbs had mismatches; pattern repeats C03 M1 + C04 + C05.
2. **ISO8601 validated client-side for `--date` (appointment only)** — invalid → usage error (64) BEFORE HTTP. Optional at DTO but UX hint.
3. **`StandardIdResponse` decode + print contract** — id MUST appear in stdout; decode MUST traverse `data.id`.
4. **`dropNulls` semantics for optional fields** — tests permit omit OR null (C03+ convention).
5. **No `--from-yaml`** — per ticket scope; minimal discipline.
6. **PII-safety per intent comments** — both intents document that `summary`/`actionPlan`/`originName`/`originContact`/`serviceReason` MUST NEVER echo in errors.

## 5. Open questions for W1

| ID | Question | Suggested |
|----|----------|-----------|
| OQ-1 | Expose `--summary`/`--action-plan` on `appointment`? | YES — DTO-faithful, PII-safe |
| OQ-2 | Expose `--linked-program` multi on `intake`? | DEFER (intent degrades to `[]`) |
| OQ-3 | Stdout wording: bare id or `Created appointment <id>`? | Either; symmetry with C03 patient register |
| OQ-4 | Formatter receives full `StandardIdResponse` or `{id}`? | Implementation choice |
| OQ-5 | Optional fields: emit with `null` or omit? | `dropNulls` per C03/C04/C05 |

## 6. RED state confirmed

```
$ dart analyze apps/cli/test/commands/care_*_test.dart
28 errors:
  2× Target URI doesn't exist (care_<verb>_command.dart)
  26× Function 'Care<Verb>Command' isn't defined
```

C05+C04+C03+C02 suites still GREEN (verified — only care_command_test C01 stubs broken, intentional).

## 7. No impl files modified

Zero changes under `apps/cli/lib/`, `apps/cli/bin/`, or `apps/social_care_bff/`. No new pubspec deps.
