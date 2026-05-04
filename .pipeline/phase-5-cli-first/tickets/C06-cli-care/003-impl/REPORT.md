# C06 — W1 (GREEN) Report

**Agent:** flutter-bff-implementer
**Wave:** 1 — GREEN
**Date:** 2026-05-04
**Status:** All 405 CLI tests pass (was 378 at end of C05; +27 net new). 31 W0 contract tests now GREEN. `dart analyze apps/cli/` returns 0 issues. AOT compile succeeds. `acdg care --help` advertises both subcommands.

## Files created (2)

1. `apps/cli/lib/src/commands/care_appointment_command.dart` — POST `/patients/{id}/appointments`. 1 required (`--professional-id`) + 4 optional. Decodes `StandardResponse<IdData>` envelope + prints `Created appointment <id>`. Client-side ISO8601 validation on `--date`.
2. `apps/cli/lib/src/commands/care_intake_command.dart` — PUT `/patients/{id}/intake`. 2 required (`--ingress-type-id`, `--service-reason`) + 2 optional. Void-returning; success on 200 envelope OR 204. `linkedSocialPrograms` not exposed (intent degrades to `[]`).

## Files modified (3)

- `apps/cli/lib/src/commands/care_command.dart` — replaced C01 stub with parent (mirror C04/C05).
- `apps/cli/lib/src/cli_runner.dart` — added `_buildCareCommand` factory; replaced stub.
- `apps/cli/lib/cli.dart` — barrel exports for 3 new types.

## Test counts

| Bucket | Before C06 | After C06 |
|--------|-----------:|----------:|
| `apps/cli/` total | 378 | **405** |
| Δ | — | **+27** |

C06 contract: 5 parent + 13 appointment + 13 intake = **31 new GREEN**. Net +27 (4 C01 stub-style retired with parent rewrite).

## Quality gates

- `dart analyze apps/cli/` → 0 issues.
- `dart format apps/cli/lib/` → 2 files reformatted (whitespace only).
- `dart compile exe apps/cli/bin/acdg.dart -o /tmp/acdg-c06-w1` → succeeded.
- `acdg care --help` → 2 subcommands advertised.
- `acdg care appointment --help` → 5 options.
- `acdg care intake --help` → 4 options.
- C02-C05 suites GREEN.

## Try/catch audit

Zero new try/catch. Adapter boundary respected (only `bff_client.dart::_attempt`).

## Decisions taken

1. **DTO-as-canon** (per W0 §3) — both verbs follow BFF DTO field names + cardinalities, NOT ticket prose.

2. **`StandardIdResponse` decode pattern** — `bffClient.post<String?>` with `decode` callback walking `data['data']['id']`. Returns `null` defensively on shape mismatch. Success prints `Created appointment <id>` (id non-empty) OR `Appointment created` (fallback).

3. **Stdout wording: `Created appointment <id>`** — human-friendly. C10 `--output=json` will swap to `formatter.format({'id': id})`.

4. **`--summary` + `--action-plan` exposed on appointment** (OQ-1) — DTO-faithful + PII-safe.

5. **`--linked-program` NOT exposed on intake** (OQ-2) — DEFERRED. Intent degrades to `const []` when absent.

6. **ISO8601 client-side validation on `--date`** — `DateTime.tryParse`; null → `usageException` BEFORE HTTP.

7. **`dropNulls` for optional fields** — absent flags omit keys.

8. **Parent `run()` returns 64 without `printUsage()`** — mirrors C04/C05.

9. **OutputFormatter injected but unused on intake success** — symmetry; C10 resolver wiring without ctor break.

10. **PII-safety in error paths** — `stderrMessageFor(error)` surfaces `Server error (<status>): <BFF message>`. CLI never re-prints user input on failure.

## Public API delta

### New types (exported via `cli.dart`)
`CareCommand` (replaces C01 stub), `CareAppointmentCommand`, `CareIntakeCommand`.

### No new BffClient verbs
`post<T>` (C03) + `put<T>` (C04) cover both. The new pattern is the **decode callback traversing `StandardResponse<IdData>.data.id`** — first exercised here.

## Open questions / TODO for W2

- `--linked-program` repeatable flag — deferred per OQ-2. Add colon-separated or `--from-yaml` mode if user testing flags.
- Formatter integration on appointment — print human string today; C10 `--output=json` will `formatter.format({'id': id})`.
- intake success line — no stdout today (matches assessment PUT). C10 may want `Updated intake <patient-id>`.
- 422 PII surface — passes BFF message through. BFF intents documented PII-safe; second-pass strip would be defense-in-depth.
- Refresh-on-401 — same gap as C03/C04/C05. Cross-cutting debt.

## Deviation from W0 surface

None. Every option name matches W0 fixtures. Body fields DTO-faithful camelCase.
