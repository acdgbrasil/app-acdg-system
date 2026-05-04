# C04 — W1 (GREEN) Report

**Agent:** flutter-bff-implementer
**Wave:** 1 — GREEN
**Date:** 2026-05-04
**Status:** All 277 CLI tests pass (was 219 at end of C03; +58 net new C04 tests). 57 W0 contract tests now GREEN. `dart analyze apps/cli/` returns 0 issues; `dart format` clean (83 files); AOT compile succeeds; `acdg family --help` advertises 4 subcommands; C03 patient + C02 auth suites still GREEN.

## Files created (4 family commands)

- `apps/cli/lib/src/commands/family_add_command.dart` — POST `/patients/{id}/family-members` with saga envelope (DTO + `cpf`/`fullName` top-level).
- `apps/cli/lib/src/commands/family_remove_command.dart` — DELETE `/patients/{id}/family-members/{memberId}` (no body).
- `apps/cli/lib/src/commands/family_assign_caregiver_command.dart` — PUT `/patients/{id}/primary-caregiver` with `{memberPersonId}`.
- `apps/cli/lib/src/commands/family_update_identity_command.dart` — PUT `/patients/{id}/social-identity` with `{typeId, description?}` (drop-nulls).

## Files renamed

- `apps/cli/lib/src/commands/_patient_helpers.dart` → `_command_helpers.dart`. Helpers (`exitCodeFor`, `stderrMessageFor`, `dropNulls`) byte-identical to family verbs needs. 8 patient_*_command.dart imports updated. No logic changes.

## Files modified

- `apps/cli/lib/src/session/bff_client.dart` — added `put<T>(path, {body, decode})` and `delete<T>(path, {decode})`. Both reuse C03 `_attempt`/`_refreshAndRetry` (`method` knob already accepts arbitrary verbs); `delete<T>` deliberately omits `body` parameter on the public API.
- `apps/cli/lib/src/cli_runner.dart` — added `_buildFamilyCommand` factory; replaced C01 stub `FamilyCommand(stdout: stdout)` with production graph reusing shared `bffClient`.
- `apps/cli/lib/src/commands/family_command.dart` — replaced C01 stub with parent (mirrors `PatientCommand`). 4 optional ctor params; placeholder fallback when no collaborators.
- 8× `patient_*_command.dart` — import `_command_helpers.dart` (renamed). Logic unchanged.
- `apps/cli/lib/cli.dart` — barrel exports for 5 new public family types.

## Test counts

| Bucket | Before C04 | After C04 |
|--------|-----------:|----------:|
| `apps/cli/` total | 219 | **277** |
| Δ | — | **+58** |

## Quality gates

- `dart analyze apps/cli/` → 0 issues.
- `dart format apps/cli/lib/ apps/cli/test/` → clean (83 files).
- `dart compile exe apps/cli/bin/acdg.dart -o /tmp/acdg-c04-w1` → succeeded.
- `acdg family --help` advertises all 4 subcommands.
- `acdg family add --help` advertises all 9 declared options.
- C03 patient + C02 auth GREEN — `_attempt` extension for PUT/DELETE did not regress GET/POST.

## Try/catch audit

| File | Boundary |
|------|----------|
| `bff_client.dart::_attempt` | Dio HTTP + JSON parse (unchanged from C03; PUT/DELETE share same gate) |

No new `try/catch` in family command modules.

## Decisions taken

1. **Helper rename `_patient_helpers.dart` → `_command_helpers.dart`.** W0 §"Helper extraction decision" allowed when byte-identical. Renaming once now avoids noisier rename later when assessment/care/protection ship.

2. **`_attempt` shape unchanged — `method` is already a `String` parameter** from C03. PUT and DELETE drop in. No new `_Attempt` variant.

3. **`delete<T>` exposes no `body` parameter on public API.** Internally passes `null` to `_attempt`. Per HTTP convention DELETE bodies are advisory.

4. **Flag `--member-id` → wire `memberPersonId`** for `assign-caregiver` (W0 §4.7). Symmetric with `family remove --member-id`.

5. **`--full-name` over ticket-prose `--first-name`** — DTO-as-canon (W0 §4.6).

6. **`update-identity` collapses to `--type-id` REQUIRED + optional `--description`** (W0 §4.8). Ticket prose said `--gender --pronoun`; canonical DTO is `{typeId, description?}`.

7. **5xx UX hint on `family add`** — recovery hint pointing at `acdg patient get <id>`. Tests assert stderr contains "500" (permissive copy).

8. **Saga rollback NOT attempted client-side** (W0 §4.6). BFF responsibility.

9. **Permissive default flags** (`is-residing`, `is-caregiver`, `has-disability`) sent as explicit `false`; `requiredDocuments` defaults to `[]`.

10. **`stdout` line on `family remove` 204** — `Family member <id> removed from patient <id>.`. Test asserts non-null, not exact wording.

## Public API delta

### New types (exported via `cli.dart`)
- `cli.FamilyCommand` (replaces C01 stub), `FamilyAddCommand`, `FamilyRemoveCommand`, `FamilyAssignCaregiverCommand`, `FamilyUpdateIdentityCommand`.

### New BffClient verbs
- `BffClient.put<T>(path, {body, decode}) → Future<Result<T>>`
- `BffClient.delete<T>(path, {decode}) → Future<Result<T>>` (no `body` param)

### New subcommands wired in `cli_runner.dart`
- `acdg family add <patient-id> --relationship --birth-date --pr-relationship-id [...]`
- `acdg family remove <patient-id> --member-id`
- `acdg family assign-caregiver <patient-id> --member-id`
- `acdg family update-identity <patient-id> --type-id [--description]`

## Wire-format conformance

| Verb | Method | Path | Body |
|------|--------|------|------|
| `family add` | POST | `/patients/{id}/family-members` | `{memberPersonId, relationship, birthDate, prRelationshipId, isResiding, isCaregiver, hasDisability, requiredDocuments, cpf?, fullName?}` (`cpf`/`fullName` top-level) |
| `family remove` | DELETE | `/patients/{id}/family-members/{memberId}` | (none) |
| `family assign-caregiver` | PUT | `/patients/{id}/primary-caregiver` | `{memberPersonId}` |
| `family update-identity` | PUT | `/patients/{id}/social-identity` | `{typeId, description?}` |

## Open questions / TODO for W2

- `--member-cpf` vs `--member-person-id` mutual-exclusion guard. Currently both accepted; BFF resolves precedence. Client-side `UsageException` would fail-fast.
- `--required-document` validation. Passed verbatim; lookup validation server-side.
- 5xx saga retry hint copy. Permissive wording today.
- `family remove` 204 stdout line — could move under `--quiet` when C10 lands.
- `assign-caregiver` flag naming — picked `--member-id` for symmetry; revisit if user testing confuses with wire `memberPersonId`.
- `update-identity --description-from-file` — argument-from-file reader for multi-line text (mirror `patient register --from-yaml`).

## Deviation from W0 surface

None. The two DTO-vs-prose divergences flagged in W0 (§4.6 `--full-name` and §4.8 `--type-id`/`--description`) implemented as documented.
