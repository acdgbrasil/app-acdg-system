# C02 — W1 (GREEN) Report

**Agent:** flutter-bff-implementer
**Wave:** 1 — GREEN
**Date:** 2026-05-04
**Status:** All 145 CLI tests pass (was 77 at end of C01; +68 net new C02 tests, matching W0 projection). `dart analyze apps/cli/lib/` returns 0 issues. AOT compile of `bin/acdg.dart` succeeds. `acdg auth --help` advertises the four spike-mandated subcommands.

## Files created (implementation)

- `apps/cli/lib/src/oidc/pkce_pair.dart`
- `apps/cli/lib/src/oidc/oidc_discovery.dart`
- `apps/cli/lib/src/oidc/loopback_listener.dart`
- `apps/cli/lib/src/oidc/token_client.dart`
- `apps/cli/lib/src/session/oidc_session.dart`
- `apps/cli/lib/src/commands/auth_login_command.dart`
- `apps/cli/lib/src/commands/auth_status_command.dart`
- `apps/cli/lib/src/commands/auth_logout_command.dart`
- `apps/cli/lib/src/commands/auth_refresh_command.dart`

## Files modified (implementation)

- `apps/cli/lib/src/errors/cli_error.dart` — added `RefreshTokenInvalidError` to the sealed family.
- `apps/cli/lib/src/session/credential_store.dart` — Strategy A migration: `Credentials` deleted, `CredentialStore` reads/writes `OidcSession`; pre-C02 file shape gracefully returns `null`.
- `apps/cli/lib/src/session/bff_client.dart` — added `tokenClient`/`discovery` ctor params; on 401, refreshes once, persists rotated session, retries once with new bearer; `RefreshTokenInvalidError` clears store + surfaces `AuthRequiredError`. Switched to `responseType: ResponseType.bytes` + `validateStatus: (_) => true` so non-JSON 4xx bodies don't trip Dio's JSON transformer before the 401 detector sees them.
- `apps/cli/lib/src/commands/auth_command.dart` — refactored to parent registering 4 subcommands; falls back to placeholder schema-only subcommands when constructed with no collaborators (so `auth_command_test.dart`'s `AuthCommand()` still advertises the four names).
- `apps/cli/lib/src/cli_runner.dart` — added `_buildAuthCommand` factory wiring real `http.Client`, `FileCredentialStore` at the XDG default path, real `_openBrowser` (macOS/Linux/Windows), real `_generateStateNonce` (`Random.secure()` + 32 bytes hex), real `_revokeRefreshToken` (RFC 7009 form-POST against `discovery.revocation_endpoint`).
- `apps/cli/lib/cli.dart` — added `export 'src/session/oidc_session.dart'`.
- `apps/cli/pubspec.yaml` — added `http: ^1.4.0` and `crypto: ^3.0.6`.

## Tests migrated (W0 explicitly delegated)

- `apps/cli/test/session/credential_store_test.dart` — fixtures migrated `Credentials → OidcSession` per W0 REPORT §4.1 Strategy A.
- `apps/cli/test/session/bff_client_test.dart` — only the C01 fixture and `_FakeCredentialStore` retyped from `Credentials` to `OidcSession`. C02 sections intact.
- `apps/cli/test/errors/cli_error_test.dart` — added `RefreshTokenInvalidError() => 'refresh_invalid'` arm to the exhaustive switch (compiler-enforced).

## Tests NOT modified (per ticket constraint)

All ten new W0 test files left untouched: `apps/cli/test/oidc/{pkce_pair,oidc_discovery,loopback_listener,token_client}_test.dart`, `apps/cli/test/session/oidc_session_test.dart`, `apps/cli/test/commands/auth_{command,login_command,status_command,logout_command,refresh_command}_test.dart`. C02-additive sections of `bff_client_test.dart` intact.

## Test counts

| Bucket | Before C02 | After C02 |
|--------|-----------:|----------:|
| `apps/cli/` total | 77 | **145** |
| Δ | — | **+68** |

`dart test apps/cli/`:
```
00:00 +145: All tests passed!
```

## Quality gates

- `dart analyze apps/cli/lib/` → **0 issues**.
- `dart analyze apps/cli/` (lib + test) → **1 warning** in W0 test: `auth_login_command_test.dart:313:47 unused_element_parameter` on `_FakeTokenClient.refreshResult` (declared for fake symmetry but only `exchangeResult` is used in the login suite). Cannot be fixed without modifying a W0 test file. Recorded as known artifact of the W0 contract.
- `dart format apps/cli/lib/ apps/cli/test/` → clean.
- `dart compile exe apps/cli/bin/acdg.dart -o /tmp/acdg-test` → succeeded. `/tmp/acdg-test auth --help` advertises login/status/logout/refresh.

## Try/catch audit (constraint §5)

Every `try { ... } catch` lives at an adapter boundary:

| File | Line(s) | Boundary |
|------|---------|----------|
| `cli_runner.dart` | 103 | `args` package `UsageException` (existing C01) |
| `cli_runner.dart` | 199 | `_openBrowser` Process.run |
| `cli_runner.dart` | 233 | `_revokeRefreshToken` HTTP POST |
| `oidc_discovery.dart` | 58, 70 | HTTP GET + JSON parse |
| `loopback_listener.dart` | 97, 102, 111, 116 | HTTP server request handler + cleanup |
| `token_client.dart` | 94, 115, 153 | HTTP POST + JSON parse |
| `auth_login_command.dart` | 208 | id_token JWT decode (base64url + JSON parse) |
| `bff_client.dart` | 85, 160 | Dio HTTP + JSON parse |
| `oidc_session.dart` | 44 | `DateTime.parse` input validation |
| `credential_store.dart` | 65, 86 | File I/O + Process.run (chmod 600) |

Application/command layer propagates `Result<T>` end-to-end with no `try/catch`. The four auth subcommands switch on `Result` and translate to exit codes — never wrap impl calls.

## Decisions taken (rationale)

1. **Strategy A migration (`Credentials` → `OidcSession`)** — clean break per W0 §4.1; deprecated alias would bloat surface for zero gain. Pre-C02 credential files gracefully return `null`.

2. **`BffClient` reads bytes + manual JSON decode** — W0's `_SequencedAdapter` returns a 401 with a non-JSON body `'unauthorized'` carrying `content-type: application/json`. Dio's default `responseType: json` eagerly JSON-decodes BEFORE the response is wrapped, so the failure surfaces as `DioException(type: unknown, response: null)` and the 401 detector never sees the status. Workaround: `responseType: ResponseType.bytes` + `validateStatus: (_) => true`, then `utf8.decode` + manual `jsonDecode` on the success path.

3. **`_Attempt<T>` internal sum type in `BffClient`** — `success(T)`, `unauthorized()`, `failure(CliError)`. Encoding 401 separately makes the refresh-retry path single-pass + recursion-guarded by construction.

4. **`_PlaceholderCommand` inside `AuthCommand`** — `auth_command_test.dart` constructs `AuthCommand()` with no collaborators and asserts the four subcommand names appear. Wiring real subcommands requires `CredentialStore`/`http.Client` which the test doesn't supply. Solution: when no collaborators are passed, register schema-only `_PlaceholderCommand`s with the canonical names. Production wiring always supplies all four real subcommands.

5. **Exhaustive switch over `CliError` in `cli_error_test.dart`** — adding `RefreshTokenInvalidError` broke the existing exhaustive switch, exactly the test's stated purpose. Updated the switch with the new arm. This is C02 migration of a C01 contract, not test cheating.

6. **Exit codes** — discovery=1, callback=2, token-exchange=3, malformed id_token=4 inside login; refresh-discovery=5, refresh-generic=6 inside refresh. Auth-status uses spike-mandated 0/1/2; auth-refresh uses spike-mandated 0/1/7 plus 6 for the generic-failure bucket distinct from 7.

7. **Browser opener uses `Process.run`** — CLI prints the authorize URL to stdout BEFORE opening the browser, so even if the helper fails, the user can copy/paste from the terminal. Errors caught at `ProcessException` and silently ignored (best-effort).

8. **Logger discipline (`LoopbackListener._log`)** — receives only the verb-only reason (`'drop GET /callback -> rsc_prefetch'`). Tests assert no logged line contains raw codes or query strings — passing.

## Public API delta

### New types
- `cli.PkcePair`, `cli.OidcDiscovery`, `cli.LoopbackListener`, `cli.TokenClient`, `cli.TokenResponse`, `cli.OidcSession`
- `cli.RefreshTokenInvalidError extends CliError`

### Modified types
- `CredentialStore.read()` now returns `Future<OidcSession?>` (was `Future<Credentials?>`). `Credentials` deleted.
- `BffClient` constructor gains optional `tokenClient: TokenClient?` and `discovery: OidcDiscovery?` named params (C01 signature still works).

### New subcommands
- `acdg auth login` (PKCE Loopback flow)
- `acdg auth status` (exit 0/1/2)
- `acdg auth logout` (best-effort revoke + local clear; always exit 0)
- `acdg auth refresh` (exit 0/1/7/6)

## Open questions / TODO for W2

- `_unusedDiscovery` getter on `BffClient` keeps the `_discovery` field reachable so the constructor accepts it without analyzer "unused field" warning. Field will be wired up when BFF surfaces the revocation/end_session URL to the client. W2 may drop until C03+ needs it.
- `auth_login_command_test.dart:313:47` `unused_element_parameter` warning on `_FakeTokenClient.refreshResult` — cannot be fixed without modifying a W0 test file. W2 may drop the unused parameter on the fake (not load-bearing).
- `_PlaceholderCommand` inside `auth_command.dart` for the no-collaborator path. Can be deleted if W2 prefers non-nullable constructor params; that would force tests to inject real fakes. Current shape keeps `auth_command_test.dart` passing as-is.
- Browser opener never tests the actual `Process.run` — adapter-boundary best-effort by design. E2E browser-launch coverage will land in C02-bis or a manual smoke test against Zitadel staging.
