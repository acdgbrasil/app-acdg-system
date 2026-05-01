# RED Team Scan — BFF Comprehensive (2026-05-01)

> Offensive scan executed by the `red-team-scanner` skill against
> `bff/social_care_web/`, `bff/social_care_desktop/` and `bff/shared/`.
> Read-only mental-model analysis. No exploits were executed against
> live systems.

## Executive summary

- **Security score**: **18 / 100** (the BFF Web is currently a permissive
  demo wired with `Fake*Bff` adapters; the entire authentication and
  authorization story is non-functional in production code paths).
- **Critical exploitable vulnerabilities**: **9**
- **High-severity vulnerabilities**: **8**
- **Medium-severity vulnerabilities**: **7**
- **Low-severity vulnerabilities**: **4**
- **Defense-in-depth gaps**: **11** (CSP, X-Requested-With, Sec-Fetch-Site,
  rate limiting, MFA, Drift encryption, request-body size limits, error-rate
  alerting, audit-log integrity, dependency pinning, container hardening).

### Top 3 attack scenarios

1. **Anonymous session minting**: `GET /auth/callback?code=anything&state=anything`
   returns `302` with a `__Host-session=<random uuid>` cookie. Because
   `bin/server.dart` wires `FakeAuthBff` as the production `AuthContract`,
   no token exchange against Zitadel ever happens. Worse, `sessionMiddleware`
   reads cookie name `__session` (not `__Host-session`), so the cookie does
   not even need to be honoured by the server — every "protected" route is
   already wide open because `authGuardMiddleware` is **never installed**
   in the protected pipeline. Result: a remote unauthenticated attacker
   reads/writes every patient prontuário.
2. **Client-controlled actor identity (audit forgery)**: Every BFF Dio
   client (`SocialCareApiClient`, `PeopleContextClient`, `RemoteBase.buildDio`)
   accepts `actorId` as a *static constructor parameter* and never derives
   it from the resolved session. Combined with finding #1, an unauthenticated
   attacker can sneak any UUID into the `X-Actor-Id` slot the BFF later
   forwards to the Vapor backend, ruining the audit trail. On Desktop the
   parameter is filled by the caller — there is no contract that ties the
   actor to the OS-level logged-in user.
3. **Local Drift database tampering**: `app_cache.sqlite` and
   `app_sync_queue.sqlite` are stored under `getApplicationDocumentsDirectory()`
   in plaintext SQLite, with `firstName`, `lastName`, `primaryDiagnosis`,
   `payload` (full PatientResponse JSON), and the entire Outbox of
   pending mutations. Any user (or malware) on the desktop machine can
   `sqlite3 app_sync_queue.sqlite "INSERT INTO outbox VALUES …"` and
   inject mutations that the SyncEngine will dispatch on the next drain
   under the legitimate user's `Authorization: Bearer …`.

## Methodology

- **Skill**: `red-team-scanner` (`.claude/skills/red-team-scanner/SKILL.md`)
- **Frameworks**: OWASP Web Security Testing Guide (WSTG), OWASP Top 10
  2021, the 10 ACDG-specific attack vectors enumerated in the skill.
- **Approach**: black-box mental model + line-by-line code reading of every
  HTTP entry point, every middleware, every adapter, the OIDC client, the
  SessionStore, the SyncEngine + Outbox + 27-class sealed `SyncMutation`
  hierarchy, and the Drift schema files.
- **Scope (in)**: `bff/social_care_web/`, `bff/social_care_desktop/`,
  `bff/shared/`.
- **Scope (out)**: `apps/acdg_system/`, `packages/*`, `contracts/`,
  `social-care/` Vapor backend.

## Vulnerabilities (by severity, CVSS scored)

### CRITICAL (CVSS 9.0+)

#### Finding 01 — Auth guard middleware not wired into protected pipeline

- **CVSS**: 9.8 (`AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H`)
- **CWE**: CWE-862 (Missing Authorization)
- **OWASP**: A01:2021 — Broken Access Control
- **File:line**: `bff/social_care_web/lib/src/server/app_router.dart:173-176`
- **Vulnerability**: `app_router.dart` constructs `protectedPipeline` with
  only `observabilityMiddleware()` + `sessionMiddleware(...)`. The class
  Dartdoc claims "Auth guard middleware rejects requests with no session
  on protected routes" (line 75-76), but `authGuardMiddleware()` (defined
  in `middleware/auth_guard_middleware.dart`) is **never added** to that
  pipeline. The middleware also has no usages anywhere in `lib/`.
- **PoC**:
  ```bash
  # No cookies, no Authorization, no nothing.
  curl -s http://bff.local/patients
  curl -s http://bff.local/patients/00000000-0000-4000-8000-000000000001
  curl -s -X POST http://bff.local/patients \
       -H 'content-type: application/json' \
       -d '{"firstName":"a","lastName":"b","cpf":"11144477735",…}'
  curl -s -X POST http://bff.local/team/<uuid>/reset-password
  curl -s -X PUT  http://bff.local/team/<uuid>/deactivate
  ```
  Every request reaches the use case and currently runs against
  `Fake*Bff` (so it returns 200 with fake data), but as soon as the
  Wave-N adapters land (`SocialCareApiClient` is already complete), the
  same calls will read/mutate real prontuários.
- **Impact**: Total bypass of authentication. CRUD over patient
  prontuários, family members, assessments, referrals, violation reports,
  team-member lifecycle (deactivate / password reset), and lookup
  governance — all reachable anonymously. LGPD violation by design.
- **Remediation**: Add `.addMiddleware(authGuardMiddleware())` to
  `protectedPipeline` after `sessionMiddleware`. Pin with a regression
  test that `curl -s -o /dev/null -w "%{http_code}" /patients` returns
  401.

#### Finding 02 — Cookie-name mismatch defeats session resolution entirely

- **CVSS**: 9.1 (`AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N`)
- **CWE**: CWE-287 (Improper Authentication)
- **OWASP**: A07:2021 — Identification and Authentication Failures
- **File:line**:
  - `bff/social_care_web/lib/src/handlers/auth_handler.dart:21` — sets
    `__Host-session=…`.
  - `bff/social_care_web/lib/src/middleware/session_middleware.dart:48` —
    parses `__session=…`.
- **Vulnerability**: `auth_handler.dart` writes the cookie under the name
  `__Host-session`. `session_middleware.dart` parses the header looking
  for `__session=`. Result: even if the session-store wiring worked, the
  middleware would never find the cookie, so `request.context[sessionContextKey]`
  is always null on protected routes. The handler `getSession(Request)`
  helper in `handler_utils.dart:18` performs `request.context[…] as Session`
  — a hard cast that would throw `TypeError` on any request that *did*
  end up calling it, leaking a 500 + stack trace via the unhandled-error
  path of `observabilityMiddleware`.
- **PoC**: Send any cookie header (or none) to a protected route — the
  session is never attached. Even if Finding #1 is fixed first, the auth
  guard will reject every authenticated user because the middleware can't
  read the cookie it issued.
- **Impact**: Even after Finding #1 is fixed, *all* legitimate users are
  blocked unless an attacker sends a manually-crafted `Cookie: __session=…`
  header. The attacker's exploit is *trivial*: fabricate any UUID,
  package it as `__session=<uuid>`, and the middleware would (after
  Finding #1 is fixed) attach a session whose `_sessions` map entry was
  never created — so `store.get(sessionId)` returns null, and
  `authGuardMiddleware` rejects with 401. So the *direct* exploit chain
  produces 401, but the design fault (cookie-name drift) is a critical
  precursor to silent auth bypass once these layers wire up properly.
- **Remediation**: Pick one canonical cookie name (`__Host-session`) and
  use it in both files. Add a contract test that asserts
  `parseSessionCookie(buildSessionCookie('x'))` round-trips.

#### Finding 03 — `__Host-session` cookie value disconnected from session store

- **CVSS**: 9.0 (`AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N`)
- **CWE**: CWE-384 (Session Fixation), CWE-287
- **OWASP**: A07:2021
- **File:line**: `bff/social_care_web/lib/src/handlers/auth_handler.dart:121`
- **Vulnerability**: `_dispatchCallback` returns
  ```dart
  Response(302, headers: {
    'location': '/',
    'set-cookie': _buildSessionCookie(UuidUtil.generateV4()),
  });
  ```
  The cookie value is a brand-new random UUID that was never inserted
  into the `SessionStore`. No `_sessionStore.create(...)` is called in
  `AuthHandler` or in any of the auth use cases. So even after Findings
  1+2 are fixed, the cookie does not correspond to any server-side
  session. Conversely `SessionStore.create()` *is* defined but is never
  invoked by production code — entirely dead code path.
- **PoC**:
  1. Hit `/auth/callback?code=x&state=y`.
  2. Browser receives `Set-Cookie: __Host-session=550e8400-e29b-…`.
  3. Browser presents that cookie to `/patients`.
  4. `sessionMiddleware` (after fixing the name mismatch) calls
     `store.get('550e8400-…')` and gets `null`.
  5. `authGuardMiddleware` (after wiring it) returns 401.
- **Impact**: Authentication is currently impossible to complete. After
  Findings 1+2 are fixed but #3 isn't, no user can ever reach a
  protected route. After `_sessionStore.create(...)` is wired, the same
  generator can be exploited for **session fixation**: an attacker
  who controls the UUID generator (or who can predict it under a
  weak RNG) hands a victim a pre-set cookie, then uses the same value
  themselves. The current generator is `Random.secure()` — but the fact
  that the cookie value travels round-trip through the user's browser
  *without being rotated on auth-state change* is a textbook session
  fixation primitive.
- **Remediation**: After successful token exchange, do
  `final id = sessionStore.create(...)` and use that `id` in
  `_buildSessionCookie`. On every privilege-state transition (login,
  logout, refresh, role change) regenerate the session ID.

#### Finding 04 — `FakeAuthBff` wired as production `AuthContract`

- **CVSS**: 9.8 (`AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H`)
- **CWE**: CWE-489 (Active Debug Code), CWE-287
- **OWASP**: A05:2021 — Security Misconfiguration
- **File:line**: `bff/social_care_web/bin/server.dart:21-29`
- **Vulnerability**: The production entrypoint hard-wires every contract
  to its in-memory `Fake*Bff`:
  ```dart
  final AuthContract authContract = FakeAuthBff();
  final RegistryContract registryContract = FakeRegistryBff();
  …
  ```
  `FakeAuthBff.callback` ignores `code` + `state` and always returns
  `Success(_wrap(null))`; `FakeAuthBff.me` always returns a hardcoded
  user `Fake User` with role `social_worker`. So the entire OIDC flow
  is short-circuited.
- **PoC**:
  ```bash
  curl -i 'http://bff.local/auth/callback?code=x&state=y'
  # → HTTP/1.1 302 Found
  # → location: /
  # → set-cookie: __Host-session=…
  curl -s -b '__Host-session=anything' http://bff.local/auth/me
  # → {"userId":"fake-user-id","email":"fake@acdgbrasil.com.br",…
  ```
- **Impact**: 100 % of authentication is fake. Anyone hitting the BFF is
  treated as "Fake User / social_worker". Every `Fake*Bff` accepts every
  write and returns canned reads. While *currently* limited to in-memory
  state (no real PII flows yet), the moment the production adapter is
  swapped in, this configuration ships unauthenticated full backend
  access.
- **Remediation**: Build a `Wave3OidcAuthBff` that talks to
  `OidcServerClient` + `SessionStore` and wire it here. Gate on a
  `ENVIRONMENT=production` env flag that refuses to start when any
  `Fake*Bff` is active. Add a smoke test that asserts
  `bin/server.dart` does not reference any class whose name starts
  with `Fake`.

#### Finding 05 — ID-token signature, `iss` and `aud` validation skipped

- **CVSS**: 9.1 (`AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N`)
- **CWE**: CWE-345 (Insufficient Verification of Data Authenticity),
  CWE-347 (Improper Verification of Cryptographic Signature)
- **OWASP**: A02:2021 — Cryptographic Failures
- **File:line**: `bff/social_care_web/lib/src/auth/oidc_server_client.dart:148-163`
- **Vulnerability**: `parseIdTokenClaims` decodes the JWT payload via
  `base64Url.decode` and `jsonDecode`, returning the claims map *without
  verifying the signature, the issuer, or the audience*. The author's
  comment ("BFF trusts its own token endpoint response received over
  HTTPS, so no signature verification is needed") is incorrect: an
  attacker who can MITM the BFF→Zitadel TLS connection (compromised CA,
  rogue corporate proxy, mis-pinned cert), or who can hit the local
  `/auth/callback` with a forged response from a malicious IdP at the
  same issuer URL, can mint arbitrary identities — including
  promoting `social_worker` to `admin` by just editing the JSON before
  re-encoding.
- **PoC**: After reaching the token endpoint via a MITM (or a poisoned
  Docker DNS that redirects `auth.acdgbrasil.com.br` to the attacker),
  return `{"access_token":"x","refresh_token":"y","id_token":"<unsigned>","expires_in":3600}`
  where the unsigned id_token's payload contains `{"sub":"victim",
  "roles":["admin"]}`. The BFF caches the claims as truth.
- **Impact**: Identity spoofing / role escalation if the BFF→Zitadel
  channel is ever weakened. LGPD blast radius is enormous because
  `admin` roles unlock the entire team-management surface.
- **Remediation**: Use `dart_jsonwebtoken` (already a direct dep) with
  `ECPublicKey` / `RSAPublicKey` resolved from the JWKS endpoint. Verify
  `iss`, `aud`, `exp`, `nbf`, and the signature. Cache JWKS keys for
  ~10 min with negative caching.

#### Finding 06 — `state` (CSRF) parameter never validated

- **CVSS**: 8.8 (`AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:N`) — closer to
  Critical for OIDC flows that fan out into prontuários.
- **CWE**: CWE-352 (Cross-Site Request Forgery), CWE-1275 (Sensitive
  Cookie with Improper SameSite)
- **OWASP**: A01:2021
- **File:line**:
  - `bff/social_care_web/lib/src/intents/auth_callback_intent.dart:26-44`
  - `bff/social_care_web/lib/src/use_cases/auth_callback_use_case.dart:33`
- **Vulnerability**: `AuthCallbackIntent.parseFromQuery` only checks that
  `state` is non-empty. The use case forwards it to
  `_auth.callback(code:..., state:...)` — but `FakeAuthBff` ignores it,
  and even the `OidcServerClient` does not have a path that asserts the
  state matches a value the BFF previously stored at `/auth/login`. There
  is no `_pkceVerifierStore` of any kind. Therefore CSRF on the OIDC
  callback is trivial — an attacker who can convince a victim to follow
  a crafted callback URL hijacks the victim's session establishment.
- **PoC**: Attacker performs an OIDC login on their own behalf, captures
  the `code` Zitadel returns, and embeds `https://bff.local/auth/callback?code=<atk>&state=anything`
  into a phishing page. Victim clicks; the BFF accepts the code and
  attaches the *attacker's* identity to the *victim's* browser session.
- **Impact**: Account takeover via session-fixation-by-CSRF: the victim
  ends up using the BFF as the attacker's identity, but with the
  victim's network access, perfect for keylogging via "auth proxy" or
  for collecting evidence under another user's name. Also a vehicle for
  the audit-trail-poisoning chain (Finding 12).
- **Remediation**: At `/auth/login` generate `state` + `codeVerifier`,
  store both in a short-lived (5 min) signed cookie or server-side
  store, and reject `/auth/callback` whose `state` does not match.

#### Finding 07 — PKCE verifier never stored or replayed

- **CVSS**: 8.6 (`AV:N/AC:H/PR:N/UI:R/S:U/C:H/I:H/A:N`)
- **CWE**: CWE-287, CWE-352
- **OWASP**: A07:2021
- **File:line**: `bff/social_care_web/lib/src/auth/oidc_server_client.dart:72-92,99-117`
- **Vulnerability**: `OidcServerClient.buildAuthorizationUrl` accepts a
  `codeVerifier` argument; `OidcServerClient.exchangeCode` *also* accepts
  one. Nowhere is the verifier persisted between the two calls — there is
  no `_pkceStore`, no Redis, no signed cookie. The skill's specification
  ("PKCE verifiers: TTL 5min, max 1000 entries, sweep on login()") is
  unimplemented. So the moment a real auth path lands, login flows will
  either (a) reuse a static verifier (attackable) or (b) explode at
  callback time. The current `FakeAuthBff` masks both failure modes.
- **PoC**: Once a real `OidcAuthBff` is wired, an attacker who observes
  one `code_challenge` (it travels in the redirect URL the user sees in
  their browser) can correlate any future `code` Zitadel returns with
  the same challenge, defeating the entire PKCE proof.
- **Impact**: PKCE downgrade — defeats the cross-device / cross-tab
  protection that PKCE is meant to provide.
- **Remediation**: Store `state -> {codeVerifier, redirectAfter, …}` in
  a server-side cache or signed encrypted cookie with TTL ≤ 5 min and
  one-time consumption.

#### Finding 08 — Sensitive secrets present in repo working tree

- **CVSS**: 9.1 (`AV:L/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:N`)
- **CWE**: CWE-798 (Use of Hard-coded Credentials), CWE-540
- **OWASP**: A05:2021
- **File:line**: `bff/social_care_web/.env`
- **Vulnerability**: A real `.env` file exists on disk in the repo working
  tree containing what looks like a *production* Zitadel `OIDC_CLIENT_SECRET`
  (`puoXaeAruKmY2YlaMjuwcS7pkD4zS4VKmJKiQaCuMwltkgMtisITpMiO47zXzqpi`),
  a 32-byte `SESSION_SECRET`
  (`1FhExUabs6Q/cHnyoWSyk4lX+n9Smy0fu46POcweZxw=`), and HML backend URLs.
  `.env` is git-ignored at the monorepo root (so it isn't in the commit
  history at this moment), but the secret IS sitting on the developer's
  workstation, in any backup of the working tree, in any Docker build
  context that is `COPY . /src` without a `.dockerignore`, and in any
  IDE indexing service that walks the project. Anyone with developer-
  workstation access can lift the OIDC client secret and impersonate the
  BFF against Zitadel.
- **PoC**:
  ```bash
  cat bff/social_care_web/.env
  curl -X POST https://auth.acdgbrasil.com.br/oauth/v2/token \
       -d 'grant_type=client_credentials' \
       -d 'client_id=367349956392059030' \
       -d 'client_secret=puoXaeAruKmY2YlaMjuwcS7pkD4zS4VKmJKiQaCuMwltkgMtisITpMiO47zXzqpi'
  ```
- **Impact**: Compromise of the OIDC client secret enables an attacker
  to mint tokens that the backend will validate. End-to-end takeover of
  every social-care user. *Treat this secret as already burned.*
- **Remediation**:
  1. Rotate the Zitadel client secret immediately. The current value
     must be considered exposed.
  2. Move developer-loop secrets to a 1Password / Bitwarden vault or
     to `direnv` with `~/.envrc.private` (outside the repo tree).
  3. Add `bff/**/.env` to a top-level `.dockerignore` so Docker builds
     never inherit it.
  4. Pre-commit hook / `gitleaks` scan in CI to fail PRs that introduce
     `.env` files.

#### Finding 09 — Drift databases (cache + outbox) stored unencrypted on desktop

- **CVSS**: 9.0 (`AV:L/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:N`)
- **CWE**: CWE-311 (Missing Encryption of Sensitive Data)
- **OWASP**: A02:2021
- **File:line**:
  - `bff/social_care_desktop/lib/src/facade/social_care_desktop.dart:265-298`
  - `bff/social_care_desktop/lib/src/cache/_shared/cache_database.dart`
  - `bff/social_care_desktop/lib/src/sync/_shared/sync_database.dart`
  - `bff/social_care_desktop/lib/src/cache/_shared/tables/patients_table.dart:32-44`
- **Vulnerability**: Both Drift databases are opened with
  `NativeDatabase(File(filePath))` — no `setup` callback that loads
  SQLCipher, no PRAGMA `key`. The schema stores:
  - `patient_summaries.firstName / lastName / primaryDiagnosis` as plain
    columns (driving FTS5 triggers).
  - `patients.payload` — full `PatientResponse` JSON (CPF, NIS, CNS, RG,
    address, diagnoses, social fichas).
  - `outbox.payload` — the full body of every pending mutation,
    including `RegisterPatientRequest`, `UpdateHealthStatusRequest`,
    `ReportRightsViolationRequest` (rights-violation reports of children!),
    `UpdateSocialIdentityRequest` (raça/cor, gênero, orientação sexual).
  - `outbox.aggregateId` — the patientId / personId.
- **PoC** (offline DB tampering, also Top-3 attack #3):
  ```bash
  # On an unattended desktop or via malware running as the same user:
  cd "~/Library/Containers/<app>/Data/Documents"
  sqlite3 app_sync_queue.sqlite \
    "INSERT INTO outbox VALUES (
       '00000000-0000-4000-8000-FFFFFFFFFFFF',
       'patient', 'victim-uuid',
       'discharge_patient',
       '{\"reason\":\"…\",\"effectiveAt\":\"2026-05-01T00:00:00Z\"}',
       0, '2026-05-01T00:00:00Z', 0, NULL, NULL, 'pending');"
  ```
  On the next connectivity edge → online, `_PumpingSyncEngine.triggerDrain`
  picks it up and dispatches `_registry.dischargePatient(...)` with the
  legitimate user's `Authorization: Bearer …` header injected by
  `RemoteBase.buildDio`. The backend has no signal that the mutation was
  injected post-hoc.
- **Impact**: (a) Mass exfiltration of LGPD "dados sensíveis" by anyone
  with file-system access. (b) Full mutation injection — including
  `withdraw_patient`, `update_social_identity`, and (worst)
  `report_violation` reports that name a child as victim of fabricated
  abuse. (c) Forensics destroyed: `clear()` wipes everything; the
  comment says "Test helper; production code should never invoke this"
  but nothing prevents a malicious extension from doing so.
- **Remediation**: Switch to `sqlcipher_flutter_libs` and pass a key
  derived from the OS Keychain (Keychain on macOS, DPAPI on Windows,
  libsecret on Linux). Sign outbox rows with an HMAC seeded from the
  same OS secret so the SyncEngine rejects tampered rows
  (`SyncMutation.fromOutboxEntry` should fail-closed on HMAC mismatch).

### HIGH (CVSS 7.0-8.9)

#### Finding 10 — Logout/Refresh do not touch the SessionStore

- **CVSS**: 7.5 (`AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:N/A:N`)
- **CWE**: CWE-613 (Insufficient Session Expiration)
- **OWASP**: A07:2021
- **File:line**:
  - `bff/social_care_web/lib/src/use_cases/logout_use_case.dart:23`
  - `bff/social_care_web/lib/src/use_cases/refresh_use_case.dart:23`
- **Vulnerability**: `LogoutUseCase` calls `_auth.logout()` (the contract)
  but never `sessionStore.destroy(intent.sessionId)`. The cookie is
  cleared on the client via `Set-Cookie: …; Max-Age=0`, but a session
  captured earlier remains valid until `expiresAt` (default 1 h).
  `RefreshUseCase` similarly never calls `sessionStore.updateTokens(...)`.
- **PoC**: Capture a `__Host-session=…` cookie via local malware; victim
  clicks "Logout"; attacker keeps replaying the cookie for up to 1 h.
- **Impact**: Logout is cosmetic. Combined with the missing `Secure`
  enforcement on real prod (currently behind Caddy TLS), session theft
  has a long replay window.
- **Remediation**: In `LogoutUseCase` plumb the `SessionStore` and call
  `destroy(sessionId)`. In `RefreshUseCase` call `updateTokens` after a
  successful Zitadel refresh and rotate the cookie value.

#### Finding 11 — `getSession` performs unconditional cast → 500 on missing session

- **CVSS**: 7.5 (`AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H`)
- **CWE**: CWE-754 (Improper Check for Unusual or Exceptional Conditions)
- **OWASP**: A05:2021
- **File:line**: `bff/social_care_web/lib/src/handlers/handler_utils.dart:17-18`
- **Vulnerability**: `Session getSession(Request request) =>
  request.context[sessionContextKey] as Session;` — null cast crashes
  with `_TypeError`. The unhandled exception flows up to
  `observabilityMiddleware`, which returns 500 with a `requestId` so
  the attacker has a confirm-channel for "auth bypass not yet wired".
- **PoC**: Once any handler starts calling `getSession(request)` (currently
  none do — it's dead code), DoS via flooding unauthenticated requests
  is trivial (each one allocates a Stopwatch, a UUID, a logger frame).
- **Impact**: DoS amplification once Wave-N handlers actually use the
  helper; today it is latent risk.
- **Remediation**: Return `Session?` and have callers branch (`return
  401` on null). Or wire `authGuardMiddleware` so the cast is only ever
  reached after auth.

#### Finding 12 — `actorId` is a static config value, not derived from session

- **CVSS**: 8.1 (`AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:N`)
- **CWE**: CWE-345, CWE-285 (Improper Authorization)
- **OWASP**: A04:2021 — Insecure Design
- **File:line**:
  - `bff/social_care_web/lib/src/remote/social_care_api_client.dart:17,26`
  - `bff/shared/lib/src/infrastructure/people_context_client.dart:13,27`
  - `bff/social_care_desktop/lib/src/remote/_shared/remote_base.dart:33-46`
- **Vulnerability**: Every Dio client takes `actorId` as a single static
  string at construction. There is no per-request override path. So the
  `X-Actor-Id` header is whatever the wiring code passed — typically the
  service-account identity, *not* the human who triggered the mutation.
  No code path resolves `Session.userId` and threads it through to the
  Dio interceptor.
- **PoC**:
  - On Web, once Wave-N adapters land, every audit row says
    `actorId = <service-account-uuid>` regardless of which user signed
    in. LGPD imputability ruined.
  - On Desktop, `actorId` is whatever the shell passes to
    `SocialCareDesktop.create(actorId: …)`. Nothing prevents the shell
    from passing `actorId: anotherUserUuid`. The BFF will then submit
    mutations under that ID.
- **Impact**: Audit poisoning, repudiation, evidence destruction.
- **Remediation**: Refactor the Dio wiring so it accepts an
  `ActorIdProvider` (a closure) read on every request from the resolved
  session (Web) or from an OS-keychain-stored "currently logged-in user"
  on Desktop. Reject requests with no actor.

#### Finding 13 — `Authorization` header sourced from a single static token (Web)

- **CVSS**: 7.4 (`AV:N/AC:H/PR:L/UI:N/S:U/C:H/I:H/A:N`)
- **CWE**: CWE-287
- **OWASP**: A07:2021
- **File:line**: `bff/social_care_web/lib/src/remote/social_care_api_client.dart:14-31`
- **Vulnerability**: `SocialCareApiClient` is constructed with a single
  `accessToken` baked into the Dio `BaseOptions.headers`. There is no
  `tokenProvider` interceptor (unlike `PeopleContextClient` which at
  least has the closure path on lines 31-43). When the access token
  expires, every request will keep sending the stale token until the
  process is restarted. There is no per-session `Dio` instance — so two
  users hitting the same BFF will end up with one user's token attached
  to the other user's request.
- **PoC**: Wire-N Web: User A logs in → BFF builds Dio with token A.
  User B logs in → if the wiring reuses the same `SocialCareApiClient`,
  every request from B carries token A. (Even if a new client is built
  per session, refresh after 5 min still sends a stale token and gets
  401 forever.)
- **Impact**: Token bleeding, persistent 401 after refresh, identity
  confusion.
- **Remediation**: Mirror `PeopleContextClient`'s `tokenProvider` pattern
  but driven by the resolved session per request (e.g. from a Zone-local
  variable installed by `sessionMiddleware`).

#### Finding 14 — Open redirect via `LoginIntent.returnTo`

- **CVSS**: 7.4 (`AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:N/A:N`) — phishing-style.
- **CWE**: CWE-601 (URL Redirection to Untrusted Site)
- **OWASP**: A10:2021
- **File:line**: `bff/social_care_web/lib/src/intents/login_intent.dart:21-26`
- **Vulnerability**: `LoginIntent.parseFromQuery` accepts any non-empty
  `returnTo` — no scheme/host whitelist, no relative-path enforcement.
  The follow-up "redirect after login" path the comment promises is not
  yet wired (the use case discards `intent.returnTo`), but the value
  rides through breadcrumbs and downstream wiring is on the roadmap
  (`POST_LOGIN_REDIRECT_URL` env). Future Wave-N: an attacker hands the
  victim `https://bff.local/auth/login?returnTo=https://evil.com/phish`
  and after Zitadel finishes, the BFF redirects the freshly-authenticated
  user to evil.com — perfect for a credential-replay phishing page that
  *looks* like a session-timeout page asking for re-auth.
- **Impact**: Phishing, credential replay.
- **Remediation**: Whitelist `returnTo` against an allow-list of relative
  paths (`^/[a-zA-Z0-9_/-]*$`) and reject schemes / `//` prefixes.

#### Finding 15 — Path-segment injection via `tableName` lookup routes

- **CVSS**: 7.5 (`AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:N/A:N`) — reflective at
  the upstream.
- **CWE**: CWE-22 (Path Traversal), CWE-89 (SQL Injection if the upstream
  composes SQL from `tableName`)
- **OWASP**: A03:2021
- **File:line**:
  - `bff/social_care_web/lib/src/intents/get_lookup_table_intent.dart:8-10`
  - `bff/social_care_web/lib/src/handlers/lookup_handler.dart:153-170`
  - `bff/social_care_web/lib/src/remote/social_care_api_client.dart:678-680`
- **Vulnerability**: `GetLookupTableIntent.tableName` is a free-form
  `String`. The Web BFF interpolates it directly into `_dio.get(
  '/api/v1/dominios/$tableName')`. Same for `POST /lookups/<tableName>`,
  `PUT /lookups/<tableName>/<id>`, and the toggle PATCH. The handler does
  zero validation. The upstream Vapor backend likely matches the
  `tableName` against a whitelist, but this BFF is the place where input
  validation should happen — and it does not.
- **PoC**: `GET /lookups/..%2F..%2Fpatients` — depending on the Vapor
  router's normalisation, this could escape the `/dominios/` prefix.
  `GET /lookups/dominio_x';DROP--` if the upstream concatenates table
  names into raw SQL (per ACDG memory the Swift backend uses SQLKit;
  prepared statements are likely, but the BFF should not assume).
- **Impact**: Backend SQL injection if the upstream concatenates,
  information disclosure of internal tables, or just attack-surface
  amplification.
- **Remediation**: Add a smart constructor `LookupTableName(raw)` that
  matches `^dominio_[a-z][a-z0-9_]{0,40}$`. Reject anything else with
  400 `INVALID_TABLE_NAME`.

#### Finding 16 — CORS allows `Access-Control-Allow-Credentials: true` with broad echoed methods

- **CVSS**: 7.5 (`AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:N`)
- **CWE**: CWE-942 (Permissive Cross-domain Policy with Untrusted Domains)
- **OWASP**: A05:2021
- **File:line**: `bff/social_care_web/lib/src/middleware/cors_middleware.dart:21-27`
- **Vulnerability**: When `frontendOrigin` is set (dev mode), the
  middleware echoes:
  ```
  Access-Control-Allow-Origin: <static value>
  Access-Control-Allow-Credentials: true
  Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
  Access-Control-Allow-Headers: Content-Type, X-Requested-With
  ```
  The middleware does NOT validate the request `Origin` header against
  the configured `allowedOrigin` — it simply parrots `allowedOrigin`
  into the response regardless. So if a developer ever ships
  `FRONTEND_ORIGIN=*` (env-driven, no validation in `ServerConfig`), the
  server immediately becomes wildcard-with-credentials, the textbook
  worst-case CORS misconfig. The `_corsHeaders` are also applied to ALL
  responses (line 16) — including health checks and 4xx/5xx error
  responses, which can leak across origins.
- **Impact**: If `FRONTEND_ORIGIN` is mis-set in any environment, every
  user's `__Host-session` (or the legacy `__session`) is reachable to
  any cross-origin script. Even with strict origin, the missing
  `Vary: Origin` makes downstream caches store the wrong headers.
- **Remediation**: Validate `request.headers['origin']` against the
  configured allow-list and only echo when it matches. Add `Vary:
  Origin`. Reject `*` in `ServerConfig.fromEnvironment`. Strip CORS
  headers on health-check + error responses.

#### Finding 17 — `shelf.logRequests()` runs *before* PII scrubbing

- **CVSS**: 7.5 (`AV:N/AC:H/PR:L/UI:N/S:U/C:H/I:N/A:N`)
- **CWE**: CWE-532 (Insertion of Sensitive Information into Log File)
- **OWASP**: A09:2021
- **File:line**: `bff/social_care_web/lib/src/server/shelf_server.dart:33`
- **Vulnerability**: `shelf.logRequests()` is the *outermost* middleware
  and logs the full URL including query string at INFO. The
  `observabilityMiddleware` `_scrubPath` helper (line 87-109) only
  scrubs the breadcrumb path — it never touches what `logRequests`
  prints. So `/auth/callback?code=<oidc-code>&state=…` is logged
  verbatim to stdout, which is ingested by every container log
  pipeline. Same for `/lookups?cpf=<cpf>` if anyone misuses the query.
- **PoC**: Anyone with read access to the BFF container's stdout (k8s
  `kubectl logs`, Loki, datadog) can grep for `code=` to harvest
  authorization codes — usable within Zitadel's `code` TTL (~10 min) to
  exchange for tokens.
- **Impact**: OIDC code theft from log pipelines.
- **Remediation**: Replace `logRequests` with a custom middleware that
  strips the same `_sensitiveQueryParams` set, or move
  `observabilityMiddleware` to the outermost layer.

### MEDIUM (CVSS 4.0-6.9)

#### Finding 18 — No request-body size limit / no JSON depth limit

- **CVSS**: 6.5 (`AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H`)
- **CWE**: CWE-770 (Allocation of Resources Without Limits)
- **File:line**: `bff/social_care_web/lib/src/handlers/*` `_readJsonBody`
- **Vulnerability**: `request.readAsString()` reads the entire body into
  memory; `jsonDecode` recurses without depth caps. A 100 MB body or a
  `[[[[[…]]]]]` 10k-deep array DoSes the BFF process.
- **Remediation**: Wrap `readAsString` with a `take(1 MB)` guard;
  reject `Content-Length` > 1 MB up front; consider `package:json5`'s
  hardened parser.

#### Finding 19 — No rate limiting on `/auth/login`, `/auth/callback`, `/auth/refresh`, `/team/<id>/reset-password`

- **CVSS**: 6.5 (`AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H`)
- **CWE**: CWE-307 (Improper Restriction of Excessive Authentication Attempts),
  CWE-770
- **OWASP**: A04:2021
- **File:line**: `bff/social_care_web/lib/src/server/shelf_server.dart` — no
  rate-limit middleware in pipeline.
- **Vulnerability**: Brute-forcing OIDC state values (Finding 6),
  hammering `/team/<id>/reset-password` to mass-trigger Zitadel password
  reset emails (email-bomb the user), and replay-spamming `/auth/refresh`
  to keep stale sessions alive — all unbounded.
- **Remediation**: `package:shelf_rate_limiter` or upstream Caddy/Traefik
  policies; tighter on auth endpoints.

#### Finding 20 — Unsigned, unbound session cookie (no MAC, no rotation)

- **CVSS**: 6.5 (`AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:N/A:N`)
- **CWE**: CWE-798, CWE-565 (Reliance on Cookies without Validation and Integrity)
- **File:line**: `bff/social_care_web/lib/src/auth/session_store.dart:151-154`
- **Vulnerability**: `SessionStore._generateId()` produces a 64-hex-char
  ID. The cookie value is *that ID directly* — no HMAC, no encrypted
  envelope. This means a guess-the-id attack only requires brute-forcing
  the in-memory map. Also: `sessionSecret` (env-required) is never used
  anywhere — dead config. There is no signature to detect a tampered
  cookie or to rotate session IDs without server restart.
- **Impact**: With a sufficiently large attacker pool (botnet), session
  IDs are guessable in ~2^256 — astronomically safe today, but if the
  RNG seed ever degrades or the store is replaced with a predictable ID
  generator, the lack of HMAC means the system fails open.
- **Remediation**: Sign the cookie with `sessionSecret` (HMAC-SHA256
  truncated to 16 bytes appended), reject on signature mismatch,
  document `sessionSecret` rotation procedure. Add session ID rotation
  on privilege change.

#### Finding 21 — Stack-trace leakage in non-`BackendError` paths via `requestId`

- **CVSS**: 5.3 (`AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N`)
- **CWE**: CWE-209 (Generation of Error Message Containing Sensitive Information)
- **File:line**: `bff/social_care_web/lib/src/middleware/observability.dart:67-76`
- **Vulnerability**: The 500 response includes `requestId` so operators
  can correlate. Combined with `logRequests()` (Finding 17), an
  unauthenticated attacker who can compare a 500 `requestId` with the
  log line can confirm successful injection of weird payloads into the
  BFF (validation-induced exceptions are silenced, but cast errors etc.
  surface here).
- **Impact**: Information disclosure / oracle for fault injection.
- **Remediation**: Strip `requestId` from the body and ship it in a
  response header (`X-Request-Id`) only.

#### Finding 22 — Dio default `validateStatus: (_) => true` masks upstream 4xx in `_dispatch`

- **CVSS**: 5.4 (`AV:N/AC:H/PR:L/UI:N/S:U/C:N/I:H/A:N`)
- **CWE**: CWE-754
- **File:line**:
  - `bff/social_care_desktop/lib/src/remote/_shared/remote_base.dart:71`
  - `bff/social_care_web/lib/src/remote/social_care_api_client.dart` (every endpoint)
- **Vulnerability**: `Options(validateStatus: (_) => true)` makes every
  HTTP code a `Success` from Dio's perspective; the remote then maps to
  `Failure` only when `statusCode != 200/201/204`. Subtle: 3xx redirects
  are mapped to `_backendFailure(...)` with the *body of the redirect*
  (often empty / HTML), losing the original error context. The
  `ConflictResolver` then gets a `BackendError(http: 302, …)` and routes
  to `RetriableDecision` (since 302 < 400) — so any badly-configured
  upstream redirect causes infinite retry of the same Outbox row.
- **Impact**: Subtle DoS / desync between cache and backend.
- **Remediation**: `validateStatus: (s) => s != null && s < 500` and let
  Dio raise on 5xx; map redirects explicitly.

#### Finding 23 — Outbox poisoning via missing payload integrity check

- **CVSS**: 6.8 (already covered partly by Finding #9, also a logical
  flaw on its own).
- **CWE**: CWE-353 (Missing Support for Integrity Check)
- **File:line**: `bff/social_care_desktop/lib/src/sync/outbox/outbox_repository.dart:155-175`
- **Vulnerability**: `enqueue` writes `jsonEncode(mutation.toPayload())`
  with no signature. `_mapRow` (line 289-301) decodes it back; if the
  on-disk JSON is mutated, `SyncMutation.fromOutboxEntry` will happily
  build the typed mutation and dispatch it (most subclasses use
  `Request.fromJson(e.payload)` which throws on schema mismatch — but
  *value* tampering is invisible).
- **PoC**: Edit a pending `update_health_status` row to change
  `severityLevel` from `low` to `critical` while preserving the schema.
  On drain, the backend stores the tampered value.
- **Impact**: Data integrity loss in patient prontuários.
- **Remediation**: Append HMAC(payload, key-from-keychain) to a new
  `payloadMac` column; reject rows where the MAC doesn't match.

#### Finding 24 — `expectedVersion` forward-compat is a free input

- **CVSS**: 4.3 (`AV:N/AC:L/PR:L/UI:N/S:U/C:N/I:L/A:N`)
- **CWE**: CWE-639 (Authorization Bypass Through User-Controlled Key)
- **File:line**:
  - `bff/social_care_desktop/lib/src/sync/outbox/sync_mutation.dart:46-48`
  - `bff/social_care_desktop/lib/src/sync/_shared/tables/outbox_table.dart:39-42`
- **Vulnerability**: Optimistic-locking `expectedVersion` is provided by
  the use-case caller and persisted as-is. Once Vapor honours the
  field, an attacker tampering with the local `app_sync_queue.sqlite`
  can set `expectedVersion = INT_MAX` to bypass the conflict check
  (the backend will accept any current version <= MAX). Conversely,
  setting `expectedVersion = 0` always wins on row creation.
- **Impact**: Silent overwrite of concurrent updates from other
  users — once both sides honour the field, the field becomes a
  privilege-bypass primitive without integrity.
- **Remediation**: Treat `expectedVersion` as an *attestation* signed
  alongside payload (Finding 23). On drain, the backend re-validates the
  MAC; tampered versions are rejected with 409.

### LOW (CVSS <4.0)

#### Finding 25 — Health endpoints leak readiness signal without auth

- **CVSS**: 3.1
- **CWE**: CWE-200
- **File:line**: `bff/social_care_web/lib/src/server/app_router.dart:122-124,188-201`
- **Vulnerability**: `/health/live` and `/health/ready` always return 200
  with `{"status":"ok"}` without checking actual readiness (DB, Zitadel,
  Vapor). Useful for fingerprinting that the BFF is alive even when
  upstreams are down.
- **Remediation**: Wire real readiness probes (DB ping, JWKS reachability,
  Vapor ping) and return 503 when degraded.

#### Finding 26 — Public health probes use `Content-Type` without `charset=utf-8`

- **CVSS**: 2.0 (Cosmetic / minor)
- **CWE**: N/A
- **File:line**: `app_router.dart:191`
- **Remediation**: `application/json; charset=utf-8`.

#### Finding 27 — `dart_jsonwebtoken` declared but unused (supply-chain bloat)

- **CVSS**: 3.7 (`AV:N/AC:H/PR:N/UI:N/S:U/C:L/I:L/A:N`)
- **CWE**: CWE-1104 (Use of Unmaintained Third Party Components — caveat:
  not unmaintained, just unused).
- **File:line**: `bff/social_care_web/pubspec.yaml:29`
- **Vulnerability**: `dart_jsonwebtoken: ^3.0.0` is pinned with caret
  semantics (will accept `<4.0.0`) but is never imported in the
  production code we audited (the OIDC client rolls its own
  `parseIdTokenClaims` — see Finding 5). A future supply-chain attack
  on this package goes unnoticed because nobody is reviewing it for the
  BFF use case.
- **Remediation**: Either *use* it (preferred — fixes Finding 5) or
  remove it. Pin with `=` instead of `^` for security-critical deps,
  and run `dart pub outdated --mode=null-safety` in CI.

#### Finding 28 — `connectivity_plus` usage gates drain only on network changes — no manual fallback if offline at boot

- **CVSS**: 2.5
- **CWE**: CWE-754
- **File:line**: `bff/social_care_desktop/lib/src/facade/social_care_desktop.dart:646-655`
- **Vulnerability**: `_PumpingSyncEngine` drain only fires on the
  offline → online edge. If the laptop boots already online with stale
  pending mutations, the drain never fires until a network blip. Not a
  security bug per se, but increases the window during which the
  unencrypted Outbox holds sensitive data on disk (Finding 9 + 23).
- **Remediation**: Trigger an initial drain in `startSync()` if
  `_wasOnline = true`.

## Attack chain scenarios (creative attack composition)

### Scenario 1 — "Walking out the front door" (anonymous total takeover)

Pre-conditions: BFF Web reachable, Wave-N HTTP adapters not yet wired
(so Fake*Bff is active) — *exactly the current state*.

1. Attacker hits `https://bff.local/auth/callback?code=anything&state=anything`.
2. `FakeAuthBff.callback` returns Success → handler issues 302 with
   `Set-Cookie: __Host-session=<random uuid>`.
3. Attacker hits `/patients`, `/team`, `/lookups`, `/patients/<uuid>/audit-trail`.
4. `protectedPipeline` has no `authGuardMiddleware`; `sessionMiddleware`
   reads `__session=` (which is missing) and continues — the lack of a
   session is not a problem because the guard isn't installed. **Every
   protected route returns Fake* data with status 200.**
5. The moment any Fake* is replaced with a real adapter, the same
   anonymous attacker has direct access to live prontuários, write
   ops, and team-management surfaces — without ever talking to Zitadel.

### Scenario 2 — "Audit-trail laundromat"

Pre-conditions: Fix Findings 1-4 (real auth wired). Findings 12 + 6
remain.

1. Attacker (legitimate `social_worker_A`) logs in normally.
2. Attacker uses CSRF on a colleague (`social_worker_B`): emails them a
   link to `https://bff.local/auth/login?returnTo=/patients` (open
   redirect, finding 14) chained to `/auth/callback?code=<atk>&state=<atk>`
   (no state validation, finding 6). The colleague's browser now holds
   `social_worker_A`'s session cookie.
3. `social_worker_B` performs day-to-day work; every audit row is
   stamped with `social_worker_A`'s userId — but every action carries
   `social_worker_B`'s laptop fingerprints (IP, UA).
4. Result: when an LGPD subject requests an access log, the trail
   blames the wrong worker. Hard to detect, hard to undo.

### Scenario 3 — "Sleepwalking sync injection"

Pre-conditions: Desktop user logs in nightly. Attacker has filesystem
access (shared workstation, malware, lab PC).

1. Attacker waits for the desktop app to be closed (or kills it).
2. Attacker opens `app_sync_queue.sqlite` and inserts 50
   `report_violation` mutations naming children of patients in the
   cache as victims of fabricated abuse, with `expectedVersion = 0`.
3. User starts the app the next morning; `connectivity_plus` fires the
   online edge; `_PumpingSyncEngine.triggerDrain` picks up the rows;
   each `Result<StandardIdResponse>` succeeds because Vapor accepts
   them as legitimate (signed by the user's bearer token).
4. The user is now the audited author of 50 false reports against
   children — a serious legal liability and a denial-of-service against
   the protection workflow.

### Scenario 4 — "OIDC code harvest from logs"

Pre-conditions: BFF logs collected to k8s/Loki; observer has read-only
log access (junior SRE, stolen log credentials).

1. `shelf.logRequests()` (Finding 17) writes
   `GET /auth/callback?code=<oidc-code>&state=<state> 302` to stdout.
2. Observer greps `code=` within the Zitadel code-TTL window (~10 min).
3. Observer hits Zitadel's `/oauth/v2/token` directly with the harvested
   code + the leaked client secret (Finding 8) and gets a fresh access
   + refresh token pair.
4. Observer impersonates the user from any host — no XSS / no MITM
   needed.

## ACDG-specific predictions

### Healthcare data exfiltration paths

- **Cache scrape** (Desktop, Finding 9): `sqlite3 app_cache.sqlite
  '.dump patient_summaries'` → JSON-encoded `PatientResponse` records
  with CPF, NIS, CNS, RG, address, and the full clinical picture.
- **Anonymous list** (Finding 1): `curl /patients?limit=10000` returns
  paginated summaries, then `curl /patients/<id>` for each, then
  `curl /patients/<id>/audit-trail` to reconstruct the change history
  including caregiver names.
- **Lookup table walk** (Finding 15): `curl /lookups/dominio_diagnosticos`
  enumerates every CID code the system tracks (including rare-disease
  identifiers — itself an LGPD-sensitive list).

### Iron-Frontier breaches (BFF → browser leakage)

- **Bearer in `Set-Cookie` headers**: not currently happening. ✅
- **`me` endpoint** (`/auth/me`) exposes `userId`, `email`, `fullName`,
  and `roles`. Combined with Finding 4 (FakeAuthBff hardcoded user), a
  breach of `/auth/me` over the unauthenticated edge today is "fake user"
  — but once real, it's a fingerprint of every Zitadel role assignment.
- **CORS+credentials** (Finding 16) with a misconfigured
  `FRONTEND_ORIGIN` opens reflective theft of `__Host-session` to any
  origin — and the cookie value, while opaque, is the live keys to the
  kingdom (Findings 1-3).

### Offline DB tampering (desktop)

- **Mutation injection** (Finding 9, Finding 23): see Scenario 3.
- **Cache poisoning**: Editing `patient_summaries.payload` to swap
  `firstName` between two patients causes a `social_worker` to
  unknowingly write a `update_health_status` against the wrong patient.
  When the user reads the same row from cache before the next refresh,
  the swap looks legitimate.
- **Outbox replay**: `attemptCount` and `status` are user-modifiable.
  Setting `status = 'pending'` on a `completed` row replays any past
  mutation — potentially `dischargePatient` of an active patient,
  causing a clinical disruption.

## Defense-in-depth gaps (things that should exist but don't)

1. **CSP headers** — no Content-Security-Policy, X-Content-Type-Options,
   X-Frame-Options, Referrer-Policy, or Permissions-Policy on any BFF
   response. The BFF is exclusively API + redirects, but the OIDC
   redirect step (302 to Zitadel) and any future SSR error pages need
   these.
2. **HSTS** — same. (Likely terminated at Caddy upstream — verify.)
3. **`X-Requested-With` enforcement** — accepted in CORS preflight, but
   no middleware refuses a state-changing POST that lacks the header.
4. **`Sec-Fetch-Site` validation** — not enforced anywhere in the
   audited surface.
5. **Per-IP / per-user rate limits**.
6. **MFA enforcement at the BFF edge** for sensitive operations
   (team `reset-password`, `withdraw_patient`).
7. **Drift database encryption** (Finding 9).
8. **Outbox row HMAC** (Finding 23).
9. **JWKS-backed JWT verification** (Finding 5).
10. **`sessionSecret` actually used** to sign cookies (Finding 20).
11. **Audit-log immutability**: `actorId` derived from session
    (Finding 12) + log shipped append-only off-host.

## Concrete recommendations for A19/A20/A21

Ordered by exploitability × impact:

1. **A19-W1 — wire real auth pipeline.** Replace `FakeAuthBff` with a
   real `OidcAuthBff` that uses `OidcServerClient` + `SessionStore`.
   Add `authGuardMiddleware()` to `protectedPipeline`. Standardise the
   cookie name (`__Host-session`) across handler + middleware + tests.
   Implement `state` + PKCE-verifier server-side store with 5-min TTL.
   *(Findings 1, 2, 3, 4, 6, 7.)*
2. **A19-W2 — verify OIDC tokens.** Replace `parseIdTokenClaims` with
   `dart_jsonwebtoken` + JWKS fetch + verify `iss`, `aud`, `exp`.
   *(Finding 5.)*
3. **A19-W3 — secret hygiene.** Rotate the leaked client secret; pull
   secrets from Bitwarden in the dev loop; add `bff/**/.env` to
   top-level `.dockerignore` and `gitleaks` to CI.
   *(Finding 8.)*
4. **A20-W0 — actor identity from session.** Refactor `RemoteBase.buildDio`
   + `SocialCareApiClient` + `PeopleContextClient` to take an
   `ActorIdProvider` closure. Plumb a `Zone`-scoped `Session` into
   the closure inside the request handler. *(Findings 12, 13.)*
5. **A20-W1 — Drift encryption + Outbox HMAC.** Switch to
   `sqlcipher_flutter_libs`; key from OS Keychain; HMAC `outbox.payload`
   + `expectedVersion`. Reject corrupted rows fail-closed.
   *(Findings 9, 23, 24.)*
6. **A20-W2 — strict input validation at the edge.** Add a smart
   constructor for `LookupTableName`, validate `LoginIntent.returnTo`
   against an allow-list, cap request body sizes (1 MB), depth-limit
   `jsonDecode`. *(Findings 14, 15, 18.)*
7. **A21-W0 — observability hardening.** Replace `shelf.logRequests` with
   a scrubbing variant; move `requestId` to a response header; add a
   structured log redaction pass for cookies + Authorization. Wire
   readiness checks into `/health/ready`. *(Findings 17, 21, 25.)*
8. **A21-W1 — CORS hardening.** Validate the request `Origin` header
   against an allow-list; reject `*` in `ServerConfig`; add `Vary:
   Origin`. *(Finding 16.)*
9. **A21-W2 — rate limits + MFA hooks.** `package:shelf_rate_limiter`
   per-IP per-route on `/auth/*` and `/team/*/reset-password`; add an
   `RequiresMfa` middleware that re-checks Zitadel for an `amr` claim
   before sensitive ops. *(Finding 19.)*
10. **A21-W3 — session lifecycle.** Wire `LogoutUseCase` →
    `sessionStore.destroy(...)`; `RefreshUseCase` →
    `sessionStore.updateTokens(...)` + cookie rotation. Sign cookies
    with `sessionSecret`. *(Findings 10, 20.)*

Suggested complementary tooling:

- **gitleaks** in pre-commit + CI to catch future `.env` leaks.
- **OWASP Dependency-Check / `dart pub outdated --mode=null-safety`**
  weekly.
- **Trivy** scan on every Docker image (BFF Web container).
- **OWASP ZAP** baseline scan against a deployed BFF Web instance once
  the auth flow is real.
- **Burp Suite** session-tracking mode for manual chain testing of
  Findings 6 + 14 once the redirect path is live.
