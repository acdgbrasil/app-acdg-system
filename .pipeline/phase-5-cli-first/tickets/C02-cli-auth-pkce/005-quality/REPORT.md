# C02 — W3 (QUALITY) Final Gate

**Verdict:** PASSED
**Date:** 2026-05-04
**Agent:** flutter-quality-checker

## Summary

C02 closes clean. `dart analyze` on `apps/cli/` reports zero issues; all 145 CLI tests pass; AOT compile produces a runnable binary; `apps/cli/` introduces no analyzer regressions in sibling packages. The four W2 SHOULD_FIX items (S1-S4) plus the `unused_element_parameter` follow-up on `_FakeTokenClient.refreshResult` are all verified applied. Conventions (naming, snake_case files, import order, StringSink injection, no client_secret, no raw token logging, no orphan TODOs) hold across the C02 surface. One incidental format fix landed in `bff_client.dart` during this gate (doc-comment reflow only — no behavior change). Ready to close ticket.

## Quality battery results

| Check | Result | Details |
|-------|:-----:|---------|
| `dart analyze` (apps/cli/) | PASS | `No issues found!` |
| `dart format --set-exit-if-changed` (apps/cli/lib/, apps/cli/test/) | PASS (after 1 file reformatted) | `bff_client.dart` doc-comment reflow only; re-run is clean (`Formatted 58 files (0 changed)`) |
| `dart test` (apps/cli/) | PASS | 145 GREEN / 0 FAIL / 0 skip — exact match with W1 projection |
| AOT compile (`bin/acdg.dart` → `/tmp/acdg-c02-w3`) | PASS | Binary built; `--help` lists 9 commands; `auth --help` lists `login`, `logout`, `refresh`, `status` |
| Workspace `dart analyze` (root) | PASS — no C02 regression | 183 issues total, **0 in apps/cli/**. All issues are pre-existing info-level lints in `apps/social_care_bff/{contracts,desktop,web}` and `kernel/lints`. Severity breakdown: 0 errors, 0 warnings, all info. |
| Workspace `dart test` totals | PARTIAL (env-bound) | apps/cli: 145, apps/social_care_bff/web: 1137, apps/social_care_bff/contracts: 535 = **1817 GREEN**. apps/social_care_bff/desktop blocked by pre-existing `swiftly` / `-isysroot` build-hook environment failure (Drift `native_assets` toolchain conflict on this host) — unrelated to C02. |

### Workspace test delta vs. C01 baseline

C01 STATE.md baseline cited "2249 GREEN +1 skip" for the workspace. The desktop package contributes the bulk of remaining tests but cannot be exercised on this host today due to the pre-existing build-hook conflict. The reachable subset (cli + web + contracts) returns 1817 GREEN. The C02 delta in apps/cli (+68 tests, 77 → 145) is fully accounted for and matches W0/W1 projections. No tests were lost or skipped by C02.

## Convention checks

| Rule | Result | Evidence |
|------|:-----:|----------|
| Naming suffixes (`*Command`, `*Client`, `*Listener`, `*Pair`, `*Discovery`, `*Session`, `*Error`) | PASS | `AuthLoginCommand`, `AuthStatusCommand`, `AuthLogoutCommand`, `AuthRefreshCommand`, `BffClient`, `TokenClient`, `LoopbackListener`, `PkcePair`, `OidcDiscovery`, `OidcSession`, `RefreshTokenInvalidError`, `TokenResponse`, `FileCredentialStore`, `CredentialStore` |
| snake_case file names | PASS | `pkce_pair.dart`, `oidc_discovery.dart`, `loopback_listener.dart`, `token_client.dart`, `oidc_session.dart`, `auth_login_command.dart`, `auth_status_command.dart`, `auth_logout_command.dart`, `auth_refresh_command.dart` |
| Import order (SDK → external → internal → relative) | PASS | All 9 new files + `auth_command.dart`, `bff_client.dart`, `cli_runner.dart`, `cli.dart` sorted; blank lines separate blocks correctly |
| No `print()` in `apps/cli/lib/src/` | PASS for C02 | One pre-existing `print` in `_stub_command.dart:28` gated by `out != null` and tagged `// ignore: avoid_print` (C01 scaffolding fallback). No new `print` in any C02 file. |
| No direct `Stdio.stdout` writes inside Command `run()` | PASS | All four auth subcommands write only to injected `StringSink? stdout` / `StringSink? stderr` |
| No backwards-compat shim — `Credentials` class fully gone (Strategy A) | PASS | `grep -rn 'class Credentials\b' apps/cli/` returns **0 hits** |
| No orphan TODO/FIXME/XXX | PASS | `grep -rn 'TODO\|FIXME\|XXX' apps/cli/lib/` returns **0 hits** |
| No `client_secret` use (PKCE-only) | PASS | 3 hits in `apps/cli/lib/`, all in docstrings explicitly stating `client_secret` MUST NEVER appear; W0 token_client tests assert form bodies do not contain `client_secret` |
| No raw token logging | PASS | grep over `(print\|writeln\|write)\(.*\b(accessToken\|refreshToken\|idToken\|code_verifier\|verifier\|nonce)\b` against `apps/cli/lib/src/` returns **0 hits** |
| `try/catch` only at adapter boundaries | PASS | 18 `try {` occurrences, each at an adapter edge (HTTP, Process.run, file I/O, JSON parse, base64 decode, DateTime.parse, UsageException) — exact match with W1 audit table |

## Security spot-checks

| Invariant | Result |
|-----------|:-----:|
| PKCE S256 only (no `plain` fallback) | PASS — `pkce_pair.dart` hardcodes `method = 'S256'`, SHA-256 challenge from `Random.secure()` 64-byte verifier |
| `client_secret` never sent to token endpoint | PASS |
| `prompt=login` always present in authorize URL | PASS — `auth_login_command.dart:174` |
| Loopback listener defenses (`_rsc=` filter, state CSRF, multi-hit, ephemeral port, 5-min timeout, no query strings in logs) | PASS — `_escapeHtml` now also applied to authorize-error page (S1) |
| RefreshTokenInvalid → no retry, clear local, exit 7 | PASS — `auth_refresh_command.dart:81-86`; `bff_client.dart:140-143` |
| No JWT signature validation in CLI (delegated to BFF) | PASS — `auth_login_command.dart:208` only base64-decodes for `sub`/`email`/`roles` |
| chmod 600 on credentials file | PASS (C01-inherited) |
| Bearer header injection only when session present | PASS — `bff_client.dart:46-51` |

## SHOULD_FIX from W2 — verification

| ID | Item | File:line evidence | Status |
|----|------|---------------------|:-----:|
| S1 | XSS escape on authorize-error HTML page | `apps/cli/lib/src/oidc/loopback_listener.dart:217-237` — `_authorizeErrorPage` calls `_escapeHtml(error)`/`_escapeHtml(description)`; helper at `:237` | APPLIED |
| S2 | Drop `_RevokeFailure`; use `ServerError`/`NetworkError` | `apps/cli/lib/src/cli_runner.dart:36` adds `import 'errors/cli_error.dart';`; `_revokeRefreshToken` constructs `ServerError(status, ...)` / `NetworkError(...)`; `grep _RevokeFailure apps/cli/` → **0 hits** | APPLIED |
| S3 | Drop dead `_unusedDiscovery` getter | `apps/cli/lib/src/session/bff_client.dart:64-65` retains `final OidcDiscovery? _discovery;` field with `// ignore: unused_field` for ctor compat with W0 fakes; getter gone | APPLIED |
| S4 | Re-export new OIDC types from `cli.dart` barrel | `apps/cli/lib/cli.dart:20-26` exports `loopback_listener.dart`, `oidc_discovery.dart`, `pkce_pair.dart`, `token_client.dart`, `bff_client.dart`, `credential_store.dart`, `oidc_session.dart` | APPLIED |
| Follow-up | Drop `_FakeTokenClient.refreshResult` unused parameter | `apps/cli/test/commands/auth_login_command_test.dart` — `grep refreshResult` returns **0 hits** | APPLIED |

## Issues found this round

None. The only mutation introduced by this gate was `dart format` on `apps/cli/lib/src/session/bff_client.dart` (doc-comment reflow only — diff is all whitespace and line-wrap; no semantic changes). After the format pass, `--set-exit-if-changed` returns clean and `dart test` still reports 145 GREEN.

### Pre-existing artifacts noted (not C02 regressions)

1. **Workspace info-only lints (170 hits)** in `apps/social_care_bff/{contracts,desktop,web}` and `kernel/lints/lib/src/no_sealed_class_downcast.dart`. None in `apps/cli/`. None are errors or warnings.
2. **Desktop package test run blocked** by `swiftly`/`-isysroot` toolchain conflict in native build hooks (Drift `native_assets`). C02 does not touch `apps/social_care_bff/desktop/`. Host-environment issue, not a code regression.
3. **`_stub_command.dart` `print` fallback** at `:28`, gated by `out == null` and tagged `// ignore: avoid_print`. C01-approved scaffolding; not new in C02.

## Outcome

**PASSED** — C02 quality gate clears. Ticket ready to close (STATE.md transition + commit). No re-routing needed; no further review rounds required.

### Final test count
- `apps/cli/`: **145 GREEN / 0 FAIL / 0 skip** (DoD target ≥ 110 met; W0 floor 77 + 30 met).
- Workspace reachable subset (cli + bff/web + bff/contracts): **1817 GREEN / 0 FAIL / 0 skip**. Desktop unreachable on this host due to pre-existing native build-hook conflict (not a C02 issue).
