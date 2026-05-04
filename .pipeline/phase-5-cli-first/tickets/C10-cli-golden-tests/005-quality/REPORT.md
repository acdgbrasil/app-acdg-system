# C10 — W3 (QUALITY) Final Gate

**Verdict:** PASSED
**Date:** 2026-05-04
**Final test count:** 704 GREEN apps/cli; **2376 GREEN workspace** (Δ +46 vs C09 baseline 2330).

## Quality battery

| Check | Status |
|-------|--------|
| `dart analyze apps/cli/` | PASS — 0 issues |
| `dart format` | PASS — 161 files, 0 changed |
| `dart test apps/cli/` | PASS — **704 GREEN** |
| AOT compile | PASS — 7.5M binary |
| Smoke `--output=table` | PASS — column-aligned table |
| Smoke `--output=json` | PASS — minified JSON |
| Smoke `--output=yaml` | PASS — YAML sequence |
| Smoke `--bff=<url>` positive | PASS — override honored |
| Smoke `--bff=<unreachable>` | PASS — exit 3 + Connection refused (error path correct) |
| Workspace `dart analyze` | PASS — 0 issues in apps/cli |
| Workspace `dart test` | PASS — **2376 GREEN** |

## Onda 4 debts — VERIFIED RESOLVED

1. **`--output` resolver runner-level** ✅ — `_parseGlobals` extracts; `_assemble` re-instantiates per `run()`. Same fixture renders 3 distinct payloads (table/json/yaml).
2. **`--bff` global flag wiring** ✅ — `globals.bffUrl` flows through `_buildBffClient(baseUrl:)`. Positive + negative smoke confirmed.
3. **CliRunner testing injection** ✅ — `adapter`/`credentialStore`/`clock` additive named-optional params. Defaults preserve production behavior.

## W2 FYI items — addressed

All 3 W2 FYI notes were non-blocking and remain as documented:
1. Validation 422 stderr verbosity (intentional per C02-C09 contract).
2. Cluster B test name (renamed accurately by W1 R2).
3. Mock matcher rewrite (verified correct).

## Test count progression

| Stage | Count |
|-------|------:|
| C09 baseline | 2330 |
| Expected C10 Δ | +46 |
| Measured | 2376 (= 535 contracts + 1137 web + 704 cli) |

Match: exact.

## FYI (non-blocking)

1. Golden path resolution requires CWD = `apps/cli/` (DX-only, production unaffected).
2. Workspace 183 pre-existing infos predate C10. 0 in apps/cli.
3. `auth status` exit-1 vs `patient list` exit-2 asymmetry by design.

## Outcome

**PASSED — C10 ready to close.**
