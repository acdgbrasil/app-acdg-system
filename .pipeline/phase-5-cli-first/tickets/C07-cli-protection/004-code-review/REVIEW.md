# C07 — W2 Code Review

**Agent:** flutter-code-reviewer
**Wave:** 2 — REVIEW
**Date:** 2026-05-04
**Round:** 1 / 3
**Verdict:** **APPROVED**

---

## 1. Summary

W1 implemented the three Contract A Protection verbs (`violation`, `referral`,
`placement-history`), replaced the C01 stub `protection_command.dart` with a
proper parent, and **extracted `decodeStandardIdResponse` to
`_command_helpers.dart`** while migrating C06 `care_appointment_command.dart`
to consume the shared helper. All quality gates verified independently:

| Gate | Result |
|------|--------|
| `dart analyze` (apps/cli) | 0 issues |
| Full suite (`apps/cli/`) | **450 / 450 GREEN** (matches W1 claim) |
| C06 migration safety | `care_appointment_command_test.dart` 13 / 13 GREEN |
| C03 M1 regression check | `patient_audit_command.dart:64` still uses `query['eventType']` — safe |
| `_command_helpers.dart` size | 84 lines (lean, single library doc) |
| W0 test files unmodified | confirmed — no diff under `apps/cli/test/commands/protection_*_test.dart` |

The 12 W1 decisions are all consistent with the C03–C06 lessons and the W0
contract; none introduces a deviation needing rework.

---

## 2. Architecture verification

### 2.1 `Result<T>` end-to-end
- `protection_violation_command.dart:161-179` switches on `Result<String?>` from
  `bffClient.post<String?>` — no `throw`, no manual exception narrowing.
- `protection_referral_command.dart:135-153` mirrors verbatim.
- `protection_placement_history_command.dart:107-130` chains two `Result`s
  (YAML parse + HTTP) via switch matches — both go through `stderrMessageFor` /
  `exitCodeFor`. `Success()` arm is empty (void verb); `Failure(:final error)`
  is exhaustive.
- All POST/PUT failure paths funnel through the shared helpers
  (`_command_helpers.dart:28-57`). No alternative exit-code path was invented.

### 2.2 `try/catch` only at adapter boundaries
- Zero `try/catch` in any of the 4 W1-touched command files
  (`protection_command.dart`, 3 protection verbs).
- The single `try/catch` for filesystem + YAML parse lives in
  `_yaml_helpers.dart:77-91` (adapter boundary, pre-existing C05). Both
  protection_placement_history and the C03/C05 ladder consume the same
  `Result<Map>`-returning helper — single source of truth maintained.
- `cli_runner.dart:178-188` retains the `try/on UsageException`
  conversion at the runner boundary (pre-existing C03 pattern, unchanged).

### 2.3 Constructor injection + `final class` + final fields
- All 3 new commands declare `final class … extends Command<int>`.
- `BffClient`, `OutputFormatter`, `StringSink? stdout/stderr`,
  `Future<String> Function(String) fileReader` injected via named ctor params.
  No globals, no service locator.
- All instance fields are `final` (`protection_violation_command.dart:87-90`,
  `protection_referral_command.dart:75-78`,
  `protection_placement_history_command.dart:73-77`).

### 2.4 Imports order alphabetical
Verified for all 4 files:
- `package:args/command_runner.dart` → `package:core_contracts/core_contracts.dart`
  (alphabetical SDK → external).
- Relative imports: `../formatters/...`, `../session/...`, `_command_helpers.dart`,
  `_yaml_helpers.dart` (alphabetical, with leading-underscore helpers grouped).

### 2.5 `StringSink` injection + zero `print(...)`
- Verified by `grep` across all 5 W1-touched files: zero `print(`, zero
  `stdout.writeln(` against `dart:io`'s global. Every output goes through
  injected `StringSink? stdout` / `StringSink? stderr` with the same
  `_writeOut` / `_writeErr` helpers seen in C03–C06.

---

## 3. `decodeStandardIdResponse` extraction (W1 decision #2)

### 3.1 Helper extracted properly
`_command_helpers.dart:78-84` defines a 7-line, 3-guard pure function:
```dart
String? decodeStandardIdResponse(Object? data) {
  if (data is! Map<String, Object?>) return null;
  final inner = data['data'];
  if (inner is! Map<String, Object?>) return null;
  final id = inner['id'];
  return id is String ? id : null;
}
```
Returns `null` defensively on shape mismatch (no `throw`); callers degrade to
a generic success line. Library-doc explicitly tracks the C06 → C07 lineage
(`_command_helpers.dart:69-77`).

### 3.2 C06 migrated to consume the shared helper
- `care_appointment_command.dart:36` imports `_command_helpers.dart`.
- `care_appointment_command.dart:118` calls `decodeStandardIdResponse` directly
  as the `decode:` argument to `bffClient.post`.
- The previous inline `static String? _decodeAppointmentId(...)` is **gone** —
  `grep -r '_decodeAppointmentId'` across `apps/cli/` returns zero hits.

### 3.3 New protection POST verbs consume the same helper
- `protection_violation_command.dart:164` → `decode: decodeStandardIdResponse`.
- `protection_referral_command.dart:138` → `decode: decodeStandardIdResponse`.

### 3.4 C06 tests still GREEN
Independent run of `dart test test/commands/care_appointment_command_test.dart`:
**13 / 13 passed in 0.0s.** Migration is safe.

### 3.5 `_command_helpers.dart` size
84 lines, 3 small public symbols + 1 `library` doc-block. Still well below any
"need to split" threshold. Decision accepted.

---

## 4. Wire format adherence (DTO-as-canon — 6th application)

Cross-checked the BFF intents against the CLI body assembly:

### 4.1 `violation` — `protection_violation_command.dart:151-159`
| Wire key | CLI flag | BFF intent expectation |
|----------|----------|------------------------|
| `victimId` | `--victim-id` | required (intent line 78) |
| `violationType` | `--violation-type` | required (intent line 79) |
| `descriptionOfFact` | `--description-of-fact` | required (intent line 80) |
| `violationTypeId` | `--violation-type-id` | optional `_asString(body['violationTypeId'])` (intent line 87) |
| `reportDate` | `--report-date` | optional (intent line 88) |
| `incidentDate` | `--incident-date` | optional (intent line 89) |
| `actionsTaken` | `--actions-taken` | optional (intent line 90) |

All 7 keys present in the body assembled at lines 151-159. `dropNulls` applied
on line 151. **PASS.**

### 4.2 `referral` — `protection_referral_command.dart:127-133`
| Wire key | CLI flag | BFF intent expectation |
|----------|----------|------------------------|
| `referredPersonId` | `--referred-person-id` | required (intent line 68) |
| `destinationService` | `--destination-service` | required (intent line 69) |
| `reason` | `--reason` | required (intent line 70) |
| `professionalId` | `--professional-id` | optional (intent line 77) |
| `date` | `--date` | optional (intent line 78) |

All 5 keys present. **PASS.**

### 4.3 `placement-history` — YAML payload passed through verbatim
The YAML→JSON pipeline lives in `_yaml_helpers.dart` (already-tested in C05);
`protection_placement_history_command.dart:107-122` reads via
`readYamlBody`, takes the `Map<String, Object?>` from `Success` and PUTs it
unchanged to `/patients/<id>/placement-history`. The BFF intent uses
`UpdatePlacementHistoryRequest.fromJson` (P2b try/fromJson), so any wire
divergence would surface as a 422 — but the W0 fixture YAML
(`protection_placement_history_command_test.dart:111-124`) exercises every
nested field and the pinned PUT-body assertion (test lines 200-231) verifies
the JSON shape end-to-end. **PASS.**

---

## 5. YAML-only `placement-history` (W1 decisions #5, #6, #7)

- **No field-flag fallback.** `protection_placement_history_command.dart:65-71`
  declares only `--from-yaml`. No `addOption` for any data field.
- **`--from-yaml` required.** Lines 98-105 reject the absent / empty case via
  `usageException` with an explicit message that calls out the no-fallback
  policy.
- **`fileReader` injected.** Line 75: `final Future<String> Function(String) fileReader;`
  — bound in `cli_runner.dart:491` to `(path) => File(path).readAsString()`
  for production wiring. No internal `dart:io` import.
- **`_yaml_helpers.readYamlBody` reused.** Line 107 calls the shared C05
  helper. No duplicate YAML loader.
- **Errors translated to `InvalidArgError` at boundary.** Verified via
  `_yaml_helpers.dart:79-95` — three failure modes
  (`fileReader` throws → `InvalidArgError`; `YamlException` → `InvalidArgError`;
  non-map root → `InvalidArgError`). Adapter pattern preserved.

---

## 6. W1's 12 decisions — verdict

| # | Decision | Verdict | Note |
|---|----------|---------|------|
| 1 | DTO-as-canon over ticket prose | **APPROVED** | 6th application of C03 M1 lesson; consistent across W0+W1 |
| 2 | `decodeStandardIdResponse` extraction + C06 migration | **APPROVED** | Helper lives at the right level; C06 GREEN after migration |
| 3 | Stdout wording symmetric with C06 (`Reported violation <id>` / `Created referral <id>`) | **APPROVED** | Uniform with `Created appointment <id>` |
| 4 | All 4 optional flags on violation | **APPROVED** | DTO-faithful; PII-safety preserved (BFF intent never echoes) |
| 5 | Both optional flags on referral (`--professional-id`, `--date`) | **APPROVED** | DTO-faithful |
| 6 | YAML-only `placement-history` | **APPROVED** | Tree DTO doesn't flatten; matches ticket prose "exigir --from-yaml por padrão" |
| 7 | `--from-yaml` flag spelling (NOT `--history-yaml`) | **APPROVED** | Symmetry with C03 register + C05 fichas; ticket prose was prescriptive on concept |
| 8 | ISO8601 client-side validation | **APPROVED** | Validates `--report-date`, `--incident-date`, `--date` BEFORE HTTP; clear local error vs opaque BFF 400/422 |
| 9 | `dropNulls` for optional fields | **APPROVED** | Consistent with C03–C06 |
| 10 | Parent `run() = 64` without `printUsage()` | **APPROVED** | Comment at `protection_command.dart:51-55` explains test-runner edge-case; CommandRunner renders banner before `run` |
| 11 | `OutputFormatter` injected but unused on `placement-history` success | **APPROVED** | Symmetric with C04/C05 void-success verbs; future-proofs for C10 `--output=json` |
| 12 | PII-safety in error paths | **APPROVED** | No echo of `--description-of-fact`, `--reason`, victim-id, registry narrative; ISO8601 echo of timestamp value (non-PII) is acceptable |

---

## 7. Code quality

- **Naming.** `*Command` for classes, `_writeOut` / `_writeErr` private I/O
  helpers, `_PlaceholderCommand` private fallback. Consistent with C03–C06.
- **Doc-strings.** Each new file has a substantive library-level doc-comment
  (40+ lines) that pins the wire shape, the PII-safety contract, and the
  rationale for any divergence from ticket prose. `_command_helpers.dart`
  doc explicitly tracks lineage of `decodeStandardIdResponse`
  (lines 69-77).
- **No orphan `TODO` / `FIXME`.** `grep -n 'TODO\|FIXME'` across the 4 new
  files yields zero hits.
- **No `_buildXxx()` helper methods inside a Command** — extraction policy
  preserved.

---

## 8. Tests

- **W0 test files unmodified.** Verified — no diff under
  `apps/cli/test/commands/protection_*_test.dart` between W0 RED state and
  the GREEN run.
- **Total ≥ 450.** `dart test --reporter compact` final line:
  `00:02 +450: All tests passed!`. **Matches W1 claim.**
- **C02–C06 GREEN.** Sampled `care_appointment_command_test.dart`:
  13 / 13. Full suite `+450` covers all earlier waves implicitly.

---

## 9. Specific watchouts — all clear

| Check | Status |
|-------|--------|
| C03 M1 regression — `patient_audit_command.dart:64` uses `query['eventType']` | **PASS** (verified line 64 reads `query['eventType'] = eventType` in camelCase) |
| C06 `care_appointment_command.dart` tests survived migration | **PASS** (13/13) |
| `_command_helpers.dart` growth | **PASS** (84 lines, lean) |
| `_yaml_helpers.dart` reuse on placement-history | **PASS** (same `readYamlBody` consumed by C03 register + C05 fichas) |

---

## 10. Minor advisory items (NOT blocking)

1. **`OutputFormatter formatter` field on `ProtectionPlacementHistoryCommand`
   is unused.** Same dead-pin pattern as C05 fichas — kept for symmetry +
   C10 readiness. Accepted for round 1 (W1 decision #11).
2. **ISO8601 echo in usage error** (`'got "$reportDate"'`) re-prints the
   user's literal value back. Timestamps are not PII so this is acceptable;
   matches the C06 `--date` precedent.
3. **No client-side UUID validation on `--victim-id` / `--referred-person-id`
   / `--professional-id`.** BFF intent does the UUID check; surfacing 422
   end-to-end is the existing C03–C06 norm. No regression introduced.
4. **`Future<int> run()` of `_PlaceholderCommand` returns 64 directly.**
   Confirmed harmless — production runner never instantiates a
   `_PlaceholderCommand` because `_buildProtectionCommand` always wires the
   real subcommands (`cli_runner.dart:475-495`).

None of the above blocks approval; all are debt items already documented in
the W1 REPORT (formatter integration in C10, UUID validation, refresh-on-401)
or accepted by symmetry.

---

## 11. Verdict

**APPROVED.** No `MUST_FIX`, no `SHOULD_FIX`. W3 (quality-checker) may proceed.

Round 1 of 3 used.

---

## 12. Files reviewed

- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/cli/lib/src/commands/protection_command.dart`
- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/cli/lib/src/commands/protection_violation_command.dart`
- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/cli/lib/src/commands/protection_referral_command.dart`
- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/cli/lib/src/commands/protection_placement_history_command.dart`
- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/cli/lib/src/commands/_command_helpers.dart`
- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/cli/lib/src/commands/_yaml_helpers.dart`
- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/cli/lib/src/commands/care_appointment_command.dart`
- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/cli/lib/src/commands/patient_audit_command.dart` (regression check only)
- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/cli/lib/src/cli_runner.dart`
- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/cli/lib/cli.dart`
- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/cli/test/commands/protection_command_test.dart`
- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/cli/test/commands/protection_violation_command_test.dart`
- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/cli/test/commands/protection_referral_command_test.dart`
- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/cli/test/commands/protection_placement_history_command_test.dart`
- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/social_care_bff/web/lib/src/intents/report_rights_violation_intent.dart`
- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/social_care_bff/web/lib/src/intents/create_referral_intent.dart`
- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/social_care_bff/web/lib/src/intents/update_placement_history_intent.dart`
