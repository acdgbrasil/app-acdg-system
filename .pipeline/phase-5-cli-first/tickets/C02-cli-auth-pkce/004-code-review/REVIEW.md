# C02 — W2 (REVIEW) Round 1

**Verdict:** APPROVED
**Date:** 2026-05-04
**Reviewer:** flutter-code-reviewer (W2)
**Inputs read:** ticket `000-request.md`, W0 `002-tests/REPORT.md`, W1 `003-impl/REPORT.md`, spike `handbook/spikes/OICD_AUTH_SPIKE.md` v1.0, all 9 W1 impl files, all 11 W0 test files, `cli_runner.dart`, `bin/acdg.dart`, `pubspec.yaml`, `cli.dart` barrel.

## Summary

W1 ships a faithful PKCE Loopback implementation that satisfies every non-negotiable from the spike (§3.4–§5.15) and every W0 contract. All 145 tests pass; `dart analyze apps/cli/lib/` is clean; the only analyzer warning is in a W0-owned test file that W1 was forbidden to touch. PKCE crypto, listener defenses (multi-hit, `_rsc=` filter, state CSRF, method/path filters, timeout, no-query-in-logs), `prompt=login`, `client_secret`-never-sent invariants, RefreshTokenInvalid → exit 7 + clear, and 401-refresh-retry are all wired correctly with Result<T> end-to-end. No security regressions, no test cheating.

The advisories below are SHOULD_FIX/NICE_TO_HAVE polish — none of them block approval. They can be batched into the W3 quality pass or deferred to C03.

## MUST_FIX (REJECT triggers)

None.

## SHOULD_FIX (advisory, doesn't block)

### S1. Authorize-error HTML page does not escape `error` / `description` (potential reflected XSS in user's browser)

- **Location:** `apps/cli/lib/src/oidc/loopback_listener.dart:217-228` (`_authorizeErrorPage`)
- **Issue:** `$error` and `$description` are interpolated directly into the HTML response. The Python reference in spike §A.1 escapes these (line 1414); the Dart sketch in spike §5.5 also has `_escape()` (line 735). W1 dropped the helper.
- **Risk profile:** the listener binds `127.0.0.1:<ephemeral>`; an attacker would need to drive the user's browser at the running listener with a malicious `error_description`. Limited because there's no authenticated origin behind 127.0.0.1, but the attacker could exfiltrate the user's clipboard/network to an external domain via injected `<img src="...">`. Low likelihood, non-zero blast radius.
- **Defer to:** this round if W1 chooses, or W3 quality pass. Two-line fix (port the `_escape()` helper from the spike sample).
- **Routing:** flutter-bff-implementer (W1).

### S2. Sealed-family invariant violated: `_RevokeFailure` is a private `Exception`, not a `CliError`

- **Location:** `apps/cli/lib/src/cli_runner.dart:259-264` defines `class _RevokeFailure implements Exception`. It is wrapped in `Failure<void>(_RevokeFailure(...))` at lines 247 and 252.
- **Issue:** `cli_error.dart:6` documents "every CLI failure lives in this hierarchy". The revoke-endpoint HTTP failure is a CLI failure surfaced through `Result<void>`, but it bypasses the sealed family. Use `NetworkError(message)` (transport failure) or `ServerError(statusCode, message)` (HTTP non-200) instead — both already exist.
- **Why it matters:** any future exhaustive switch over the error space will not see `_RevokeFailure`, so the lint `acdg_lints/no_sealed_class_downcast` cannot help. The error is also opaque to anyone calling `result.error.toString()` outside `cli_runner.dart`.
- **Defer to:** this round (one-file change, two call-sites).
- **Routing:** flutter-bff-implementer (W1).

### S3. `_unusedDiscovery` getter is dead code with `// ignore: unused_element`

- **Location:** `apps/cli/lib/src/session/bff_client.dart:203-206`.
- **Issue:** the getter exists solely to keep the `_discovery` field reachable; the `discovery:` constructor param is never used inside `BffClient` today. The W1 REPORT flags this for W2 judgment.
- **Verdict:** delete both the getter AND the field AND the constructor param now. Re-introducing them when C03+ wires `end_session_endpoint` / `revoke` is one commit; carrying the dead surface invites confusion (the W0 test file `bff_client_test.dart:225` *does* pass `discovery:`, so the param signature must remain — but the field can become a true unused-by-design pass-through with a brief docstring, OR W1 can keep the field and drop the dead getter only).
- **Minimal change:** drop the getter (`bff_client.dart:203-206`) and remove `// ignore: unused_element`. Keep the field + constructor param so W0's test still wires the param. This silences the analyzer without dead-code on the public surface.
- **Defer to:** this round (3-line delete).
- **Routing:** flutter-bff-implementer (W1).

### S4. `cli.dart` barrel does not export the new public types W1 declared

- **Location:** `apps/cli/lib/cli.dart` (lines 11-20).
- **Issue:** the W1 REPORT §"Public API delta" claims `cli.PkcePair`, `cli.OidcDiscovery`, `cli.LoopbackListener`, `cli.TokenClient`, `cli.TokenResponse`, `cli.RefreshTokenInvalidError` are public. The barrel only exports `oidc_session.dart`. The other oidc/* files are not re-exported, so `import 'package:cli/cli.dart'` does not see them. Tests work because they import private paths (`package:cli/src/...`).
- **Decision required:** either (a) add `export 'src/oidc/{pkce_pair,oidc_discovery,loopback_listener,token_client}.dart'` to `cli.dart` and `export 'src/errors/cli_error.dart'` already exports `RefreshTokenInvalidError` transitively (verified — sealed family reachable), or (b) update the W1 REPORT to clarify these types remain `package:cli/src/...`-only.
- **Recommendation:** (a) — the spike contemplates these as the OIDC subsystem's public surface; private paths are an anti-pattern for any caller outside the test suite.
- **Defer to:** this round.
- **Routing:** flutter-bff-implementer (W1).

### S5. No `copyWith` on `OidcSession`; rotation is open-coded twice

- **Location:** `apps/cli/lib/src/session/oidc_session.dart` (no copyWith) → forces manual reconstruction at:
  - `apps/cli/lib/src/session/bff_client.dart:167-178` (`_rotate`)
  - `apps/cli/lib/src/commands/auth_refresh_command.dart:65-74`
- **Issue:** the flutter-expert SKILL says immutable value types should expose `copyWith` for refactor-safety. Both call-sites repeat `sub:`, `email:`, `roles:` from the previous session and bump the token triple + expiry. A `copyWith` would localise that pattern.
- **Risk if skipped:** when a future ticket adds an `OidcSession` field (e.g., `idTokenExpiresAt` for §A.4 or `loggedInAt` for audit), both call-sites must be updated by hand and a forgotten field silently drops to its constructor default — exactly the bug `copyWith` exists to prevent.
- **Defer to:** C03 if W1 prefers, or this round (small, mechanical).
- **Routing:** flutter-bff-implementer (W1).

### S6. `_PlaceholderCommand` in `AuthCommand` keeps a no-collaborator path alive only for one test

- **Location:** `apps/cli/lib/src/commands/auth_command.dart:31-36` and `:56-70`.
- **Issue:** when `AuthCommand()` is constructed with all four named params null (only the C02 W0 test `auth_command_test.dart:51-60` does this), the parent registers schema-only stubs. Production wiring at `cli_runner.dart:151-190` always passes real subcommands. The placeholder path exists to keep the W0 contract test passing as written.
- **W1 explicitly asked W2:** "accept or require non-nullable constructor params?". My answer: **accept for now** — forcing non-nullable params is the correct long-term shape, but it requires modifying `auth_command_test.dart` to inject fakes, which is a W0-owned file. Defer the cleanup to a later round (C02-bis or C03) so this round does not touch W0 territory. The placeholder is harmless because:
  1. it cannot be reached from `bin/acdg.dart` (production always wires the four reals);
  2. the test is asserting the shape of `--help` advertisement, not behavior;
  3. no security path runs through it.
- **Defer to:** future ticket. Document in C03 backlog.
- **Routing:** none this round.

### S7. `_Attempt<T>` sealed sum + `flatMapWith` is over-engineered for a one-shot retry

- **Location:** `apps/cli/lib/src/session/bff_client.dart:209-249` (24 lines of sum-type machinery).
- **Issue:** the only consumer is two call-sites in `BffClient.get`; the same logic is expressible in ~10 lines of inline `if (status == 401)` branching with no loss of clarity.
- **W1 explicitly asked W2:** "clean or over-engineered?". My answer: **leans over-engineered** but acceptable as a defensive style choice — the sum type does encode the retry-once invariant by construction (you cannot accidentally call `_refreshAndRetryGet` twice). I would not block the ticket on this. If `BffClient` grows POST/PUT/DELETE in C03+, the sum type starts to pay off.
- **Defer to:** C03 — re-evaluate when more verbs land. If C03 still has only `get`, simplify.
- **Routing:** none this round.

## NICE_TO_HAVE (purely stylistic)

### N1. Inconsistent comments around `bff_client.dart:91-94`

There are two stacked comments explaining the same thing (validateStatus + responseType). Could fold into one paragraph; minor readability.

### N2. `auth_command.dart:49` comment "EX_USAGE — `acdg auth` without a subcommand" — `args` already returns 64; the comment makes it sound load-bearing.

Trivial.

### N3. Discovery `load` returns `NetworkError` for HTTP non-200 even when the cleaner type is `ServerError(statusCode, ...)`

`oidc_discovery.dart:60-66` constructs `ServerError(response.statusCode, ...)` for HTTP non-200 (correct), but lines 73, 78, 86, 104 use `NetworkError` for JSON-malformed / issuer-mismatch / missing-endpoint. These are actually content-validation failures, not transport failures. `InvalidArgError` does not fit either; consider adding a `ProtocolError(message)` variant to `cli_error.dart` in C03 if the distinction proves useful for telemetry. Not load-bearing today.

## Confirmations (what passed)

### Architecture
- Result<T> end-to-end ✅ — every async function in domain/application returns Result; no `throw` in command layer.
- `try/catch` only at adapter boundaries ✅ — W1's audit table at REPORT §"Try/catch audit" cross-checked against grep of `apps/cli/lib/`. Boundaries: HTTP (`http.Client`, `Dio`), Process.run (chmod, browser open, revoke), file I/O (CredentialStore), JWT base64-decode (auth_login_command), JSON parse (`oidc_discovery.dart`, `token_client.dart`, `oidc_session.dart`). One `throw StateError` at `loopback_listener.dart:63` for double-bind — programmer fault guard, acceptable per ADR-019.
- No service locator / singletons ✅ — every collaborator (httpClient, store, listener, tokenClient, browserOpener, stateNonceFactory, revoker, discoveryLoader) is constructor-injected.
- `abstract interface class` for sub-contracts ✅ — `CredentialStore` (correct H5).
- Plain `class` where Fakes need `implements` ✅ — `OidcDiscovery`, `LoopbackListener`, `TokenClient` (per W0 §4.3). Verified that W0 test fakes implement them.
- Imports order ✅ — every file sorts SDK → external → internal → relative. Spot-checked across all 9 new files.
- StringSink injection on Commands ✅ — none of the four auth subcommands writes to `Stdio.stdout` directly inside `run()`.

### Security (CRITICAL)
- PKCE S256 ✅ — `pkce_pair.dart:42-48`: 64 random bytes from `Random.secure()` → b64url no-pad verifier (86 chars) → SHA-256(utf8(verifier)) → b64url no-pad challenge (43 chars). `method = 'S256'` is hard-coded; no `plain` fallback.
- LoopbackListener defenses ALL present ✅:
  - `_rsc=` filter at `loopback_listener.dart:149-154` (drains 204 even when state matches).
  - `state == expected` at `loopback_listener.dart:182` (silent 204 on mismatch — multi-hit preserved).
  - 204 silent drain at `loopback_listener.dart:184` (no terminal completion).
  - Ephemeral port at `loopback_listener.dart:66` (`InternetAddress.loopbackIPv4` + port 0).
  - 5-min default at `loopback_listener.dart:42` (`OidcConfig.loopbackTimeout`).
  - Logger discipline at `loopback_listener.dart:200-205` (only reason text; tests verify no `code=` ever appears in log lines).
- `prompt=login` always set ✅ — `auth_login_command.dart:174` via `OidcConfig.authorizePrompt = 'login'`.
- `code_challenge_method=S256` ✅ — `auth_login_command.dart:173` via `PkcePair.method`.
- Token endpoint POST form-urlencoded ✅ — `token_client.dart:97`. `client_id` always present (default `OidcConfig.clientId`); `code_verifier` on exchange; `client_secret` NEVER set (verified by `token_client_test.dart:171,309`).
- RefreshTokenInvalid → no retry, clear, exit 7 ✅ — `auth_refresh_command.dart:81-86`; `bff_client.dart:140-143` clears + returns AuthRequiredError.
- No full-token logging ✅ — grep confirmed: no `print/writeln/log` of `accessToken`, `refreshToken`, `idToken`, `code`, `verifier`, `state`, `nonce` raw. Identity claims (`email`, role names) are intentionally surfaced for `auth status`/`auth login` UX, which matches spike §5.15 ("can log: sub, email (obfuscate)" — note: not obfuscated, but that's a UX call, not a leak).
- No JWT signature validation in CLI ✅ — `auth_login_command.dart:203-231` only base64-decodes for `sub`/`email`/`roles`; explicit comment "no signature validation — that's the BFF's job".
- chmod 600 ✅ — inherited intact from C01 at `credential_store.dart:84-91`. (The `writeAsString` → `chmod` race window is C01-inherited; not a C02 regression.)
- Bearer header injection only when session present ✅ — `bff_client.dart:46-51` reads store on every outbound; `null` session → no header. Verified by `bff_client_test.dart:103-134`.

### Code quality
- Naming ✅ — `*Command`, `*Client`, `*Listener`, `*Session`, `*Pair`, `*Discovery`, `*Error` all match. snake_case files, PascalCase classes.
- Imutabilidade ✅ — `final class` where allowed; all fields `final`; `with Equatable` on `PkcePair`, `OidcDiscovery`, `OidcSession`, `TokenResponse`. `LoopbackListener` is mutable by necessity (`_server`, `_bound`).
- Doc-strings on public surface ✅ — every new file has a top-level `library;` docstring + per-class docstrings. Spot-checked.
- No "WHAT" comments ✅ — comments explain "why" (e.g., the `responseType: bytes` comment at `bff_client.dart:91-94` explains a non-obvious workaround; no tautological "increment counter" comments anywhere).
- No orphan TODO/FIXME ✅ — grep returned zero hits in `apps/cli/lib/`.
- No unnecessary backwards-compat shim ✅ — Strategy A clean break confirmed; `Credentials` references survive only in docstrings.

### Tests
- W1 did not modify W0 tests ✅ — only the 3 explicitly-delegated (`credential_store_test.dart`, `bff_client_test.dart` C01 fixtures, `cli_error_test.dart` exhaustive switch). Verified by reading each file.
- Tests assert intent, not impl ✅ — listener tests drive a real `HttpServer` (smart choice — the contract IS HTTP); token client tests assert form-body invariants (grant_type, client_id, NOT client_secret) not byte-for-byte equality; status/refresh/logout assert exit codes + side effects on store, not internal state.
- Fakes, not magic mocks ✅ — `_FakeStore`, `_FakeListener`, `_FakeTokenClient`, `_SequencedAdapter`, `_CapturingAdapter`, `_ThrowingAdapter`. All hand-rolled, all implement the public interface.
- Test discoverability ✅ — every file name matches the unit under test.

### Decisions verdict (response to W1's 8 design decisions)

1. **Strategy A clean break (`Credentials` → `OidcSession`)** — **ACCEPT**. Surface bloat avoided; pre-C02 file shape gracefully returns null at `credential_store.dart:70`. The "deprecated alias" alternative (Strategy B) would have been worse: extra type, extra docs, eventual deletion anyway.

2. **`bytes responseType` + manual JSON decode in BffClient** — **ACCEPT**. The W0 test `_SequencedAdapter` returns a non-JSON body (`'unauthorized'`) with `content-type: application/json`. Dio's default `responseType: json` would JSON-decode eagerly and surface the failure as `DioException(type: unknown, response: null)` — the 401 detector never sees status. Three alternatives exist: (i) modify W0 to send a valid JSON 401 body (forbidden — W2 cannot ask test-writer to soften the contract), (ii) custom Dio Transformer (heavier than the bytes fix), (iii) bytes + manual decode (what W1 chose). (iii) is the smallest delta. Comment at `bff_client.dart:86-94` explains the reasoning.

3. **`_Attempt<T>` sum type internal to BffClient** — **ACCEPT WITH CAVEAT (S7)**. Encodes the retry-once invariant by construction; valuable when more verbs land but currently 24 lines of machinery for one call site. Re-evaluate in C03.

4. **`_PlaceholderCommand` for collaborator-less `AuthCommand()`** — **ACCEPT (S6)**. Keeps the W0 contract test passing without modifying it; production wiring always supplies real collaborators. Long-term, prefer non-nullable params + a fake-injecting test, but that requires touching a W0-owned file.

5. **Exit codes 1-7 (with extras 3/4/5/6)** — **ACCEPT**. The spike pins 0/1/2 (status), 0/1/7/n (refresh). W1's extras (login: 1=discovery, 2=callback, 3=token-exchange, 4=malformed-id-token; refresh: 5=discovery-failure, 6=generic) provide useful telemetry granularity for shell scripts (`if [ $? -eq 4 ]; then ...`). They do not contradict the spike — the spike says 0/1/7 are guaranteed; everything else is `non-zero (other)`.

6. **Browser opener via `Process.run` without test coverage** — **ACCEPT**. RFC 8252 §7.3 + the spike §5.7 both treat the browser launcher as a best-effort adapter. The CLI prints the authorize URL to stdout BEFORE calling `_openBrowser`, so even if the helper fails (no DISPLAY, SSH session, etc.), the user has the recovery path. Wrapping it in a testable abstraction would only test "did we call the wrapper" — not whether the OS actually opened a browser. Manual smoke test against Zitadel staging is the right gate (deferred to C03/QA).

7. **`_unusedDiscovery` getter** — **REJECT, see S3**. Drop the getter now (3-line change). Keep the field + ctor param so the W0 test compiles. Re-wire the field when C03 brings end_session/revoke.

8. **Logger discipline** — **ACCEPT**. `loopback_listener_test.dart:255-281` exhaustively asserts no logged line contains raw `code=`, `?code=`, or any of the planted secret strings. Implementation at `loopback_listener.dart:200-205` only forwards reason strings. Spike §5.15 satisfied.

## Spike adherence

- §3.4 access_token claims (`aud.contains(PROJECT_ID)`, NOT `azp`/`email`) ✅ — the CLI does no JWT validation (correctly delegated to BFF). The id_token decoder reads `email` from the id_token only (not access_token), matching §3.6.
- §3.5 roles claim shape (object with keys = role names) ✅ — `auth_login_command.dart:222-228` reads `OidcConfig.rolesClaim` (with project-specific fallback), takes `keys`, sorts. Falls back to empty list if claim absent or wrong shape.
- §5.4 PKCE generation ✅ — see "Security" confirmations above.
- §5.5 LoopbackListener defenses ✅ — see "Security" confirmations above.
- §5.6 Authorize URL with `prompt=login` ✅ — `auth_login_command.dart:163-176`.
- §5.7 Browser opener with macOS/Linux/Windows fallbacks ✅ — `cli_runner.dart:198-213`. The "fallback: print URL" is satisfied by the unconditional print at `auth_login_command.dart:94-97` BEFORE the browser-opener call.
- §5.8 Token client (form-urlencoded, no client_secret) ✅ — see "Security" confirmations above.
- §5.9 RefreshTokenInvalid → no retry, clear, exit 7 ✅ — `token_client.dart:165-169` matches `error == 'invalid_grant' && description.contains('RefreshTokenInvalid')`; consumer at `auth_refresh_command.dart:81-86` clears + exits 7.
- §5.13 proactive refresh window ✅ — `oidc_session.dart:103-107` returns true when `now >= accessExpiresAt - 60s`.
- §5.14 logout best-effort revoke ✅ — `auth_logout_command.dart:51-83` always clears local even on revoke/discovery failure; exit 0 always.
- §5.15 logging discipline ✅ — listener log channel never receives query strings; no token logging anywhere.

## Routing

APPROVED. No re-implementation needed. The 4 SHOULD_FIX advisories (S1, S2, S3, S4) are small surgical fixes that should land in a follow-up commit — they belong to **flutter-bff-implementer (W1)** but can be batched into the W3 quality pass (`flutter-quality-checker`) if W1 prefers, since none change behavior.

S5 (`copyWith`), S6 (`_PlaceholderCommand`), S7 (`_Attempt<T>`) are deferred to C03.

NICE_TO_HAVE items N1/N2/N3 can be picked up opportunistically or skipped.

## Round 1 outcome

W1 may proceed to W3 (`flutter-quality-checker`) immediately. The quality pass should:
1. Apply S1-S4 if simple enough to bundle.
2. Run `dart analyze --fatal-infos` and confirm the only outstanding warning is the W0 test-file `unused_element_parameter` (test-writer territory; deferred to a separate commit if anyone cares — recommended: drop the unused fake parameter via test-writer in a one-line follow-up before close, but not blocking).
3. Run `dart format` and `dart test` final sweep.

No further review rounds anticipated unless the quality pass surfaces something new.
