# C06 — W3 (QUALITY) Final Gate

**Verdict:** PASSED
**Date:** 2026-05-04
**Agent:** flutter-quality-checker

## Quality battery

| Check | Status | Detail |
|-------|--------|--------|
| `dart analyze apps/cli/` | PASS | `No issues found!` (0/0/0) |
| `dart format --set-exit-if-changed` | PASS | `Formatted 103 files (0 changed)` |
| `dart test apps/cli/` | PASS | **405 GREEN, 0 fails, 0 skips** |
| AOT compile | PASS | `dart compile exe apps/cli/bin/acdg.dart -o /tmp/acdg-c06-w3` succeeded |
| Smoke `acdg care --help` | PASS | 2 subcommands |
| Smoke `acdg care appointment --help` | PASS | 5 options (`--professional-id`, `--date`, `--type`, `--summary`, `--action-plan`) |
| Smoke `acdg care intake --help` | PASS | 4 options (`--ingress-type-id`, `--service-reason`, `--origin-name`, `--origin-contact`) |
| Workspace `dart analyze` | PASS | 0 issues in `apps/cli/`; pre-existing 184 issues in BFF/kernel unchanged |
| Workspace `dart test` (cli + bff/web + bff/contracts) | PASS | **2077 GREEN** (Δ +27 vs C05 baseline 2050) |

## Convention checks

All passed:
- Naming PascalCase + `*Command` suffix
- snake_case files
- `final class` modifier
- Imports SDK → external → relative; alphabetical
- Barrel exports alphabetical (`care_appointment` → `care_command` → `care_intake` in `cli.dart:22-24`)
- No `print(...)` in care commands
- No direct stdout writes in `run()` (all via `_writeOut`/`_writeErr` to injected `StringSink`)
- No orphan TODO/FIXME
- No `client_secret`/`access_token`/`refresh_token` literals
- `try/catch` only at adapter boundaries (zero new in care files)
- StandardIdResponse decode walks `data.data.id` (3-guard, null-safe) at `care_appointment_command.dart:141-143`
- C03 M1 regression preserved — `patient_audit_command.dart:64` still uses `query['eventType']`

## W2 verification

W2 verdict: **APPROVED Round 1**, 0 MUST_FIX, 0 SHOULD_FIX, 4 NICE_TO_HAVE all defer-to-future.

| Item | Defer-to | Applied? |
|------|----------|---------:|
| N1 — `OutputFormatter` unused on intake success | C10 | NO (correct per W2) |
| N2 — raw path interpolation | carries from C03 | NO (acceptable trade-off) |
| N3 — machine-parseable stdout | C10 (`--output=json`) | NO (correct per W2) |
| N4 — defensive null-id fallback | preserved as belt-and-suspenders | NO (kept) |

## Issues found

None.

## Outcome

**PASSED — C06 ready to close.**

**Final test count:** 405 (apps/cli) / 2077 (workspace cli + bff/web + bff/contracts).
