# C10 — W2 Code Review (Round 1)

**Agent:** flutter-code-reviewer
**Wave:** 2 — REVIEW
**Date:** 2026-05-04
**Verdict:** **APPROVED**

## Summary

W1 R1+R2 consolidated impl is sound. Three Onda-4 debts (`--output` resolver, `--bff` flag, CliRunner testing injection) closed cleanly. 11 W0 contract drift clusters were renegotiated and aligned with the C02-C09 leaf source-of-truth — no leaf signatures touched. 704 / 704 GREEN, `dart analyze` reports 0 issues, and the golden tree lays down a stable snapshot baseline for the 9-namespace surface.

I verified:
- 704 tests GREEN locally (`apps/cli/`); 46 of those are the new golden tests under `test/golden/`.
- `dart analyze apps/cli` = `No issues found!`.
- Diff against `HEAD` for `apps/cli/lib/src/cli_runner.dart` is purely additive on the public surface — only constructor and factory params grew, no removals or reshapes.
- 14 of 44 goldens are intentionally empty (lifecycle PUT/DELETE 204), which I confirmed by reading the leaf `case Success(): return 0;` branches that emit nothing on stdout (e.g. `family_add_command.dart:146-148`, `assessment_housing_command.dart:147`).
- Mock matcher rewrite handles single- and multi-`*` patterns consistently; counter-cases (trailing `/`, mismatched segment counts) reject correctly.

## What I checked vs what I found

### Architecture (PASS)

- **Result<T> end-to-end** — preserved. `_revokeRefreshToken` (`cli_runner.dart:865-895`) keeps the `try/catch → Result` adapter-boundary pattern. Every leaf still returns `Result<T>` via `BffClient`. No regression.
- **`try/catch` only at adapter boundaries** — verified. `cli_runner.dart` has two `try` blocks: line 193 (around `resolveFormatter` to map `InvalidArgError`→stderr+64) and line 204 (around `assembled.run` to map `UsageException`→stderr+64). Both are at the runner boundary, not in domain. `_openBrowser` (`cli_runner.dart:835-850`) and `_revokeRefreshToken` are also adapter boundaries — acceptable.
- **`final class` discipline** — preserved. `CliRunner` (line 139), `_GlobalFlags` (line 329), `_CapturingCommandRunner` (line 369), `MockResponse`, `MockBffServer`, `_Route`, `_MockAdapter`, `GoldenInvocation`, `FakeCredentialStore` — all `final class`.
- **Imports order** — alphabetical SDK → external → relative in every modified file. `cli_runner.dart:33-108` correct; the 9 golden test files all use `package:test/test.dart` then 3 relative `_helpers/...` imports.

### CliRunner additive params (PASS — CRITICAL)

- `cli_runner.dart:140-163` — three new params (`adapter`, `credentialStore`, `clock`) all named-optional with `null` defaults. When `null`:
  - `adapter == null` ⇒ `_buildBffClient` skips the `Dio()..httpClientAdapter = adapter` branch and passes `dio: null` to `BffClient`, which then constructs a default `Dio()` (`bff_client.dart:60`). Identical to pre-C10 wiring.
  - `credentialStore == null` ⇒ `cli_runner.dart:151-155` falls back to `FileCredentialStore(path: defaultPath(env: Platform.environment))` — identical to pre-C10 wiring.
  - `clock == null` ⇒ forwarded to `AuthStatusCommand.now`, which already handled `null` via `now?.call() ?? DateTime.now().toUtc()` (`auth_status_command.dart:41`) since C02. Zero behavioral change for production.
- C02-C09 leaf signatures unchanged — confirmed by `git diff` not touching any `commands/*.dart` and 658 baseline tests still GREEN.

### `--output` resolver wiring (PASS — DEBT 1 RESOLVED)

- `_parseGlobals` (`cli_runner.dart:339-357`) — extracts `--output` once into `_GlobalFlags`, returns `null` for the `'auto'` sentinel and the actual string for explicit choices. `FormatException` catch falls back to defaults (any malformed argv reaches the assembled runner, which surfaces the real usage error — clean two-stage pattern, no double-error noise).
- `run()` (`cli_runner.dart:190-214`) — calls `resolveFormatter(explicitFormat: globals.output, isTerminal: _stdoutHasTerminal(_stdout))` and only on `InvalidArgError` writes to stderr + exits 64. Note that an invalid value like `--output=xml` actually falls through `_parseGlobals` (the side parser throws on `allowed:`-violation, returns default `null`), so the side parse alone never surfaces the InvalidArgError; the assembled runner catches it as a `UsageException` and gives a usage-printout exit 64. Both paths converge on exit 64. Acceptable.
- `_stdoutHasTerminal` (`cli_runner.dart:362-364`) — `sink is Stdout && sink.hasTerminal`. Test envs pass `StringBuffer`, fails the `is Stdout` check, returns `false` → JSON. Production binary (`bin/acdg.dart:12`) passes `stdout` (the dart:io Stdout instance), so `is Stdout` is true and `hasTerminal` is consulted. Correct semantics.
- Per-`run()` re-instantiation — `_assemble` rebuilds 9 sub-commands per invocation. Cheap: closures + factory ctors only, zero I/O. The eager `_runner` from the constructor is replaced on every `run()` call (`cli_runner.dart:203 _runner = assembled`). The `late _CapturingCommandRunner _runner;` field is non-final, so reassignment is legal. Confirmed via the test (`cli_runner_test.dart` test 4) that constructor still produces a usable `runner` for `--help`-style discovery.

### `--bff` flag wiring (PASS — DEBT 2 RESOLVED)

- `_parseGlobals` (`cli_runner.dart:349`) extracts; `_buildBffClient(baseUrl: globals.bffUrl, ...)` (`cli_runner.dart:247`) consumes; default fallback `_defaultBffUrl = 'http://localhost:3000'` preserved (`cli_runner.dart:113`). Single source of truth — both side parser and `_assemble`'s argParser reference the same `_defaultBffUrl` and `_outputFormats` constants, so no drift risk.

### Mock matcher rewrite (PASS)

`mock_bff_server.dart:168-190` — generic segment matcher handles single and multi-`*` uniformly. Verified edge cases by reading:
- `/patients/*/family-members` vs `/patients/abc/family-members` → 4-segment lists match position-by-position; `*` accepts non-empty `'abc'`. ✓
- `/patients/*` vs `/patients/` → segments `['','patients','*']` vs `['','patients','']`; `*` rejects empty segment (line 182). ✓
- `/lookups/*/toggle/*` vs `/lookups/dominio_genero/55.../toggle` → 5 vs 5 segments, `toggle` (literal) at index 3 matches `55...` ⇒ no, mismatch — correctly rejected (line 185). ✓
- `/lookups/dominio_genero/55.../toggle/` (trailing slash) vs same pattern → 6 vs 5 segments — early rejected at line 179. ✓

The matcher is conservative (single `*` = exactly one non-empty segment, no greedy multi-segment matching) which is exactly what the goldens need.

### Golden tests (PASS)

- All 46 GREEN. The 14 empty `.golden` files correspond to 1-1 with leaf commands whose `case Success(): return 0;` emits nothing on stdout — verified for `family_add_command.dart:146-148`, `assessment_housing_command.dart:147`, `team_deactivate_command.dart`, etc.
- `expectGolden` (`golden_compare.dart:41-63`) treats empty file as `expect(actual, equals(""))`, which is a real assertion (catches future regressions where someone adds a `_writeOut` to a 204 verb).
- Auto mode in non-TTY → JSON: confirmed by `lookup/get_json.golden` capturing single-line minified JSON, while `lookup/get_table.golden` captures the column-aligned table only when `--output=table` is explicit.
- No PII risk: every UUID in fixtures is the canonical synthetic `1111-1111-...` / `8888-1111-...` pattern; CPF `12345678900` is a fictional sequence (not a Receita Federal valid checksum); names like `Maria Silva` / `Ana Pereira` are synthetic. Token strings in `FakeCredentialStore.signedIn()` are `fake-access-token` / `fake-refresh-token` (no real bearer leaks). `errors/auth_expired.json` carries no token. Acceptable for snapshot tests.

### W0 alignment — 11 clusters (PASS)

I sampled the highest-risk clusters against impl source-of-truth:
- **A (clock)** — `auth_status_command.dart:23,41` already had `DateTime Function()? now`. CliRunner wires it via `_clock` → `_buildAuthCommand(clock: _clock)` (`cli_runner.dart:261`) → `AuthStatusCommand(now: clock)` (`cli_runner.dart:413`). Tests pin `() => DateTime.utc(2099,1,1).subtract(24h)` → deterministic `(in 24h0m)`.
- **B (signed-out → exit 2)** — Test wires 401 fixture for `GET /patients` and `FakeCredentialStore.signedOut()`. BffClient interceptor adds no Bearer; mock returns 401; `_refreshAndRetry` sees `tokenClient == null` and returns `Failure(AuthRequiredError())` (`bff_client.dart:304-305`); `exitCodeFor(AuthRequiredError())` = 2. Renamed test name accurately reflects the dispatch path.
- **C (protection paths)** — verified `protection_violation_command.dart:162` POSTs `/patients/$patientId/violations` (no `/protection/` segment). Test register matches.
- **D, E, F (lookup paths/flags)** — `lookup_toggle_command.dart` PATCH `/lookups/<table>/<id>/toggle`; `lookup_request_list_command.dart` GETs `/lookup-requests`; `lookup_batch_command.dart` takes positional CSV. Tests align.
- **G, K (patient register flag set)** — `patient_register_command.dart:_buildBodyFromFlags` requires the 5 flags. Test passes all 5. Validation 422 test reuses the same 5 flags so the wire body is well-formed; mock returns 422 to exercise the server-error path. Sound.
- **H (family positional)** — all 4 family verbs use positional `<patient-id>`. Tests aligned.
- **I (assessment housing 15-field)** — verified by reading `assessment_housing_command.dart:155-198`: 7 strings + 3 ints + 5 bools = 15 fields. Test passes all 15 flags.
- **J (team role assign)** — `team_role_assign_command.dart:76-82` requires both `--system` AND `--role-id`. Test passes both. Fixture reuse of `team/register_success.json` for `role assign` is acceptable since the BFF returns the same `{data: {id: ...}}` envelope; the rendered golden `Assigned role 88888888-9999-4999-8999-999999999999` correctly surfaces the id from that fixture.

### Code quality (PASS)

- No `print(...)` in C10-modified code. The pre-existing `print` in `commands/_stub_command.dart:28` is C01-era scaffolding with `// ignore: avoid_print` and is not touched by C10.
- No orphan TODO/FIXME in `apps/cli/lib` or `apps/cli/test/golden`.
- `dart format --set-exit-if-changed` per W1 report — clean.

### Tests (PASS)

- 704 / 704 GREEN locally (`dart test` summary line: `+704: All tests passed!`).
- `test/golden` alone: 46 GREEN.
- Baseline (704 − 46 = 658) matches W0 RED snapshot of C02-C09 GREEN.

## Open questions resolution (W1 §7)

1. **Validation 422 stderr verbosity (`Server error (422): HTTP 422`)** — confirm. The C03 contract for `BffClient` does not parse the BFF body for non-2xx; it surfaces `ServerError(status, 'HTTP $status')`. Adding structured-body parse is a cross-cutting change that touches every command. **Out of scope for C10**; track as future debt if/when the BFF body schema is stable.
2. **Cluster B test name** — accurate. The `signed-out` test does NOT short-circuit before HTTP; it dispatches and the BFF/mock returns 401. Naming reflects this.
3. **Mock matcher rewrite** — endorsed. Promotion to a documented helper API is a nice-to-have; current shape is fine for the 46 goldens. **Not blocking.**
4. **Cluster J fixture reuse** — endorsed. The `{data: {id: ...}}` envelope is identical across `team register` and `team role assign`, so reuse is semantically valid and reduces fixture surface. **Not blocking.**
5. **Empty goldens (14 of 44)** — endorsed. The empty golden is a real assertion (file content == ""); regression-detecting if a future change accidentally adds stdout to a 204 verb.

## Findings

### MUST_FIX — none.

### SHOULD_FIX — none.

### Informational (FYI, not blocking)

1. **(FYI) `auth status` exit code asymmetry** — `errors_golden_test.dart` second test names "signed-out … → exit 2" but uses `patient list`, not `auth status`. The `auth status` command itself returns exit code **1** (no session) per `auth_status_command.dart:38` — it does NOT round-trip to BFF. So the `auth/status_signed_out.golden` (used by `auth_golden_test.dart` test 2, which asserts `isNot(equals(0))` only) is consistent with exit 1. The two tests probe two different code paths and are correctly named in their respective files. No issue — flagging here only because it's easy to confuse the two on a casual read.
2. **(FYI) `late _CapturingCommandRunner _runner` reassignment** — non-final `late` is reassigned in every `run()` call. Legal, but means `runner` getter reflects the most recent `run()` invocation. The `cli_runner_test.dart` tests that use `runner.run(['--help'])` go through the eager-built runner, which uses the auto-resolved formatter for `_stdout` (StringBuffer ⇒ JSON). No test depends on the formatter for `--help` output, so this is fine. Future contributors who lean on `runner` for non-help flows should be aware that `--output`/`--bff` from later `cli.run([...])` calls will mutate this getter.
3. **(FYI) BffClient does not close `Dio`** — per-`run()` rebuild creates a fresh `BffClient` (and fresh `Dio` if `adapter` is supplied) and discards the prior one. In CLI lifetime (one process per invocation) the OS reaps everything on exit. Not a leak in practice, but worth noting if `CliRunner` is ever embedded long-lived.

## Verdict

**APPROVED** — proceed to W3 (quality gate). The implementation is canonical, tests are stable, and the 3 Onda-4 debts are closed without disturbing C02-C09 leaf surface.

## Files inspected

- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/cli/lib/src/cli_runner.dart` (full read + diff vs HEAD).
- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/cli/lib/src/formatters/auto_formatter.dart`.
- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/cli/lib/src/errors/cli_error.dart`.
- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/cli/lib/src/session/bff_client.dart` (header + 401 path).
- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/cli/lib/src/commands/auth_status_command.dart`.
- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/cli/lib/src/commands/family_add_command.dart`.
- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/cli/lib/src/commands/assessment_housing_command.dart` (relevant sections).
- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/cli/lib/src/commands/patient_register_command.dart` (success path).
- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/cli/lib/src/commands/team_role_assign_command.dart` (required flags).
- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/cli/test/golden/_helpers/mock_bff_server.dart`.
- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/cli/test/golden/_helpers/golden_runner.dart`.
- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/cli/test/golden/_helpers/golden_compare.dart`.
- All 9 golden test files.
- All 18 fixtures.
- All 44 `.golden` files (sampled).
- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/cli/test/cli_runner_test.dart`.
- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/cli/test/commands/_command_test_helpers.dart`.
- `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/apps/cli/bin/acdg.dart`.

## Quality gate evidence

- `dart analyze apps/cli/` ⇒ `No issues found!`.
- `dart test apps/cli/` ⇒ `00:03 +704: All tests passed!`.
- `dart test apps/cli/test/golden` ⇒ `00:00 +46: All tests passed!`.
- `git diff --stat apps/cli/lib/src/cli_runner.dart` ⇒ `234 insertions(+), 74 deletions(-)` — purely additive on public surface; deletions are stale comments + the inlined `_runner` build that was extracted into `_assemble`.
