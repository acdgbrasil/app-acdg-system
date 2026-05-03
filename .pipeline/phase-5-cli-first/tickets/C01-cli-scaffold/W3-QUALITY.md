# C01 W3 — Quality Gate

## Verdict: PASSED

---

## 1. dart analyze

**PASS — zero issues across all three targets.**

| Target | Output |
|--------|--------|
| `apps/cli/lib/` + `apps/cli/bin/` | `Analyzing lib, bin...` → `No issues found!` |
| `apps/social_care_bff/desktop/lib/` | `Analyzing lib...` → `No issues found!` |
| `apps/social_care_bff/web/lib/` | `Analyzing lib...` → `No issues found!` |

Cross-package non-regression confirmed: BFF desktop + web stayed at 0 issues.

---

## 2. dart format

**PASS — exit 0.**

```
Formatted 21 files (0 changed) in 0.04 seconds.
```

All 21 files in `apps/cli/lib/` + `apps/cli/bin/` are already canonically formatted. No drift.

---

## 3. CLI tests

**PASS — 77/77 GREEN.**

```
00:00 +76: test/session/credential_store_test.dart: CredentialStore (abstract interface — H5) is implementable from foreign code
00:00 +77: All tests passed!
```

Matches the W2 report's claim of 77 new tests in C01 (cli_runner, command stubs, formatters, credential store, bff_client interface).

---

## 4. Cross-package non-regression

| Package | Expected | Actual | Verdict |
|---------|----------|--------|---------|
| cli | 77 | 77 | PASS |
| contracts | 535 | 535 | PASS |
| web | 1137 | 1137 | PASS |
| desktop | 500 +1 skip | 500 +1 skip (`+500 ~1`) | PASS |
| **Total** | **2249 +1 skip** | **2249 +1 skip** | **PASS** |

Delta from baseline (2172 +1 skip) = **+77** — exactly matches the 77 new C01 tests. Zero regressions in BFF packages.

---

## 5. Compile smoke test

**PASS — all three scenarios behave as specified.**

### `dart compile exe apps/cli/bin/acdg.dart -o /tmp/acdg-c01-smoke`
```
Generated: /tmp/acdg-c01-smoke
```
AOT compile succeeds.

### `/tmp/acdg-c01-smoke --help`
- Banner exhibits banner header line, usage line.
- 9 commands shown alphabetically: assessment, auth, care, family, health, lookup, patient, protection, team.
- 4 global flags shown: `-h, --help`, `--bff`, `--output` (with allow-list `[json, table, yaml, auto (default)]`), `--quiet`.
- Exit code: **0** ✓

Note: ticket request mentions "3 global flags" but the binary surfaces 4 (the 3 spec'd `--bff`/`--output`/`--quiet` plus the standard `-h, --help`). The `args` package always surfaces `-h, --help`; this is the documented behaviour and matches every other CLI in the ecosystem (`gh`, `aws`, etc.). PASS.

### `/tmp/acdg-c01-smoke patient`
```
Not implemented yet — pending C03
```
Exit code: **0** ✓ (stub for C03 per ticket §"Comportamento mínimo").

### `/tmp/acdg-c01-smoke unknown-command`
```
Could not find a command named "unknown-command".

Usage: acdg <command> [arguments]
[...]
```
Exit code: **64** ✓ (`EX_USAGE` per `sysexits.h`, matching W2 report's UsageException → exit 64 wiring).

Cleanup: `/tmp/acdg-c01-smoke` removed.

---

## 6. Workspace integrity (dart pub get)

**PASS — exit 0.**

```
Got dependencies!
45 packages have newer versions incompatible with dependency constraints.
```

`apps/cli` is correctly registered as workspace member; root `dart pub get` resolves the entire workspace clean. The "45 newer versions available" line is informational only (no constraint failures, no errors).

---

## Final verdict

**PASSED — C01 ready to commit / proceed to C02.**

Summary:
- `dart analyze`: 0 issues across cli + cross-package targets
- `dart format`: 0 drift across 21 files
- 77 new CLI tests GREEN
- BFF baseline preserved: 2172 +1 skip → 2249 +1 skip (delta +77, zero regressions)
- AOT compile + `--help` + stub command + unknown-command exit-64 all behave to spec
- Workspace member `apps/cli` resolves clean

Three SHOULD_FIX items flagged in W2 (CliError propagation in `run`, `Credentials.fromJson` TypeError catch, `BffClient.get` cast) are non-blocking for C01 and should be addressed in C02 before PKCE persistence ships. Five NICE_TO_HAVE items are pure polish for C10/C11.

Pass to commit / C02 kickoff.
