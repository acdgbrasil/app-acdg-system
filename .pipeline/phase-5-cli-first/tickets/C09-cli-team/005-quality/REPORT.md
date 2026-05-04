# C09 — W3 (QUALITY) Final Gate

**Verdict:** PASSED
**Date:** 2026-05-04
**Onda 4 fecha quando este ticket fechar.**
**Final test count:** 658 (apps/cli) — workspace 2330.

## Quality battery
| Check | Status |
|-------|--------|
| `dart analyze apps/cli/` | PASS — `No issues found!` |
| `dart format` | PASS — 149 files, 0 changed |
| `dart test apps/cli/` | PASS — **658 GREEN** |
| AOT compile | PASS |
| Smoke `acdg team --help` | PASS — 7 entries |
| Smoke `acdg team role --help` | PASS — 3 sub-leaves |
| Smoke `acdg team register --help` | PASS — 3 req + 2 opt flags |
| Workspace `dart analyze` | PASS — 0 new issues |
| Workspace `dart test` (cli + bff/web + bff/contracts) | PASS — **2330 GREEN** (Δ +93 vs C08) |

## Convention checks
All passed. C03 M1 (`query['eventType']`) preserved.

## `decodeStandardIdResponse` — 7 call-sites confirmed

1. `care_appointment_command.dart:118` (C06)
2. `lookup_create_command.dart:85` (C08)
3. `lookup_request_create_command.dart:102` (C08)
4. `protection_referral_command.dart:138` (C07)
5. `protection_violation_command.dart:164` (C07)
6. `team_register_command.dart:116` (C09)
7. `team_role_assign_command.dart:90` (C09)

## Project-specific checks

All passed:
- Result<T> end-to-end with exhaustive `switch`
- Constructor injection (StringSink for IO)
- Sub-parent two-level nesting (mirror C08 lookup-request)
- Saga UX hint (5xx → stderr, no rollback) on `team_register`
- **`--role-id` → wire `role` translation (8th C03 M1 application)** — impl + test pin
- **`team reset-password` POST not PUT** — explicit test assertion
- ISO8601 validation on `--birth-date` (mirror C03 patient admit)
- `team list` queryParameters omit-when-absent

## Findings

None. Zero MUST_FIX, zero SHOULD_FIX, zero NIT.

## Outcome

**PASSED — C09 ready to close. Onda 4 fecha.**
