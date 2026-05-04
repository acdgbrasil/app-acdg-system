# C10 — W0 (RED) Report

**Agent:** test-writer
**Wave:** 0 — RED
**Date:** 2026-05-04
**Status:** RED CONFIRMED. 9 test files + 17 fixtures + 44 golden placeholders + 3 helpers. C02-C09 GREEN preserved (536 reachable from `test/commands` + `test/cli_runner_test.dart`).

## 1. File inventory

### Test infrastructure (`apps/cli/test/golden/_helpers/`)
- `mock_bff_server.dart` — `(method, path)` → `MockResponse` adapter for Dio. Wildcard support. Records requests for assertions. Synthetic 404 on unmatched routes.
- `golden_runner.dart` — `runCliForGolden([...args], mockAdapter, credentialStore)` drives `CliRunner` end-to-end + captures stdout/stderr/exitCode. Includes `FakeCredentialStore` (signedIn/signedOut/withSession factories).
- `golden_compare.dart` — `expectGolden(actual, relativePath)` + `UPDATE_GOLDENS=1` env mode.

### Test files (9 namespaces)
| File | Tests | Coverage |
|------|------:|----------|
| `patient_golden_test.dart` | 13 | list (table+json+yaml+empty+search), get, audit, register, admit, discharge, readmit, withdraw |
| `family_golden_test.dart` | 4 | all 4 family verbs |
| `lookup_golden_test.dart` | 7 | get (table+json+yaml), batch, create, toggle (PATCH), request list |
| `team_golden_test.dart` | 8 | list, get, register, deactivate, reactivate, reset-password, role assign |
| `care_golden_test.dart` | 2 | appointment, intake |
| `protection_golden_test.dart` | 2 | violation, referral |
| `auth_golden_test.dart` | 3 | status signedIn/Out, logout (login excluded — covered separately) |
| `assessment_golden_test.dart` | 2 | housing, health (representative) |
| `errors_golden_test.dart` | 5 | 401, no session, 422, 500, unknown command |
| **Total** | **46** | within ticket target ~50 |

### Fixtures (17 JSON files)
17 fixtures under `_fixtures/{patient,family,lookup,team,care,protection,errors}/`. Use canonical envelope `{data: ..., meta: {timestamp: ...}}`.

### Golden placeholders (44 empty files)
Empty `.golden` files. W1 populates via `UPDATE_GOLDENS=1 dart test`.

## 2. Decisions taken

1. **`MockBffServer` ≠ per-command `_CapturingAdapter`** — different goal: replay canned BFF responses for snapshot comparison.
2. **Drive through `CliRunner.run([...])` not leaf commands** — locks down assembled behavior including args dispatch + `--output` resolution.
3. **Empty `.golden` files instead of pre-rendered** — avoids "test cheating" REGRA #2 pattern. W1 populates via `UPDATE_GOLDENS=1` after wiring + manual inspection.
4. **Auth bypass via `FakeCredentialStore.signedIn()`** — no `--no-auth` global footgun.
5. **Exit-code matrix re-validated** — mirrors `_command_helpers.dart::exitCodeFor`.
6. **`auth login` excluded** — loopback HTTP server + browser open already covered.
7. **`protection placement-history` excluded** — YAML-only via injected `fileReader`.

## 3. W1 contract

### 3.1 `CliRunner` additive constructor params (CRITICAL)
```dart
CliRunner(stdout: out, stderr: err, adapter: mockAdapter, credentialStore: fakeStore)
```
Both new params: named, optional, nullable, default null = production wiring.

### 3.2 `--output` global flag wiring (CRITICAL — current debt)
Today `--output` parsed but ignored. W1 must:
1. Inside `CliRunner.run`, parse `--output` first, then pass through `resolveFormatter(explicitFormat: ..., isTerminal: ...)`.
2. `resolveFormatter` exists in `auto_formatter.dart` — only call-site missing.

### 3.3 `--bff` global flag wiring (DEBT pre-C03)
Wire `parsedArgs['bff']` into `_buildBffClient`.

### 3.4 Decode envelope helpers (existing — keep stable)
`decodeStandardIdResponse` 7 call-sites. No change.

### 3.5 Populate goldens
After §3.1-§3.3: `UPDATE_GOLDENS=1 dart test test/golden`. Manual inspect — table widths, JSON/YAML format, error stderr captures.

## 4. Open questions for W1

1. `--output=auto` test env: defaults to JSON (`stdout.hasTerminal == false`).
2. 401 + signedIn + no token client wired = test target. Runner-level refresh wiring is separate debt.
3. `errors/no_session_table.golden` captures stderr (auth errors flow through `_writeErr`).
4. `lookup batch` fixture decode — verify shape on populate.

## 5. RED state confirmed

```
$ dart analyze apps/cli/test/golden
2 issues — adapter/credentialStore params not yet defined on CliRunner.

$ dart test apps/cli/test/golden
Every golden test file fails to load.

$ dart test apps/cli/test/commands apps/cli/test/cli_runner_test.dart
00:02 +536: All tests passed! (C02-C09 baseline preserved)
```

## 6. No impl files modified

`apps/cli/lib/**` untouched. C02-C09 test files untouched.
