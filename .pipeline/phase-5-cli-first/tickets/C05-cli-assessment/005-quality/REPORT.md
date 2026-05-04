# C05 — W3 (QUALITY) Final Gate

**Verdict:** PASSED
**Date:** 2026-05-04
**Agent:** flutter-quality-checker

## Quality battery

| Check | Status | Detail |
|-------|--------|--------|
| `dart analyze apps/cli/` | PASS | `No issues found!` |
| `dart format --set-exit-if-changed` | PASS | 99 files, 0 changed |
| `dart test apps/cli/` | PASS | **378 GREEN, 0 fails, 0 skips** |
| AOT compile | PASS | `dart compile exe apps/cli/bin/acdg.dart -o /tmp/acdg-c05-w3` succeeded |
| Smoke `acdg assessment --help` | PASS | 7 fichas advertised |
| Smoke `acdg assessment housing --help` | PASS | 15 required flags + `--from-yaml` |
| Workspace `dart analyze` | PASS | Zero new issues; pre-existing 170 info under BFF/kernel unchanged |
| Workspace `dart test` (cli + bff/web + bff/contracts) | PASS | **2050 GREEN** (Δ +101 vs C04 baseline 1949) |

## Convention checks

All passed:
- Naming PascalCase + `*Command` suffix
- snake_case files (8 ficha files + `_yaml_helpers.dart`)
- Imports SDK → external → relative; alphabetical
- No `print(...)` in assessment commands or `_yaml_helpers.dart`
- No direct `Stdio.stdout` writes inside `Command.run()` (all via injected `StringSink`)
- No orphan TODO/FIXME
- No `client_secret` (6 hits all in negative-assertion docs/tests)
- No raw token logging
- `try/catch` only at adapter boundaries (`_yaml_helpers.dart::readYamlBody` + unchanged `bff_client.dart::_attempt`)

## Wire format spot-check

All 7 fichas verified against `Update<X>Request.fromJson` in BFF intents — every camelCase key matches `toJson()` shape exactly. No M1-style casing surprises.

## W2 verification

W2 verdict: **APPROVED Round 1**, 0 MUST_FIX, 3 SHOULD_FIX defer-to-future, 4 NICE_TO_HAVE.

| Item | Defer-to | Applied? |
|------|----------|---------:|
| S1 — formatter field unused on 7 fichas | C10 | NO (correct per W2) |
| S2 — bool/numeric helper duplication ~70 LOC | post-C09/C10 grooming | NO (correct per W2) |
| S3 — `--bff` global flag hardcoded | C10 (debt pre-C03) | NO (correct per W2) |
| N1 — `_parseBool` → `_requireBool` rename | next pass | NO |
| N2 — defensive yaml walk branches | keep as-is per W2 | NO |
| N3 — per-ficha schema validation | C10 | NO |
| N4 — flag-presence dedup | with S2 | NO |

## Regression checks

| Watchout | Status |
|----------|--------|
| C03 M1 fix at `patient_audit_command.dart:64` (`query['eventType']`) | PRESERVED |
| C04 `_command_helpers.dart` rename + 8 patient + 4 family imports | UNBROKEN (20 import hits) |
| `_yaml_helpers.dart` extraction byte-equivalent for `patient register` | PASS — 10/10 tests GREEN |
| C04 family + C03 patient + C02 auth suites | GREEN |

## Issues found

None.

## Outcome

**PASSED — C05 ready to close.**

**Final test count:** 378 (apps/cli) / 2050 (workspace cli + bff/web + bff/contracts).
