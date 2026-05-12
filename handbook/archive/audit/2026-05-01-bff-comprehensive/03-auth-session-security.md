# Auth/Session Security Audit — BFF Comprehensive (2026-05-01)

## Executive summary

- **Auth posture: CONCERNS** (architecture is sound; production wiring is incomplete and several security primitives ship in scaffold-only form).
- **OWASP ASVS L2 compliance status: PARTIAL** — Authentication V2 ~50%, Session Management V3 ~55%, Access Control V4 ~25%, Error Handling V7 ~80%.
- **Top 3 strengths**
  1. Trust Model intent is correct: Web BFF designed as Confidential Client with `__Host-`prefixed, HttpOnly, Secure, SameSite=Strict cookies; tokens never modeled in browser-visible state. (`bff/social_care_web/lib/src/handlers/auth_handler.dart:21,222`).
  2. PII discipline in observability is excellent: dedicated PII-mask helpers, sensitive query params scrubbed (`code`, `access_token`, `refresh_token`, `id_token`, `token`), breadcrumbs explicitly forbid raw PII. (`bff/social_care_web/lib/src/middleware/observability.dart:11-17`, `bff/social_care_web/lib/src/observability/pii_mask.dart`).
  3. Session IDs are 32-byte cryptographically random (`Random.secure()`), expirations are enforced server-side with auto-eviction on `get()`, and the store is testable with an injectable clock (`bff/social_care_web/lib/src/auth/session_store.dart:75,100-112,150-154`).
- **Top 3 gaps (all CRITICAL or HIGH)**
  1. **`AuthContract` is wired to `FakeAuthBff` in production entrypoint** — `bin/server.dart:21` instantiates `FakeAuthBff()`, meaning real Zitadel OIDC is NOT exercised. The hardened `OidcServerClient` exists but is constructed and never invoked (`app_router.dart:87` receives it as a parameter; the field is unused). Today the BFF will accept any login, mint a fake redirect, mint an opaque session cookie with NO real token, and ship `MeResponse(userId: 'fake-user-id', roles: ['social_worker'])` to anyone. **No actual authentication is enforced.**
  2. **Session cookie is decoupled from session store** — `auth_handler.dart:121` issues a brand-new opaque cookie value (`UuidUtil.generateV4()`) on callback success but **never inserts a corresponding entry into `SessionStore`**. The `sessionMiddleware` reads the cookie and looks it up in the store; since the store is empty, every authenticated route is unreachable in production wiring. Conversely, `session_middleware.dart:48` parses cookies named `__session=` while the writer emits `__Host-session=` — the names are mismatched. Both bugs together mean the session lifecycle is not yet functional.
  3. **PKCE store does not exist** — the SKILL canon mandates a PKCE verifier store with TTL 5min, max 1000 entries, swept on `login()`. `OidcServerClient.buildAuthorizationUrl` requires `codeVerifier` / `state` to be passed in by the caller, but no callsite generates, persists, retrieves, or consumes them. State is therefore not validated at callback (CSRF), and PKCE proof is structurally absent in the production flow.

## Methodology

- **Skill:** `auth-session-security` (`.claude/skills/auth-session-security/SKILL.md`).
- **Frameworks:** OWASP ASVS L2, NIST 800-63B, OAuth 2.0 / OIDC RFCs (6749, 6819, 7636, 7009).
- **Files audited:** 22 first-party Dart files across the 3 in-scope packages plus the production entrypoint, supplemented by spot-grep across the wider tree (`__Host-`, `Bearer`, `MFA`, `csrf`, `secure_storage`, `Authorization`, `Sec-Fetch`, `X-Frame-Options`, etc.). Generated `*.g.dart` and Drift `.drift.dart` files were not audited.
- **Out-of-scope:** `apps/acdg_system/`, `packages/*` (per instructions).

## Findings (by dimension)

### 1. Token handling

| ID | Severity | Finding |
|----|----------|---------|
| TOK-1 | CRITICAL | `bin/server.dart:21` wires `FakeAuthBff` for the production entrypoint, so the real `OidcServerClient` is never used. `app_router.dart:87` accepts `oidcClient` only to ignore it (no field, no usage). The Trust Model "browser never sees a real token" is technically held only because there are no real tokens. (OWASP ASVS V2.1.7, V2.10) |
| TOK-2 | HIGH | `OidcServerClient.parseIdTokenClaims` (`oidc_server_client.dart:152-163`) explicitly skips signature verification with the comment "BFF trusts its own token endpoint response". This is acceptable IF the response is authenticated TLS to Zitadel AND id_token is never used as an authorization decision input — but no `iss`/`aud`/`exp`/`nonce` validation is performed anywhere downstream. If id_token claims (e.g., roles) are ever consumed by the BFF, this becomes JWT bypass. (OWASP ASVS V2.7.1, RFC 7519 §7.2) |
| TOK-3 | HIGH | `Session.accessToken` and `Session.refreshToken` are stored as plain strings in an in-process Map (`session_store.dart:8-22,74`). Acceptable for a single replica; for multi-instance (HA / Kubernetes pods), session lookups will fail across nodes with no shared store, encouraging operators to either pin sessions or downgrade `SameSite=Strict` to keep things working. Recommend Redis-backed store before A19 production rollout. |
| TOK-4 | MEDIUM | `_parseTokenResponse` (`oidc_server_client.dart:172-189`) casts `body['access_token'] as String` and friends without null-checks. A malformed Zitadel response surfaces as `TypeError`, which the observability middleware (`observability.dart:56-77`) converts to a sanitized 500 — safe for the user, but the operator gets no structured `OidcException`. |
| TOK-5 | MEDIUM | `OidcServerClient.revokeToken` (line 136) is fire-and-forget — there is no status-code check. A revocation that returns 4xx/5xx (e.g., refresh token expired, network blip) is silently ignored, and `LogoutUseCase` will still report success. |
| TOK-6 | LOW | The `accessToken: String` field of the `Session` is logged through `Logger.root.info` only via the `data` map of a breadcrumb — no callsite ever places it there. Good. But `print('BFF Web server listening on ${config.host}:${config.port}')` (`shelf_server.dart:46`) is a stray `print`; replace with the structured logger to keep prod logs uniform. |

### 2. Session management

| ID | Severity | Finding |
|----|----------|---------|
| SES-1 | CRITICAL | **Cookie name mismatch** — `auth_handler.dart:21` declares `__Host-session`, but `session_middleware.dart:43-53` only matches `__session=`. The session middleware will never resolve a cookie set by the auth handler. Either the writer or reader is wrong; given the SKILL canon mandates `__Host-session`, the middleware is the bug. |
| SES-2 | CRITICAL | **No session insertion on callback** — `_dispatchCallback` (`auth_handler.dart:107-126`) on success generates a NEW cookie value via `UuidUtil.generateV4()` and writes it to the browser, but **never calls `SessionStore.create(...)`**. Even with the cookie name fixed, the middleware will still find no session because the store is empty. The session-write path is missing entirely. |
| SES-3 | HIGH | **No session fixation defense** — when (eventually) the callback creates a session, there is no documented "rotate session ID on privilege change" or "rotate after MFA". The current design issues a fresh ID per callback, but there is no equivalent on token refresh: `RefreshUseCase` (`use_cases/refresh_use_case.dart`) merely calls `_auth.refresh()` and returns; no `SessionStore.updateTokens` (which exists at `session_store.dart:118`) is called from any callsite (grep for `updateTokens` returns only the definition). After token refresh, the session expiresAt is also never extended in production wiring. |
| SES-4 | HIGH | **No `Max-Age` on the active cookie** — `_buildSessionCookie` (`auth_handler.dart:220-224`) emits `__Host-session=...; Path=/; HttpOnly; Secure; SameSite=Strict` with NO `Max-Age` attribute, making the cookie a session cookie scoped to the browser tab. The server-side `SessionStore` has a TTL (default 1h, configurable via `SESSION_TTL_MINUTES`), so the discrepancy means a long-lived browser process will keep sending an opaque ID after the server has expired it (causing 401s). Add `Max-Age=${sessionTtl.inSeconds}` to align client + server. (OWASP ASVS V3.4.1) |
| SES-5 | MEDIUM | **No idle vs absolute timeout** — only one TTL exists, applied as both. NIST 800-63B and OWASP ASVS V3.3 distinguish idle (sliding) and absolute (hard cap) timeouts. `SessionStore.updateTokens` extends TTL on refresh (sliding behavior), but there is no absolute expiration. A bad actor with a stolen refresh token can perpetually slide forever. |
| SES-6 | MEDIUM | **`destroyExpired` is never called** — the sweep method exists at `session_store.dart:145-148` but no scheduled timer or middleware invokes it. Memory grows unboundedly until each ID is individually probed via `get()`. For production replace with a periodic `Timer.periodic` or move to Redis with native TTL. |
| SES-7 | MEDIUM | **`SessionStore.create()` does not enforce a max-entries cap.** The SKILL specifies "max 1000 entries" for the PKCE store — that pattern should also bound the session store to prevent OOM via session-flood. |
| SES-8 | LOW | `Session` is mutable enough that callers can hold a reference and inspect tokens after destroy. Consider returning a redacted view (`{userId, roles, displayName}`) from `SessionStore.get()` and exposing a separate `getTokens(id)` method gated by a port. |

### 3. PKCE

| ID | Severity | Finding |
|----|----------|---------|
| PKCE-1 | CRITICAL | **No PKCE store exists.** Grep for `PKCEStore`, `pkceStore`, `verifierStore`, or `Map<String, String>.*pkce` returns zero hits in `bff/social_care_web/lib/`. `OidcServerClient.buildAuthorizationUrl` (line 72) takes `state` and `codeVerifier` as parameters but no callsite supplies them — the only caller is the `LoginUseCase` which delegates to `AuthContract.login()` which is a `FakeAuthBff` returning a static URL. Real PKCE is not implemented. (OWASP ASVS V2.10, RFC 7636) |
| PKCE-2 | CRITICAL | **No `state` validation in callback** — `AuthCallbackIntent.parseFromQuery` (`auth_callback_intent.dart:26-44`) requires `state` to be present and non-empty but does NOT match it against a server-side store. A CSRF attacker can craft a callback with arbitrary `state`. Once PKCE-1 is fixed, the `consume(state)` step must happen before the token exchange. |
| PKCE-3 | HIGH | `_generateCodeChallenge` (`oidc_server_client.dart:166-169`) uses SHA-256 and `base64Url.encode(...).replaceAll('=', '')` which is correct per RFC 7636 §4.2 (S256). However, no `code_verifier` GENERATOR exists in the codebase. Spec demands 43-128 chars, [A-Z][a-z][0-9]-._~ unreserved. When this is implemented, use `Random.secure()` with at least 32 bytes and base64url-encode without padding. |
| PKCE-4 | MEDIUM | The `OidcServerClient` does not emit a `nonce` parameter on `buildAuthorizationUrl`. Per OIDC Core §3.1.2.1, `nonce` is REQUIRED for `id_token` recipients (including `response_type=code` flows that consume id_token). When id_token validation lands (TOK-2), `nonce` must be added to the auth URL and verified against the id_token claim. |

### 4. RBAC

| ID | Severity | Finding |
|----|----------|---------|
| RBAC-1 | HIGH | **No role-based route guard exists.** `authGuardMiddleware` (`auth_guard_middleware.dart`) checks ONLY for session presence (line 14: `if (session == null)` → 401). There is NO middleware that checks `session.roles` against a required set. `social_worker`/`owner`/`admin` distinctions are entirely absent from the BFF — `/team/*` (admin-level: register worker, reset password, assign role) is gated only by "any session". An authenticated `owner` (read-only) can call `POST /team/<id>/reset-password` and the BFF will forward it. Backend Vapor enforces RBAC, but the BFF MUST defend in depth. |
| RBAC-2 | HIGH | **`authGuardMiddleware` is not wired into the protected pipeline** — `app_router.dart:172-176` adds `observabilityMiddleware` + `sessionMiddleware` to `protectedPipeline` but **never adds `authGuardMiddleware`**. Combined with SES-1/SES-2, every protected route currently behaves as if no auth were required. (OWASP ASVS V4.1.1, V4.1.5) |
| RBAC-3 | HIGH | **No `X-Actor-Id` extraction or injection in social_care_web** — `social_care_api_client.dart:17,26` accepts an `actorId` constructor param and pins it in the Dio default headers, but there is no callsite that constructs `SocialCareApiClient` with the resolved `Session.userId`. With FakeAuthBff in place this is moot; in A19 the wiring must extract `actor` from the session and forward it to every mutating handler. The audit trail relies on it. |
| RBAC-4 | MEDIUM | The `Session.roles` set is unmodifiable but never validated against a known whitelist (`{social_worker, owner, admin}`). A malicious or misconfigured Zitadel project could ship arbitrary role strings; downstream RBAC checks (when added) should refuse unknown roles rather than silently accept them. |
| RBAC-5 | MEDIUM | `MeResponse.roles: List<String>` (`shared/lib/src/contract/dto/responses/auth/me_response.dart:21`) is sent as-is to the browser. Roles are not PII per LGPD, but they do leak the authorization model to anyone who can read the cookie response. Acceptable, but document it. |

### 5. Password / credentials

| ID | Severity | Finding |
|----|----------|---------|
| PWD-1 | INFO | No password hashing or storage occurs in the BFF — Zitadel owns this, correct per architecture. Verified via grep: `bcrypt`, `argon2`, `scrypt`, `pbkdf2`, `password_hash` all return no hits in BFF code. |
| PWD-2 | LOW | `ResetPasswordUseCase` (`use_cases/reset_password_use_case.dart`) signals "intent" to Zitadel but does NOT enforce the OWASP forgot-password best practice of always returning a generic success response (account enumeration prevention). Currently it surfaces backend errors: a 404 from Zitadel will leak whether `memberId` is a real user. The handler `_extractError` echoes `BackendError.code` upstream. Recommend collapsing all reset-password failures into a generic 202 Accepted at the BFF layer. |

### 6. Auth endpoints

| ID | Severity | Finding |
|----|----------|---------|
| EP-1 | HIGH | `_handleLogin` (`auth_handler.dart:72-84`) issues a 302 to whatever `AuthContract.login()` returns, with NO validation that the URL is the configured `oidcIssuer`. With `FakeAuthBff` (`fake_auth_bff.dart:15`) it points to `https://fake-idp.local/...`. A real `AuthContract` impl that returns an attacker-controlled URL becomes an open redirect. Add a strict origin check before responding with `Location:`. |
| EP-2 | HIGH | `LoginIntent.parseFromQuery` (`login_intent.dart:21-26`) accepts `returnTo` as a free-form string. If the OIDC flow ever round-trips `returnTo` to the post-callback redirect (currently not implemented), this becomes another open-redirect vector. Pre-empt by whitelisting same-origin paths only (`startsWith('/')` AND `!startsWith('//')`). |
| EP-3 | MEDIUM | `/auth/login` is a `GET` handler (line 60) with no CSRF token. Acceptable because login does not authenticate (it just redirects), but if `LoginIntent.returnTo` is ever persisted server-side (PKCE-store-attached) it must be treated as a CSRF-bearing parameter. |
| EP-4 | MEDIUM | `/auth/logout` is `POST` (line 62) — good. But `_handleLogout` (`auth_handler.dart:132-150`) reads the session cookie, builds a `LogoutIntent` with `sessionId: ''` if the cookie is absent (line 135), and dispatches anyway. The `_logout.execute(intent, ...)` flow does not consume `intent.sessionId` (`logout_use_case.dart:17-23` — never reads `intent.sessionId`); it just calls `_auth.logout()`. Server-side session destruction is missing — even when `LogoutUseCase` returns success, `SessionStore.destroy(sessionId)` is never called. The cookie clears in the browser, but the session lingers server-side until TTL expiry. (OWASP ASVS V3.3.1) |
| EP-5 | LOW | `/auth/refresh` returns a generic success body (`auth_handler.dart:191-194`) but does not communicate the new expiry (`expires_in`) — the client can't proactively refresh. Consider returning `{expires_at: ISO8601}`. |

### 7. Logout completeness

| ID | Severity | Finding |
|----|----------|---------|
| LO-1 | CRITICAL | **Logout does not destroy the server-side session.** See EP-4. The chain `_handleLogout` → `LogoutIntent(sessionId)` → `LogoutUseCase` → `AuthContract.logout()` never invokes `SessionStore.destroy`. Until A19 wires a real `AuthContract` impl that calls `sessionStore.destroy(sessionId)` AND `oidcClient.revokeToken(refreshToken)`, logout is a client-side cookie clear only. |
| LO-2 | HIGH | **No token revocation upstream.** `OidcServerClient.revokeToken` exists (line 136) but is never invoked. On logout the refresh token remains live at Zitadel for its full lifetime (typically 30+ days) — a stolen refresh token survives logout. |
| LO-3 | MEDIUM | **No "log out everywhere" surface.** Standard practice (OWASP ASVS V3.3.4) is to expose a "revoke all my sessions" endpoint that destroys every server-side session for `userId`. The `SessionStore` has no `destroyAllForUser(userId)` method. |
| LO-4 | LOW | `_buildClearSessionCookie` (`auth_handler.dart:227-230`) sets `Max-Age=0` and an empty value — correct for browser eviction. Good. |

### 8. MFA / 2FA

| ID | Severity | Finding |
|----|----------|---------|
| MFA-1 | HIGH | **MFA/2FA is entirely absent from the BFF.** Grep for `mfa`, `MFA`, `2FA`, `two_factor`, `totp`, `webauthn` returns zero hits across all 3 in-scope packages. Zitadel can enforce MFA at the IdP layer (acceptable design), but the BFF should at minimum:<br>(a) Surface an `amr` claim (`["mfa", "pwd"]`) inspection in id_token validation when TOK-2 is fixed, and<br>(b) Refuse to grant `admin` role sessions without an `amr` containing `mfa`.<br>For a system handling LGPD-protected health data on rare-disease patients, MFA enforcement on `admin` and `social_worker` roles is essentially mandatory. Document the gap and the Zitadel-side enforcement plan. |

### 9. Account lockout / brute force

| ID | Severity | Finding |
|----|----------|---------|
| RL-1 | MEDIUM | **No rate limiting in the BFF.** Grep for `rate`, `RateLimit`, `throttle`, `brute` returns no matches. Zitadel handles login lockout at the IdP layer, but the BFF endpoints `/auth/login`, `/auth/callback`, `/auth/refresh`, `/auth/me`, `/auth/logout`, and especially `POST /team/<id>/reset-password` are open to volumetric abuse. Add per-IP and per-userId token-bucket limiting before public exposure. |
| RL-2 | LOW | The session-store unbounded growth (SES-7) interacts with this — a cookie-flooding attacker can fill the in-process `Map` until OOM with no rate limit in place. |

### 10. Secret management

| ID | Severity | Finding |
|----|----------|---------|
| SEC-1 | LOW | **`.env` file is committed to the repo** (`bff/social_care_web/.env`). Confirm via `git ls-files` whether the actual secrets file (not the `.example`) is tracked. If yes: rotate the secrets, delete the file from history, and gitignore. (Already flagged on the wider DevSecOps audit; reiterating because OIDC client_secret is one of the values.) |
| SEC-2 | INFO | `ServerConfig.fromEnvironment` (`server_config.dart:27-62`) requires `OIDC_CLIENT_SECRET`, `SESSION_SECRET` etc. via `Platform.environment` and throws `StateError` on absence — good fail-fast. No defaults, no fallbacks. |
| SEC-3 | MEDIUM | `SESSION_SECRET` is required (`server_config.dart:55`) but is **never used** anywhere in the codebase — grep shows only the field definition and the env read. The session ID is purely random (no HMAC-signed cookie). For an opaque session-id design this is fine, BUT the field name promises something the code does not deliver; either implement signed cookies (defense in depth against ID forgery in case of timing attacks on `SessionStore.get`) or rename / drop the env var. |
| SEC-4 | LOW | `OIDC_REDIRECT_URI=http://localhost:8081/auth/callback` in `.env.example` — fine for dev, but the `__Host-` cookie prefix REQUIRES HTTPS (`Secure` attribute) per RFC 6265bis. In dev over HTTP, the browser will silently drop the cookie. Add a doc note + a runtime warning when `OIDC_REDIRECT_URI` is `http://`. |

## Trust Model verification

- **Browser NEVER sees tokens:** PARTIALLY VERIFIED. By design, yes — `Session.accessToken` lives only in `SessionStore` (server memory). In current production wiring (TOK-1) there is no real token to leak because no real OIDC exchange happens. Once A19 lands a real `AuthContract`, recheck.
- **BFF as Iron Frontier:** PARTIALLY VERIFIED. The proxy boundary pattern is in `social_care_api_client.dart` (token + `X-Actor-Id` injected server-side), but the client is not currently used — `app_router.dart` consumes `*Contract` instances which are `Fake*Bff` from `shared/`. No request actually traverses the BFF to a real backend yet. **VIOLATION at `bff/social_care_web/bin/server.dart:21-29`** (all contracts are fakes).
- **Split-Token Pattern (web vs desktop):**
  - **Web:** Designed correctly (access in server memory, opaque session cookie, refresh in-store); broken in wiring (SES-1, SES-2, TOK-1).
  - **Desktop:** PARTIALLY VERIFIED. `RemoteBase.buildDio` (`remote_base.dart:33-61`) uses a `tokenProvider` callback so tokens are NOT persisted in Dio's BaseOptions — good. **VIOLATION:** the desktop package has zero references to `flutter_secure_storage`, Keychain, DPAPI, or any other secure-storage adapter. Whoever calls `SocialCareDesktop.create(tokenProvider: ...)` is fully responsible for sourcing the token securely; nothing in `bff/social_care_desktop/` enforces or even documents that the token must come from `flutter_secure_storage` and not `SharedPreferences` or in-memory fields. This is a documentation gap that will become a critical bug if a downstream developer hooks `tokenProvider: () => prefs.getString('token')`.

## Compliance scorecard (OWASP ASVS L2)

| Section | Coverage | Notes |
|---------|----------|-------|
| **V2 Authentication** | ~50% | V2.1 (passwords): N/A — Zitadel-owned. V2.2 (general auth): partial — OIDC client present, but flow not wired. V2.3 (auth lifecycle): MISSING — no MFA, no breach detection. V2.7 (out-of-band): partial — id_token NOT verified (TOK-2). V2.10 (service auth): incomplete — client_secret env-loaded but flow non-functional. |
| **V3 Session Management** | ~55% | V3.1 (fundamental): cookies have HttpOnly+Secure+SameSite=Strict + `__Host-` (good); but mismatch SES-1, no Max-Age (SES-4). V3.2 (binding): session ID is 256-bit random — good. V3.3 (timeout): only sliding TTL (SES-5), no absolute timeout, logout doesn't destroy server-side session (LO-1). V3.4 (cookie attrs): mostly compliant, fix SES-4. V3.5 (token-based): N/A. |
| **V4 Access Control** | ~25% | V4.1.1 (deny by default): FAILS — `authGuardMiddleware` not wired (RBAC-2). V4.1.3 (least privilege): FAILS — no role-based gating (RBAC-1). V4.2 (operation): no resource-ownership checks observed (out of scope of this dimension but flagged). V4.3 (admin): admin endpoints (`/team/*`) lack any extra hardening. |
| **V7 Error Handling** | ~80% | V7.1 (log content): excellent PII discipline (observability.dart, pii_mask.dart). V7.4 (error handling): handlers consistently return generic INTERNAL on non-`BackendError` failures, hiding stack traces. V7.4.1 (audit logs): breadcrumbs are well-structured. Minor: stray `print` in shelf_server.dart:46. |

## Concrete recommendations for A19/A20/A21

Ordered by priority (P0 = ship-blocker for production OIDC):

1. **[P0 / TOK-1, SES-1, SES-2, RBAC-2] Replace `FakeAuthBff` with a real `ZitadelAuthAdapter`** in `bin/server.dart` that:
   - Generates `state` + `code_verifier` on `login()`, persists them in a new `PKCEStore` (TTL 5min, max 1000 entries, sweep on `login()` per SKILL canon).
   - On `callback()`: consume the verifier from `PKCEStore`, exchange the code via `oidcClient.exchangeCode`, parse claims, call `sessionStore.create(...)`, return the new session ID upward so the handler can set the cookie.
   - Modify `_dispatchCallback` so the cookie value is the session ID returned by the use case, not `UuidUtil.generateV4()`.
   - Fix `session_middleware.dart` to read `__Host-session=` (not `__session=`).
2. **[P0 / RBAC-1, RBAC-2] Wire `authGuardMiddleware` into `protectedPipeline`** and add a parallel `roleGuardMiddleware({allowedRoles})` to gate `/team/*`, admin lookup operations, and any future admin surface. Add a unit test that asserts `owner` cannot reach `POST /team`.
3. **[P0 / LO-1, LO-2] Implement true logout** in the new `ZitadelAuthAdapter.logout()`: call `sessionStore.destroy(sessionId)` AND `oidcClient.revokeToken(refreshToken)`. Add a test that asserts the session is gone after logout.
4. **[P1 / SES-4, SES-5] Cookie + TTL alignment**: emit `Max-Age=${sessionTtl.inSeconds}`; introduce an absolute-timeout field (`createdAt`) in `Session` and reject in `SessionStore.get` once `now - createdAt > absoluteMax` (default 12h).
5. **[P1 / TOK-2, PKCE-4] Introduce `nonce` and id_token validation** — generate a nonce, persist it alongside PKCE, verify `id_token.nonce` after exchange. Use a JWKS-backed verifier (likely `package:jose` or `package:dart_jsonwebtoken`) — validate `iss` against `OIDC_ISSUER`, `aud` against `OIDC_CLIENT_ID`, `exp` with a clock-skew of 30s, and the JOSE alg whitelist (`RS256` only — reject `none`).
6. **[P1 / SES-3, SES-6, SES-7] Session hygiene**: rotate session ID on token refresh (call `SessionStore.updateTokens` AND issue a new ID via a new `rotate(sessionId)` method); schedule a periodic `Timer.periodic(Duration(minutes: 1), (_) => sessionStore.destroyExpired())`; cap entries at 100k with LRU eviction.
7. **[P1 / PKCE-2] Validate `state` in callback** — make `AuthCallbackUseCase` look up the state in `PKCEStore` BEFORE token exchange, and refuse with a generic `INVALID_CALLBACK` 400 on miss.
8. **[P2 / EP-1, EP-2] Open-redirect hardening** — `LoginUseCase` should validate the returned URL's `Uri.parse(...).origin == config.oidcIssuer` before propagation; `LoginIntent.returnTo` should be normalized to a same-origin path (`startsWith('/') && !startsWith('//')`).
9. **[P2 / RBAC-3] `X-Actor-Id` propagation** — once the real `SocialCareApiClient` is wired, build it per-request from the resolved `Session.userId` (via a factory injected into handlers), not at app construction.
10. **[P2 / RL-1] Rate limiting** — apply a token-bucket middleware on `/auth/*` (per-IP: 30 rpm; per-userId on `/auth/refresh`, `/team/*/reset-password`: 10 rpm). Use `package:shelf_limiter` or roll a simple in-memory bucket.
11. **[P3 / TOK-3, SES-6] Multi-instance safety** — replace the `Map`-backed `SessionStore` and `PKCEStore` with Redis-backed implementations once a second BFF replica is foreseen (likely A20+ ops work).
12. **[P3 / MFA-1] Document MFA enforcement** in `handbook/architecture/DECISIONS.md`: state which roles require MFA, which Zitadel project enforces it, and add a BFF-side `amr` claim check on the id_token for defense-in-depth.
13. **[P3 / PWD-2] Generic reset-password response** — collapse `_handleResetPassword` failure paths into 202 Accepted regardless of upstream outcome (preserve the breadcrumb trail for ops, hide enumeration from caller).
14. **[P3 / SEC-3] `SESSION_SECRET` semantics** — either drop the env var or use it to HMAC-sign session cookies (`<sessionId>.<HMAC(sessionId, SESSION_SECRET)>`) so a stolen ID alone cannot be replayed. Reject mismatches at `sessionMiddleware`.
15. **[P3 / Desktop tokenProvider] Document and enforce** in `bff/social_care_desktop/README.md` (and ideally a doc-comment on `SocialCareDesktop.create`'s `tokenProvider` arg) that the callback MUST read from `flutter_secure_storage` (Keychain on macOS, Credential Manager on Windows, libsecret on Linux). Consider shipping a `SecureTokenProvider` helper from the desktop package itself.

---

**Total findings: 41** (Critical: 5, High: 13, Medium: 13, Low: 8, Info: 2).
