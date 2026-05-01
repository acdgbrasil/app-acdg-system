# API Security Audit — BFF Comprehensive (2026-05-01)

> Read-only audit. Cites file:line for every finding. CVSS-style severity rationale per finding.

## Executive summary

- **Security posture:** **CRITICAL**
- **Total findings:** 6 CRITICAL, 9 MAJOR, 7 MINOR (22 total)
- **Top-3 (CVSS-weighted):**
  1. **AUTH-BYPASS** — `authGuardMiddleware` is implemented but NEVER registered in the protected pipeline. All `/patients/*`, `/team/*`, `/lookups/*`, `/lookup-requests/*`, `/auth/me`, `/auth/refresh` are reachable without any cookie. (CVSS ~9.8)
  2. **SESSION-COOKIE-MISMATCH** — Session middleware reads `__session` while `AuthHandler` writes `__Host-session`. Authenticated callers can never have their session resolved by the middleware. (CVSS ~9.0; combined with #1 it converts the entire app into an open API)
  3. **NO-SECURITY-HEADERS** — Zero security headers are emitted anywhere in the BFF Web stack: no HSTS, no CSP, no X-Content-Type-Options, no X-Frame-Options, no Referrer-Policy. (CVSS ~7.5)

## Methodology

- **Skill:** `api-security-guardian` (8 dimensions)
- **Files audited:** ~140 source `.dart` files (excluding tests, generated `.g.dart`, `.drift.dart`, `.dart_tool/`)
- **In scope:** `bff/social_care_web/`, `bff/social_care_desktop/`, `bff/shared/`
- **Out of scope:** `apps/`, `packages/` (Phase 4)
- **Public attack surface:** `bff/social_care_web/` (HTTP, Shelf, network-exposed)
- **Trust-internal:** `bff/social_care_desktop/` (in-process Dart facade), `bff/shared/` (DTO/contract/domain library)

## API surface map (Web BFF)

| Method | Path | Auth required (intent) | Auth enforced (reality) | Body validated | UUID validated | Notes |
|---|---|---|---|---|---|---|
| GET | `/health/live` | no | no | n/a | n/a | OK |
| GET | `/health/ready` | no | no | n/a | n/a | OK |
| GET | `/auth/login` | no | no | n/a | n/a | No PKCE verifier persistence (see #4) |
| GET | `/auth/callback` | no | no | query parsed | n/a | No state nonce validation (see #4) |
| POST | `/auth/logout` | no | no | n/a | n/a | Idempotent, OK |
| GET | `/auth/me` | yes | **NO** | n/a | n/a | Reads cookie ad-hoc (`__Host-session`) |
| POST | `/auth/refresh` | yes | **NO** | n/a | n/a | Reads cookie ad-hoc (`__Host-session`) |
| POST | `/patients` | yes | **NO** | partial (P2 if-case) | n/a | `DiagnosisDraftDto.fromJson` not in try/catch (see #6) |
| GET | `/patients` | yes | **NO** | n/a | n/a | `limit` unbounded (see #7) |
| GET | `/patients/<id>` | yes | **NO** | n/a | yes | OK |
| POST | `/patients/<id>/admit` | yes | **NO** | yes | yes | OK |
| POST | `/patients/<id>/discharge` | yes | **NO** | yes | yes | OK |
| POST | `/patients/<id>/readmit` | yes | **NO** | yes | yes | OK |
| POST | `/patients/<id>/withdraw` | yes | **NO** | yes | yes | OK |
| POST | `/patients/<id>/family-members` | yes | **NO** | yes | yes | CPF forwarded raw, no checksum (see #11) |
| DELETE | `/patients/<id>/family-members/<mid>` | yes | **NO** | n/a | yes | OK |
| PUT | `/patients/<id>/primary-caregiver` | yes | **NO** | yes | yes | OK |
| PUT | `/patients/<id>/social-identity` | yes | **NO** | yes | yes | OK |
| GET | `/patients/<id>/audit-trail` | yes | **NO** | n/a | yes | `limit/offset` unbounded |
| PUT | `/patients/<id>/housing-condition` | yes | **NO** | P2b try/catch | yes | OK |
| PUT | `/patients/<id>/socio-economic-situation` | yes | **NO** | P2b try/catch | yes | OK |
| PUT | `/patients/<id>/work-and-income` | yes | **NO** | P2b try/catch | yes | OK |
| PUT | `/patients/<id>/educational-status` | yes | **NO** | P2b try/catch | yes | OK |
| PUT | `/patients/<id>/health-status` | yes | **NO** | P2b try/catch | yes | OK |
| PUT | `/patients/<id>/community-support-network` | yes | **NO** | P2b try/catch | yes | OK |
| PUT | `/patients/<id>/social-health-summary` | yes | **NO** | P2b try/catch | yes | OK |
| POST | `/patients/<id>/appointments` | yes | **NO** | yes | yes | OK |
| PUT | `/patients/<id>/intake-info` | yes | **NO** | yes | yes | OK |
| POST | `/patients/<id>/referrals` | yes | **NO** | yes | yes | OK |
| POST | `/patients/<id>/violations` | yes | **NO** | yes | yes | OK |
| PUT | `/patients/<id>/placement-history` | yes | **NO** | P2b try/catch | yes | OK |
| GET | `/lookups` | yes | **NO** | n/a | n/a | Query-bounded, OK |
| GET | `/lookups/<tableName>` | yes | **NO** | n/a | **no allowlist** | `tableName` not validated (see #8) |
| POST | `/lookups/<tableName>` | yes | **NO** | yes | n/a | Same `tableName` issue |
| PUT | `/lookups/<tableName>/<id>` | yes | **NO** | yes | yes | Same `tableName` issue |
| PATCH | `/lookups/<tableName>/<id>/toggle` | yes | **NO** | yes | yes | Same `tableName` issue |
| GET | `/lookup-requests` | yes | **NO** | n/a | n/a | OK |
| POST | `/lookup-requests` | yes | **NO** | yes | n/a | OK |
| PUT | `/lookup-requests/<id>/approve` | yes | **NO** | n/a | yes | OK |
| PUT | `/lookup-requests/<id>/reject` | yes | **NO** | n/a | yes | OK |
| GET | `/team` | yes | **NO** | n/a | n/a | Filters bounded, OK |
| POST | `/team` | yes | **NO** | yes | n/a | `initialPassword` forwarded raw, no strength check (see #12) |
| GET | `/team/<id>` | yes | **NO** | n/a | yes | OK |
| PUT | `/team/<id>/deactivate` | yes | **NO** | n/a | yes | OK |
| PUT | `/team/<id>/reactivate` | yes | **NO** | n/a | yes | OK |
| POST | `/team/<id>/reset-password` | yes | **NO** | n/a | yes | No rate limit on this sensitive op (see #9) |
| POST | `/team/<id>/roles` | yes | **NO** | yes | yes | OK |
| PUT | `/team/<id>/roles/<rid>/deactivate` | yes | **NO** | n/a | yes | OK |
| PUT | `/team/<id>/roles/<rid>/reactivate` | yes | **NO** | n/a | yes | OK |

**51 endpoints, 41 of which require auth in intent but none actually enforce it in production.**

## Findings (by dimension)

---

### Dimension 1 — Input validation

#### #6 [MAJOR] `RegisterPatientIntent.parseFromBody` does not wrap `fromJson` in try/catch — partial P2 coverage

- **CVSS:** 5.5 (PII exposure low; primary impact is unhandled `TypeError` → 500 instead of clean 400)
- **File:** `bff/social_care_web/lib/src/intents/register_patient_intent.dart:55-81`
- **Evidence:** Lines 55-60 call `DiagnosisDraftDto.fromJson(e as Map<String, dynamic>)` inside `_parseDiagnoses`. The generated `_$DiagnosisDraftDtoFromJson` (`bff/shared/lib/src/contract/dto/requests/registry/register_patient_request.g.dart:49-54`) performs raw casts: `json['icdCode'] as String`, `json['date'] as String`. Passing `null` or wrong-typed values triggers a `TypeError`. No try/catch.
- **Impact:** A malformed `POST /patients` body where `initialDiagnoses[0].icdCode` is missing crashes the parser and surfaces as a generic 500 (caught by `observabilityMiddleware` line 56-67) instead of a structured 400 `INVALID_REGISTER_BODY`. Exception messages (with potential PII fragments) are written to the logger via `obs.logError` (line 58-62 of `observability.dart`).
- **Skill alignment:** `RegisterPatientRequest` has 7+ fields including PII-dense sub-DTOs (`PersonalDataDraftDto`, `CivilDocumentsDraftDto`) — per skill canon §P2b, this should use `try/catch` over `fromJson`.
- **Remediation:** Mirror the `update_placement_history_intent.dart:53-76` P2b pattern — wrap `RegisterPatientRequest.fromJson(body)` in try/catch and emit a constant PII-safe failure message.

#### #7 [MAJOR] Unbounded `limit` on `GET /patients` and `GET /patients/<id>/audit-trail`

- **CVSS:** 6.0 (DoS / data exfiltration vector)
- **Files:**
  - `bff/social_care_web/lib/src/intents/list_patients_intent.dart:51-54` — `int.tryParse(raw.trim())` with no upper bound
  - `bff/social_care_web/lib/src/remote/social_care_api_client.dart:125` — defaults to 20 if absent but accepts any caller-supplied value
  - `bff/social_care_desktop/lib/src/remote/registry_remote.dart:30` — defaults to 100, no cap
- **Impact:** Caller can request `limit=999999999`. If the upstream backend respects the value, returning the full patient list to a logged-out user (since auth is bypassed, see #1) becomes a one-shot data exfiltration of every patient in the system.
- **Remediation:** Cap `limit` server-side at ≤100 in both BFFs. Reject (or silently clamp) values above the cap.

#### #8 [MAJOR] `tableName` path parameter accepted without allowlist on every `/lookups/*` endpoint

- **CVSS:** 5.5 (path forgery / upstream-validation bypass)
- **File:** `bff/social_care_web/lib/src/handlers/lookup_handler.dart:153-170`, `intents/get_lookup_table_intent.dart:7-14`
- **Evidence:** `GetLookupTableIntent` carries `tableName` as a free-form string, forwarded into `dio.get('/api/v1/dominios/$tableName')` (`social_care_api_client.dart:680`). No allowlist regex, no sanity check.
- **Impact:** Caller can probe unknown table names, attempt path manipulation (`tableName=requests/../patients`), or scan the upstream API surface. Dio URL-encodes path segments so escape-via-slash is mitigated, but the BFF should fail fast on unknown table names per ACDG defense-in-depth canon. The skill explicitly calls this out: "Validacao de dominio no BFF DEVE acontecer ANTES de proxiar ao backend."
- **Remediation:** Add an allowlist (`Set<String> _knownDominioTables`) and reject anything not in it with `INVALID_LOOKUP_TABLE_NAME`.

#### #11 [MAJOR] CPF forwarded raw — no domain validation in BFF before proxying

- **CVSS:** 5.0 (defense-in-depth gap; data quality / LGPD)
- **Files:**
  - `bff/social_care_web/lib/src/intents/add_family_member_intent.dart:94` — `cpf: _asNullableString(body['cpf'])`
  - `bff/social_care_web/lib/src/intents/register_worker_intent.dart:61` — `cpf: _asString(body['cpf'])`
  - `bff/social_care_web/lib/src/intents/register_patient_intent.dart:78-80` (delegates to `CivilDocumentsDraftDto.fromJson` which has no validation)
- **Evidence:** A working `Cpf.create` smart constructor exists in `bff/shared/lib/src/domain/kernel/cpf.dart:56` with mod-11 checksum, but it is **never called** by the live BFF Web request path. The only callers are tests + `bff/shared/lib/src/infrastructure/mappers/registry_mapper.dart:129` (a translator helper exported but not wired to handlers/use cases — confirmed by grep over `lib/`).
- **Impact:** A malformed CPF reaches the upstream backend, where validation occurs. This violates the ACDG architecture canon ("validation in BFF ANTES de proxiar") and pushes data-quality errors deeper into the stack, increasing observability noise and slow-feedback for clients.
- **Skill alignment:** Skill §"Domain Validation no BFF (Result Pattern)" — this is a direct miss.
- **Remediation:** Pipe `body['cpf']` through `Cpf.create` in each intent and surface `Failure(...)` as 400 BEFORE forwarding. **Caveat:** if you do this, also fix #10 first because the current `Cpf.create` failure message echoes the raw CPF.

#### #12 [MINOR] `initialPassword` forwarded raw without strength check

- **CVSS:** 4.0 (weak-credential admission)
- **File:** `bff/social_care_web/lib/src/intents/register_worker_intent.dart:62`
- **Evidence:** `initialPassword: _asString(body['initialPassword'])` — no length/complexity check.
- **Impact:** Admin can register a worker with `initialPassword = "1"`. Backend may reject, but BFF should fail-fast.
- **Remediation:** Minimum 12 characters, mixed character classes, plus deny-list of common passwords. PII rule: NEVER echo the password in a parse error message.

#### #20 [MINOR] Body size not capped — Shelf has no built-in body limit middleware

- **CVSS:** 4.5 (DoS via large payload)
- **File:** `bff/social_care_web/lib/src/server/shelf_server.dart:32-46` (no body-limit middleware)
- **Impact:** Caller can `POST /patients` with a 100MB JSON body; `request.readAsString()` (e.g., `registry_patient_handler.dart:296`) buffers the entire body before parsing.
- **Remediation:** Add a body-size middleware that streams `request.read()` with a hard cap (e.g., 1MB for JSON, 10MB for any future file uploads) and rejects with 413.

---

### Dimension 2 — Output encoding

#### #10 [CRITICAL] Smart-constructor failure messages echo raw CPF / NIS into AppError.message — PII leak vector

- **CVSS:** 8.5 (LGPD violation if these errors propagate to logs or HTTP responses)
- **Files:**
  - `bff/shared/lib/src/domain/kernel/cpf.dart:64, 78, 87, 96` — raw CPF interpolated into `AppError.message` for codes CPF-002, CPF-003, CPF-004, CPF-005
  - `bff/shared/lib/src/domain/kernel/nis.dart:31, 40, 49` — same pattern with raw NIS
- **Evidence:** Example: `_buildError('CPF-005', "O CPF '$trimmed' contém caracteres inválidos.")` — `$trimmed` is the caller-supplied string, possibly containing a real CPF.
- **Impact:** If `Cpf.create`/`Nis.create` is ever wired to a hot request path (as recommended by #11), every invalid-CPF attempt logs the raw CPF via `obs.logError` and may surface in error responses if the handler echoes `error.toString()`. This is a textbook LGPD violation for healthcare data.
- **Discovery is dormant:** today these constructors are only invoked from `infrastructure/mappers/registry_mapper.dart` and `patient_translator.dart`, both **not currently wired to a live HTTP path** (confirmed by grep — only tests + the dormant translator). But the loaded gun is sitting on the table waiting for Phase-4 to wire it.
- **Remediation:** Strip raw CPF/NIS from the message: replace with PII-safe text like `"CPF format invalid"` and put the raw value (if needed for diagnostics) ONLY in `safeContext` with a documented sanitization layer above the logger.

#### #14 [MINOR] `_extractError` catch-all returns 500 INTERNAL but `obs.logError` records raw exception with stack — log destination determines blast radius

- **CVSS:** 4.5 (information leak via logs, dependent on retention/access)
- **Files:**
  - `bff/social_care_web/lib/src/middleware/observability.dart:56-77` — catches all and `obs.logError('unhandled exception in pipeline', cause: error, stack: stack)`
  - `bff/social_care_web/lib/src/observability/observability_context.dart:127-129` — `Logger.root.severe('$message requestId=$requestId', cause, stack)`
- **Impact:** Stack traces and exception messages (which may include PII fragments from #10 if Cpf.create is wired) end up in logs verbatim. Whether this is a real leak depends on log retention/PII policies.
- **Remediation:** Sanitize log entries that touch domain VO errors; or document the log destination and access control as part of the LGPD register.

#### #15 [MINOR] `BackendError.stackTrace` is JSON-serialized via `toJson()` — never echoed today, but reactivation risk

- **CVSS:** 3.5 (latent risk only)
- **File:** `bff/shared/lib/src/contract/dto/shared/backend_error.dart:43, 60` — `stackTrace` is part of `props` and serialized to JSON
- **Status:** All current handlers extract `(http, code, message)` only via `_extractError(...)` (see e.g., `team_handler.dart:357-364`), so `stackTrace` is never emitted. The dead helper `bff/social_care_web/lib/src/handlers/handler_utils.dart:48-66` (`backendError`) DOES `jsonEncode(error.toJson())` — including the stack — but is unused.
- **Remediation:** Delete the dead `backendError` helper, OR make it strip `stackTrace` defensively. Document that `BackendError.stackTrace` MUST stay server-side.

---

### Dimension 3 — Authentication boundaries

#### #1 [CRITICAL] `authGuardMiddleware` is not registered in `protectedPipeline` — auth bypass on every protected route

- **CVSS:** 9.8 (exploitable from any unauthenticated client; affects 41 endpoints)
- **Files:**
  - `bff/social_care_web/lib/src/server/app_router.dart:173-176` — `protectedPipeline` has only `observabilityMiddleware` + `sessionMiddleware`. **No `authGuardMiddleware`.**
  - `bff/social_care_web/lib/src/middleware/auth_guard_middleware.dart:11-28` — middleware exists, returns 401 when session missing, but is never wired
  - The doc-comment on `app_router.dart:75-82` even claims "auth guard middleware rejects requests with no session on protected routes" — this is **factually false**.
- **Impact:** Every protected endpoint (51 routes minus health + auth = 41) is reachable by any unauthenticated client. Combined with #2 (cookie mismatch), there is no realistic path to add auth back without code changes.
- **Remediation:** Add `.addMiddleware(authGuardMiddleware())` between `sessionMiddleware` and the cascade in `app_router.dart`.

#### #2 [CRITICAL] Session cookie name mismatch: `__session` vs `__Host-session` — sessions are never resolved

- **CVSS:** 9.0 (high if #1 is fixed; today it just compounds the bypass)
- **Files:**
  - `bff/social_care_web/lib/src/middleware/session_middleware.dart:48-49` — reads `__session=...`
  - `bff/social_care_web/lib/src/handlers/auth_handler.dart:21` — `const String _sessionCookieName = '__Host-session'`
  - `bff/social_care_web/lib/src/handlers/auth_handler.dart:222-223` — `Set-Cookie: __Host-session=$sessionId; Path=/; HttpOnly; Secure; SameSite=Strict`
  - Confirmed by tests `bff/social_care_web/test/middleware/session_middleware_test.dart:71` — middleware tests assert `__session=...` (the legacy name)
- **Evidence:** `AuthHandler._handleMe` and `_handleRefresh` read the cookie ad-hoc using the correct name `__Host-session` — but they don't run through `sessionMiddleware`, so they bypass the broken middleware. Any handler that relies on `request.context[sessionContextKey]` (e.g., the dead `health_handler.dart:31`) would see `null` even with a valid `__Host-session` cookie.
- **Impact:** The intended secure-cookie design is half-built. After fixing #1, sessions still won't resolve until #2 is also fixed.
- **Remediation:** Rename `__session` → `__Host-session` in `session_middleware.dart:48-49` and update tests.

#### #4 [CRITICAL] OIDC PKCE / state nonce never persisted between login → callback

- **CVSS:** 8.5 (CSRF in the OAuth callback, code-replay)
- **Files:**
  - `bff/social_care_web/lib/src/auth/oidc_server_client.dart:72-92` — `buildAuthorizationUrl` takes a `codeVerifier` param
  - `bff/social_care_web/lib/src/auth/oidc_server_client.dart:99-117` — `exchangeCode` requires the same `codeVerifier`
  - **No production caller** of `OidcServerClient.buildAuthorizationUrl` or `exchangeCode` exists in the live wiring. The `LoginUseCase` and `AuthCallbackUseCase` route through the abstract `AuthContract`, and the only impl wired is `FakeAuthBff` (`bin/server.dart:21`).
  - `bff/shared/lib/src/testing/fake_auth_bff.dart:42-48` — `login()` returns a hardcoded URL; `callback()` returns `Success` for ANY `code`/`state`.
- **Impact:** No PKCE verifier store exists. No state nonce store exists. If/when the real OIDC adapter is wired (skill: "PKCE verifiers: TTL 5min, max 1000 entries, sweep on login()"), the BFF will need stateful storage that today does not exist. As-shipped, the OIDC callback is wide-open: `GET /auth/callback?code=anything&state=anything` lands a random session UUID via `auth_handler.dart:117-122`.
- **Remediation:** Implement an in-memory `PkceStore` keyed by `state` with TTL 5min and max 1000 entries (per skill canon). Wire it from `LoginUseCase` (write) and `AuthCallbackUseCase` (read+delete).

#### #16 [MINOR] `OidcServerClient.parseIdTokenClaims` skips signature verification

- **CVSS:** 4.5 (mitigated by HTTPS to token endpoint, but skill canon says JWKS validate)
- **File:** `bff/social_care_web/lib/src/auth/oidc_server_client.dart:148-163`
- **Evidence:** Comment "BFF trusts its own token endpoint response received over HTTPS, so no signature verification is needed."
- **Skill alignment:** Skill §"Authentication & API Keys" + Vapor backend pattern requires JWKS validation. The argument is reasonable for the BFF when speaking directly to the IdP token endpoint, but documenting and pinning the IdP TLS certificate is recommended.
- **Remediation:** Either wire JWT/JWKS validation OR document the threat model (TLS pinning, etc.) explicitly in the handbook.

---

### Dimension 4 — Rate limiting

#### #9 [MAJOR] Zero rate limiting anywhere — including login, callback, refresh, and reset-password

- **CVSS:** 6.5 (brute force / DoS against auth flows + sensitive admin operations)
- **Files:**
  - `bff/social_care_web/lib/src/server/shelf_server.dart:32-46` — only `logRequests()` and conditionally `corsMiddleware` are in the chain. No rate-limit middleware.
  - `bff/social_care_web/lib/src/handlers/team_handler.dart:218` — `POST /team/<id>/reset-password` is unguarded
  - `bff/social_care_web/lib/src/handlers/auth_handler.dart:60-65` — login/callback/refresh have no per-endpoint limits
- **Impact:** Attacker can brute-force valid `state` values on `/auth/callback`; can mass-trigger `reset-password` for every team member to spam emails; can DoS `/auth/refresh`.
- **Remediation:** Add a `shelf_limiter` middleware: global cap (e.g., 100 req/min/IP), tighter cap on `/auth/*` (e.g., 10 req/min/IP), and even tighter on `/team/<id>/reset-password` (e.g., 3 req/min/actor).

---

### Dimension 5 — CORS

#### #5 [MAJOR] CORS preflight returns `Allow-Origin` echoing config but `Allow-Methods: GET, POST, PUT, DELETE, OPTIONS` is permissive and `Access-Control-Allow-Credentials: true` requires strict origin matching

- **CVSS:** 5.5 (cross-origin abuse if `frontendOrigin` is misconfigured)
- **File:** `bff/social_care_web/lib/src/middleware/cors_middleware.dart:21-27`
- **Evidence:**
  - `Access-Control-Allow-Origin: $origin` where `$origin` is `config.frontendOrigin` from env — single value, not a list. OK.
  - `Access-Control-Allow-Credentials: true` combined with `Access-Control-Allow-Headers: Content-Type, X-Requested-With` — OK structurally.
  - **However:** if `FRONTEND_ORIGIN=*` is ever set via env (typo, debug), the wildcard combined with credentials is a textbook misconfiguration.
- **Impact:** Misconfiguration trap; not exploitable today if env is correct.
- **Remediation:** Reject `*` explicitly when reading the env var. Add a unit test that validates the origin string is a well-formed scheme+host+port URL.

#### #21 [MINOR] Preflight (`OPTIONS`) returns 200 with body `''` — should be 204

- **CVSS:** 2.0 (HTTP correctness; not a vuln)
- **File:** `bff/social_care_web/lib/src/middleware/cors_middleware.dart:11-13`
- **Remediation:** Use `Response(204)` for preflight responses.

---

### Dimension 6 — Security headers

#### #3 [CRITICAL] No security headers anywhere — HSTS, CSP, X-Content-Type-Options, X-Frame-Options, Referrer-Policy all absent

- **CVSS:** 7.5 (clickjacking, MIME sniffing, insecure transport, supply-chain XSS)
- **Files:** Confirmed by grep `Strict-Transport-Security|Content-Security-Policy|X-Content-Type-Options|X-Frame-Options|Referrer-Policy|nosniff` over the entire `bff/` tree — **zero matches** in source. The shelf pipeline at `bff/social_care_web/lib/src/server/shelf_server.dart:32-46` does not install any header middleware.
- **Impact:** Although the BFF is API-only (no SSR HTML today), the Flutter web app's BFF MUST emit HSTS for transport security and `X-Content-Type-Options: nosniff` for response-content-type discipline. The skill canon explicitly requires:
  - HSTS `max-age=31536000; includeSubDomains`
  - CSP with nonce per request
  - `X-Frame-Options: DENY`
  - `Referrer-Policy: strict-origin-when-cross-origin`
- **Remediation:** Add a `securityHeadersMiddleware` to the pipeline as the OUTERMOST middleware so even error responses emit headers. CSP nonce is irrelevant for pure-API responses (no HTML), but if the BFF later serves any HTML (login page, error page) the nonce middleware is mandatory.

#### #18 [MINOR] No `Cache-Control: no-store` on responses carrying patient data

- **CVSS:** 3.5 (sensitive data caching)
- **Files:** All `_jsonHeaders` constants across handlers (e.g., `team_handler.dart:305-307`) include only `content-type: application/json`.
- **Impact:** Intermediate caches / browser back-forward cache may persist patient-PII responses. ACDG canon (skill: "Cache-Control on sensitive data") requires `no-store`.
- **Remediation:** Add `Cache-Control: no-store, no-cache, must-revalidate` and `Pragma: no-cache` to every JSON response. Best done via a response middleware.

---

### Dimension 7 — Error handling

#### #13 [MAJOR] Dead helper `handler_utils.backendError` JSON-encodes the full `BackendErrorResponse` including `stackTrace`

- **CVSS:** 5.5 (latent — unused today, but reactivation lethal)
- **File:** `bff/social_care_web/lib/src/handlers/handler_utils.dart:48-66`
- **Evidence:** `body: jsonEncode(error.toJson())` directly serializes `error.stackTrace` and `error.cause` to the network response.
- **Impact:** If any new handler imports `backendError` (the symbol still exists and is exported in spirit by being public top-level), it will instantly leak stack traces.
- **Remediation:** Delete this function. The 8 handlers each have their own `_extractError` that correctly drops `stackTrace`/`cause`.

#### #17 [MINOR] `getSession(request)` will crash with `TypeError` if the session is null

- **CVSS:** 3.5 (DoS / unhandled exception path)
- **File:** `bff/social_care_web/lib/src/handlers/handler_utils.dart:17-18`
- **Evidence:** `request.context[sessionContextKey] as Session` — unconditional cast. Comment claims "Auth guard middleware ensures this is never null" but no guard is wired (#1).
- **Status:** Only used by the dead `health_handler.dart:31, 42`. So real-world impact today is zero.
- **Remediation:** Either delete `health_handler.dart` (dead — confirmed inline `_liveHandler/_readyHandler` in `app_router.dart:188-201` are used instead) OR fix `getSession` to return `Session?` and let callers handle null.

---

### Dimension 8 — Abuse protection / CSRF / Fetch Metadata

#### #19 [CRITICAL] No `X-Requested-With: XMLHttpRequest` validation on state-changing endpoints — CSRF protection missing

- **CVSS:** 7.5 (CSRF-with-credentials when SameSite=Strict edge cases apply)
- **File:** Confirmed by grep — `X-Requested-With` appears only in `cors_middleware.dart:24` (allow-list) and in the desktop client's request headers. No middleware validates that POST/PUT/DELETE requests carry it.
- **Skill alignment:** Skill canon §"X-Requested-With CSRF Protection" requires this on `/api/*`. ACDG canon explicitly mandates: "POST/PUT/DELETE ao BFF devem incluir X-Requested-With".
- **Impact:** Although the session cookie is `SameSite=Strict` (auth_handler.dart:223), some browsers send cookies on top-level form submissions. Without `X-Requested-With` enforcement, a malicious cross-site form `POST /patients/<known-uuid>/withdraw` could ride the user's session.
- **Remediation:** Add a `csrfMiddleware` that rejects POST/PUT/DELETE/PATCH on protected routes when `X-Requested-With != 'XMLHttpRequest'`.

#### #22 [MAJOR] No `Sec-Fetch-Site` validation — Fetch Metadata API ignored

- **CVSS:** 6.0 (defense-in-depth gap)
- **File:** Confirmed by grep — `Sec-Fetch-Site` is never inspected anywhere in the BFF.
- **Skill alignment:** Skill §"Fetch Metadata Validation (BFF)" — required on `/api/*` (mapped to Web BFF protected pipeline here).
- **Impact:** Cross-origin requests are not rejected pre-CORS, increasing the available CSRF surface.
- **Remediation:** Add a `fetchMetadataMiddleware` that rejects requests where `Sec-Fetch-Site` is `cross-site` and the path is in the protected pipeline.

#### #23 [MAJOR] IDOR risk on every `/patients/<id>/...` and `/team/<id>/...` route — UUID is validated, but no actor-vs-resource ownership check

- **CVSS:** 6.5 (assuming auth is fixed via #1+#2, but IDOR remains)
- **Files:** all 8 handlers in `bff/social_care_web/lib/src/handlers/`
- **Evidence:** Path UUID is well-validated (`uuid_validation.dart:36-43` is rigorous), but no use case checks that the authenticated session has authorization to mutate THIS specific patient/worker. Every authenticated user can withdraw any patient given a UUID.
- **Skill alignment:** Skill §"Abuse protection — IDOR vectors". This is the canonical IDOR scenario.
- **Impact:** Healthcare PII (patient data) is enumerable + mutable by any authenticated social_worker. A `social_worker` from CRAS-A can withdraw a patient assigned to CRAS-B.
- **Remediation:** Authorization checks in the use cases / contracts. Either (a) row-level authorization in the upstream backend (push-down), or (b) explicit `authorize(session, patientId)` calls before mutations. The skill canon points at RoleGuardMiddleware (RBAC), which is the floor — IDOR demands ABAC (resource-level).

---

## CSVS / CVSS-style scoring summary

| ID | Title | Severity | CVSS-ish |
|---|---|---|---|
| #1 | authGuardMiddleware not wired | CRITICAL | 9.8 |
| #2 | Session cookie name mismatch | CRITICAL | 9.0 |
| #3 | Zero security headers | CRITICAL | 7.5 |
| #4 | OIDC PKCE/state not persisted | CRITICAL | 8.5 |
| #10 | CPF/NIS smart constructors echo raw value | CRITICAL | 8.5 |
| #19 | No X-Requested-With CSRF check | CRITICAL | 7.5 |
| #5 | CORS allows wildcards via env | MAJOR | 5.5 |
| #6 | RegisterPatientIntent fromJson not in try/catch | MAJOR | 5.5 |
| #7 | Unbounded `limit` on list endpoints | MAJOR | 6.0 |
| #8 | `tableName` no allowlist | MAJOR | 5.5 |
| #9 | No rate limiting | MAJOR | 6.5 |
| #11 | CPF forwarded raw, no domain validation | MAJOR | 5.0 |
| #13 | Dead `backendError` helper leaks stack | MAJOR | 5.5 |
| #22 | No Sec-Fetch-Site validation | MAJOR | 6.0 |
| #23 | IDOR — no resource-level authorization | MAJOR | 6.5 |
| #12 | initialPassword no strength check | MINOR | 4.0 |
| #14 | obs.logError records raw exceptions | MINOR | 4.5 |
| #15 | BackendError.stackTrace in toJson | MINOR | 3.5 |
| #16 | parseIdTokenClaims skips signature | MINOR | 4.5 |
| #17 | getSession unconditional cast | MINOR | 3.5 |
| #18 | No Cache-Control no-store | MINOR | 3.5 |
| #20 | Body size not capped | MINOR | 4.5 |
| #21 | Preflight returns 200 not 204 | MINOR | 2.0 |

---

## ACDG-specific concerns

### LGPD compliance gaps

- **#10** (smart-constructor PII leak) is the highest LGPD risk — once those constructors are wired into the live request path (Phase 4), they will write raw CPF/NIS to logs.
- **#7** (unbounded `limit`) combined with **#1** (auth bypass) means an unauthenticated client could exfiltrate the entire patient list in one request.
- **#23** (IDOR) means social workers from one organization unit can read/write patient data from another — direct LGPD § 6 (purpose limitation) violation.
- **#14** (logError records raw exceptions) needs a documented log-retention + access-control policy before production.

### Healthcare-data exposure paths

The two leakage paths to keep an eye on:
1. **Logger sink** — `Logger.root` is global; whatever attaches to it (Sentry, file, stdout) will receive everything `obs.logError` writes. Confirm sanitization at the sink.
2. **HTTP response body** — handlers correctly extract only `(http, code, message)` from `BackendError`, but the dead `backendError` helper (#13) and any future "passthrough" handler must be kept disciplined.

### Iron Frontier integrity (browser sees no tokens)

- **PASS** for the current code path — tokens are not echoed in any HTTP response body. `Set-Cookie: __Host-session=$sessionId` carries an opaque UUID, not a token.
- **CONDITIONAL** — the `auth_handler.dart` issues a fresh UUID at callback time (line 121-122) without storing it anywhere; this is correct for the cookie value but means `MeUseCase` and `RefreshUseCase` have no persistent session linkage. After fixing #2 (cookie name) the chain becomes: cookie → SessionStore — but SessionStore is **never populated by the callback path** today. The `_sessionStore.create(...)` call sits in `SessionStore` but no production code path invokes it. **This is a deeper architectural gap than just the cookie name.**

### Trust boundary verdict (per the skill table)

| Boundary | Status |
|---|---|
| Browser → Web BFF | **BROKEN** (#1, #2 — auth not enforced) |
| Web BFF → Backend | **DEFERRED** — production path uses `FakeXxxBff`; real adapters scheduled. The wiring shape is OK, but `X-Actor-Id` is hardcoded in `social_care_api_client.dart:26` (used only when wiring is replaced). |
| Desktop BFF → Backend | OK structurally — `RemoteBase.buildDio` injects `X-Actor-Id` and Bearer token interceptor (`remote_base.dart:30-61`) |

---

## Concrete recommendations for A19 / A20 / A21

In dependency order:

1. **A19-S1 (P0):** Fix #1 + #2 + #4 in a single ticket. These three are coupled: the auth chain needs `authGuardMiddleware` wired AND the cookie-name canon AND a real OIDC callback path. Suggested split:
   - Wire `authGuardMiddleware` into `protectedPipeline` (line `app_router.dart:175-176`).
   - Rename `__session` → `__Host-session` in `session_middleware.dart` and tests.
   - Implement `PkceStore` + wire `OidcServerClient` to a real `OidcAuthBff` impl that persists verifier on login and consumes it on callback. Replace `FakeAuthBff` in `bin/server.dart` for production.
2. **A19-S2 (P0):** Add `securityHeadersMiddleware` to the outermost pipeline (#3, #18). Single middleware, ~30 lines.
3. **A19-S3 (P0):** Add `csrfMiddleware` (`X-Requested-With`) and `fetchMetadataMiddleware` (`Sec-Fetch-Site`) in the protected pipeline (#19, #22).
4. **A20-S1 (P1):** Body-size middleware (#20) and `limit` clamp at the intent layer (#7). Both are 1-day tickets.
5. **A20-S2 (P1):** Allowlist for `tableName` in `lookup_handler` (#8).
6. **A20-S3 (P1):** Rate limiting via `shelf_limiter` — global + per-endpoint (#9). Tighter on `/auth/*` and `/team/*/reset-password`.
7. **A20-S4 (P1):** Strip raw CPF/NIS from VO error messages (#10) — single-line fixes in `cpf.dart` / `nis.dart`. Required BEFORE wiring smart constructors into the request path (#11).
8. **A21-S1 (P2):** IDOR — design ownership/authorization at the `Patient` / `Team Member` aggregate level (#23). This is the hardest and likely needs upstream backend cooperation.
9. **A21-S2 (P2):** Wire `Cpf.create` / `Nis.create` into the live intent layer for `register_patient`, `add_family_member`, `register_worker` (#11). Add `try/catch` to `RegisterPatientIntent` (#6).
10. **A21-S3 (P2):** Delete dead code: `handler_utils.backendError`, `handler_utils.getSession` + `health_handler.dart` (#13, #17). And the `parseIdTokenClaims` skip-verification comment (#16) — either implement JWKS or document the threat model.
11. **A21-S4 (P3):** Password policy on `initialPassword` (#12). Preflight 204 (#21). `BackendError.stackTrace` toJson defensiveness (#15). Log sanitization audit (#14).

---

**End of report.**
