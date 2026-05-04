# C07 — W1 (GREEN) Report

**Agent:** flutter-bff-implementer
**Wave:** 1 — GREEN
**Date:** 2026-05-04
**Status:** All 450 CLI tests pass (was 405; +45 net new). 49 W0 contract tests now GREEN. `dart analyze apps/cli/` 0 issues. AOT compiles. `acdg protection --help` advertises 3 subcommands.

## Files created (3)

- `apps/cli/lib/src/commands/protection_violation_command.dart` — POST + StandardIdResponse decode + `Reported violation <id>` print.
- `apps/cli/lib/src/commands/protection_referral_command.dart` — POST + StandardIdResponse decode + `Created referral <id>` print.
- `apps/cli/lib/src/commands/protection_placement_history_command.dart` — PUT void, YAML-only.

## Files modified (5)

- `apps/cli/lib/src/commands/protection_command.dart` — replaced C01 stub with parent.
- `apps/cli/lib/src/commands/_command_helpers.dart` — **extracted `decodeStandardIdResponse(Object? data) -> String?`** (3-guard defensive walk).
- `apps/cli/lib/src/commands/care_appointment_command.dart` — migrated to use shared `decodeStandardIdResponse` (removed local `_decodeAppointmentId`).
- `apps/cli/lib/src/cli_runner.dart` — `_buildProtectionCommand` factory.
- `apps/cli/lib/cli.dart` — barrel exports.

## Test counts

| Bucket | Before C07 | After C07 |
|---|---:|---:|
| `apps/cli/` total | 405 | **450** |
| Δ | — | **+45** |

49 new GREEN; 4 C01 stub retired = +45 net.

## Quality gates

- `dart analyze apps/cli/` → 0 issues.
- `dart format` → clean.
- `dart compile exe` → succeeded.
- `acdg protection --help` → 3 subcommands.
- C02-C06 GREEN.

## Decisions taken

1. **DTO-as-canon (5th application)**.
2. **`decodeStandardIdResponse` extracted to `_command_helpers.dart`** — once the same 3-guard walk landed in 3 commands, DRY beat inline. C06 migrated in the same wave.
3. **Stdout wording symmetric with C06** — `Reported violation <id>` / `Created referral <id>`.
4. All optional flags exposed on violation + referral (PII-safe per intent).
5. `placement-history` YAML-only (no field-flag fallback).
6. `--from-yaml` flag (uniform with C03/C05).
7. ISO8601 client-side validation on date flags.
8. `dropNulls` for optional fields.
9. Parent `run()` returns 64 without `printUsage()`.
10. `OutputFormatter` injected but unused on placement-history success — symmetry with C04/C05/C06.
11. PII-safety: error paths surface only BFF message + status; never user input.

## Open questions / TODO for W2

- Formatter integration on POST verbs (C10 `--output=json`).
- placement-history stdout on 204 — permissive today.
- 422 PII surface — defense-in-depth strip would be belt-and-suspenders.
- Refresh-on-401 — cross-cutting debt.

## Deviation from W0 surface

None.
