# C03 — W1 (GREEN) Report

**Agent:** flutter-bff-implementer
**Wave:** 1 — GREEN
**Date:** 2026-05-04
**Status:** All 219 CLI tests pass (was 145 at end of C02; +74 net new C03 tests). 78 W0 contract tests now GREEN. `dart analyze apps/cli/` returns 0 issues; `dart format` clean (75 files, 0 changed); AOT compile succeeds.

## Files created (implementation)

- `apps/cli/lib/src/commands/_patient_helpers.dart` — `exitCodeFor(Object)`, `stderrMessageFor(Object)`, `dropNulls(Map)` shared between the eight subcommands.
- `apps/cli/lib/src/commands/patient_list_command.dart`
- `apps/cli/lib/src/commands/patient_get_command.dart`
- `apps/cli/lib/src/commands/patient_audit_command.dart`
- `apps/cli/lib/src/commands/patient_register_command.dart`
- `apps/cli/lib/src/commands/patient_admit_command.dart`
- `apps/cli/lib/src/commands/patient_discharge_command.dart`
- `apps/cli/lib/src/commands/patient_readmit_command.dart`
- `apps/cli/lib/src/commands/patient_withdraw_command.dart`

## Files modified (implementation)

- `apps/cli/lib/src/session/bff_client.dart` — added `post<T>(path, {body, decode})`. Refactored `_attemptGet`/`_refreshAndRetryGet` into a single generalized `_attempt({method, path, body, decode})` + `_refreshAndRetry({...})` so GET and POST share the retry-once invariant by construction. Body is JSON-serialized via `Headers.jsonContentType`; the retry path resends the original body verbatim.
- `apps/cli/lib/src/commands/patient_command.dart` — replaced C01 leaf stub with parent. Eight optional ctor params; falls back to schema-only `_PlaceholderCommand` set when collaborators absent (mirrors `AuthCommand`). `run()` returns 64 (EX_USAGE) without calling `printUsage()` (the parent test invokes `cmd.run()` directly without a runner; `printUsage()` would NPE on `runner.usage`).
- `apps/cli/lib/src/cli_runner.dart` — added `_buildBffClient` and `_buildPatientCommand` factories. Refactored `_buildAuthCommand` to take `httpClient`/`credentialStore`/`loadDiscovery` as injected params so the runner builds a single shared `http.Client`, `FileCredentialStore`, and discovery loader, then reuses them across `_buildAuthCommand` and `_buildBffClient` (no duplicate clients).
- `apps/cli/lib/cli.dart` — barrel exports for the eight new public command types + `PatientCommand`.

## Test counts

| Bucket | Before C03 | After C03 |
|--------|-----------:|----------:|
| `apps/cli/` total | 145 | **219** |
| Δ | — | **+74** |

`dart test apps/cli/` → `00:00 +219: All tests passed!`

The +74 delta accounts for the C01 patient-stub tests deleted by W0 plus the 78 new W0 contract tests.

## Quality gates

- `dart analyze apps/cli/` → 0 issues (lib + test).
- `dart format apps/cli/lib/ apps/cli/test/` → clean (75 files, 0 changed).
- `dart compile exe apps/cli/bin/acdg.dart -o /tmp/acdg-c03-w1` → succeeded.
- `acdg patient --help` → advertises all 8 subcommands.
- `acdg patient list --help` → advertises `--search/--status/--cursor/--limit`.

## Try/catch audit

| File | Boundary |
|------|----------|
| `bff_client.dart` `_attempt` | Dio HTTP request + JSON parse |
| `patient_admit_command.dart` `_isValidIso8601` | `DateTime.parse` (input validation) |
| `patient_register_command.dart` `_readYamlBody` | `fileReader` (file I/O) + `loadYaml` (parser) |

Application/command layer propagates `Result<T>` end-to-end.

## Decisions taken

1. **Single shared `_attempt`/`_refreshAndRetry` for GET and POST.** W0 §4.4 suggested factoring; chose the larger generalization (single function with `method` and `body` params) rather than two near-identical helpers. The retry path receives the original body unchanged via closure capture.

2. **`Object?` body type, not `Map<String, Object?>`.** Matches Dio's `data` param.

3. **`_patient_helpers.dart` accepts `Object`, not `CliError`.** `Result.error` is statically `Object`. The helper narrows internally with `is` type checks against the `CliError` family. Avoids `error as CliError` cast (forbidden by `acdg_lints/no_sealed_class_downcast` per P5).

4. **Pagination cursor surfaced on stderr.** W0 §4.2 left this permissive; emits `Next page cursor: <value>` to stderr after the formatted stdout payload. Keeps stdout pipe-clean.

5. **`event_type` (snake_case) on the wire.** W0 §4.3.

6. **`--from-yaml` reader injected; YAML→JSON tree conversion is recursive.** `YamlMap` and `YamlList` aren't `Map<String, Object?>`/`List<Object?>` — impl walks the tree. File I/O and YAML parse failures translated to `InvalidArgError`.

7. **Mutually-exclusive guard fires BEFORE file I/O.** Throws `UsageException` when `--from-yaml` + field flags both passed.

8. **`PatientCommand.run()` returns 64 without `printUsage()`.** W0 parent test calls `cmd.run()` directly without a `CommandRunner`. Production invocations always go through the runner.

9. **DTO-faithful body shape (W0 §4.1 divergences).** `discharge` → `{reason, notes?}` (no `--discharged-at`). `readmit` → `{notes?}` only. `withdraw` → `{reason (REQUIRED), notes?}`.

10. **`_buildBffClient` does NOT wire `tokenClient`/`discovery` yet.** Auth subcommands handle refresh explicitly. Patient verbs that hit a 401 surface `AuthRequiredError` directly via `_translate`. Wiring runner-level refresh-on-401 requires async-aware factory + discovery cache — left for W2 / C04.

## Public API delta

### New types (exported via `cli.dart`)
- `cli.PatientCommand`, `cli.PatientListCommand`, `cli.PatientGetCommand`, `cli.PatientAuditCommand`, `cli.PatientRegisterCommand`, `cli.PatientAdmitCommand`, `cli.PatientDischargeCommand`, `cli.PatientReadmitCommand`, `cli.PatientWithdrawCommand`

### Modified types
- `BffClient.post<T>(path, {body, decode}) -> Future<Result<T>>` — new verb mirroring `get<T>`.
- `BffClient` internals: `_attemptGet`/`_refreshAndRetryGet` collapsed into `_attempt`/`_refreshAndRetry` (private).

### New subcommands wired in `cli_runner.dart`
- `acdg patient list [--search=X] [--status=Y] [--cursor=Z] [--limit=N]`
- `acdg patient get <patient-id>`
- `acdg patient audit <patient-id> [--event-type=...] [--limit=N] [--offset=O]`
- `acdg patient register {--from-yaml=path | --person-id=X --pr-relationship-id=Y --icd-code=Z --diagnosis-date=YYYY-MM-DD --diagnosis-description=...}`
- `acdg patient admit <patient-id> --reason=X --admitted-at=ISO8601 [--notes=...]`
- `acdg patient discharge <patient-id> --reason=X [--notes=...]`
- `acdg patient readmit <patient-id> [--notes=...]`
- `acdg patient withdraw <patient-id> --reason=X [--notes=...]`

## Open questions / TODO for W2

- **Refresh-on-401 wiring at runner level.** `_buildBffClient` does not pass a `TokenClient` today. If W2 wants `acdg patient list` to silently auto-refresh expired sessions, the runner needs an async discovery-aware factory plus a cache. Suggest a small `BffClientFactory` that lazily resolves discovery on first call. Deferred — out of scope for C03 GREEN.
- **`_buildBffClient` ignores its `loadDiscovery` parameter.** Kept the param to preserve future-wiring shape (W2/C04 will plug in `tokenClient`). W2 may either drop the param or wire it.
- **Default formatter hard-coded to `JsonFormatter`.** The global `--output` flag resolver (C10) will switch on `'json'/'table'/'yaml'/'auto'`. Patient subcommands will get the resolver via constructor injection at that point.
- **Cursor surfacing format.** Currently `Next page cursor: <value>` (stderr). If C10 introduces a structured pagination envelope the surfacing layer may move into the formatter contract.
- **`--from-yaml` schema validation.** YAML body is converted to JSON map and POSTed verbatim — BFF rejects bad shapes with 422. C10 may add client-side schema validation to fail-fast before the round-trip.

## Deviation from W0 surface

None. The contract divergences flagged in W0 §4.1 (discharge omits timestamp, readmit only notes, withdraw requires reason) were implemented as documented; no W0 test was modified.
