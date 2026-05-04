# C04 — W3 (QUALITY) Final Gate

**Verdict:** PASSED
**Date:** 2026-05-04
**Agent:** flutter-quality-checker

## Quality battery

| Check | Status | Details |
|-------|--------|---------|
| `dart analyze apps/cli/` | PASS | `No issues found!` (0/0/0) |
| `dart format --set-exit-if-changed` | PASS | 83 files, 0 changed |
| `dart test apps/cli/` | PASS | **+277: All tests passed!** (0 fails, 0 skips) |
| AOT compile | PASS | `dart compile exe apps/cli/bin/acdg.dart -o /tmp/acdg-c04-w3` succeeded |
| Smoke `acdg family --help` | PASS | 4 subcommands: add, assign-caregiver, remove, update-identity |
| Smoke `acdg family add --help` | PASS | 3 required + 6 optional flags advertised |
| Workspace `dart analyze` | PASS | Zero issues attributable to `apps/cli/` |
| Workspace `dart test` (cli + bff/web + bff/contracts) | PASS | **+1949** (Δ +58 vs C03 baseline 1891) |

## Convention checks

All passed:
- Naming PascalCase + suffixes
- snake_case files
- Imports SDK → external → relative; alphabetical
- No `print(...)` in family commands or `_command_helpers.dart`
- No direct `Stdio.stdout` writes in `Command.run()` (all via `_writeOut`/`_writeErr`)
- No orphan TODO/FIXME
- No `client_secret` leakage (3 hits in safety doc-comments only)
- No raw token logging
- `try/catch` only at adapter boundaries (`bff_client.dart::_attempt`)
- `final class` everywhere
- Helper rename clean — no `_patient_helpers.dart` remnant; all 8 patient files import `_command_helpers.dart`
- C03 M1 regression preserved — `patient_audit_command.dart:64` still uses `query['eventType']`
- Result<T> end-to-end

## Wire format adherence (cross-checked vs BFF intents)

| Verb | Method | Path | Body | BFF intent verification |
|------|--------|------|------|-------------------------|
| `family add` | POST | `/patients/{id}/family-members` | `{memberPersonId, relationship, birthDate, prRelationshipId, isResiding, isCaregiver, hasDisability, requiredDocuments, cpf?, fullName?}` | MATCH — `cpf`/`fullName` confirmed top-level (not nested) |
| `family remove` | DELETE | `/patients/{id}/family-members/{memberId}` | (none) | MATCH — DELETE no-body invariant |
| `family assign-caregiver` | PUT | `/patients/{id}/primary-caregiver` | `{memberPersonId}` | MATCH — exact key |
| `family update-identity` | PUT | `/patients/{id}/social-identity` | `{typeId, description?}` | MATCH — exact key + correct dropNulls |

C03 M1-style casing surprise: NONE this round.

## BffClient PUT + DELETE — security spot-checks

All passed:
- Bearer header attached on PUT + DELETE (single `onRequest` interceptor for all verbs)
- 401 → refresh once → retry once with same body (PUT) / same path (DELETE)
- 4xx (non-401) → ServerError, NO retry
- `RefreshTokenInvalidError` → clear store + AuthRequiredError
- Refresh path invoked AT MOST ONCE (W0 persistent-401 DELETE test asserts `refreshCalls == 1, adapter.calls <= 2`)

## W2 fixes verification

W2 verdict: **APPROVED Round 1**, 0 MUST_FIX, 4 SHOULD_FIX all defer-to-future.

| Item | Defer-to | Applied? |
|------|----------|---------:|
| S1 — unused `formatter` field on 4 family commands | C10 | NO (correct per W2) |
| S2 — `--member-cpf` ↔ `--member-person-id` mutual-exclusion | next family iteration | NO (correct per W2) |
| S3 — `--required-document` lookup validation | post C09/C10 | NO (correct per W2) |
| S4 — `--bff` global flag hardcoded | C10 | NO (pre-existing C02/C03 debt) |

## Test count breakdown

| Bucket | Count |
|--------|------:|
| `apps/cli/` (post-C04) | 277 |
| Workspace reachable (cli + bff/web + bff/contracts) | 1949 |
| Δ vs C03 baseline (1891) | +58 |

## Outcome

**PASSED.** C04 ready to close.

**Final test count:** 277 (cli) / 1949 (workspace reachable).
