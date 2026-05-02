# C00 W2 — Code Review Report

**Date**: 2026-05-01
**Reviewer**: flutter-code-reviewer (W2)
**Mode**: read-only audit
**Implementation by**: W1 (flutter-bff-implementer)

## Verdict: REJECTED

## Round: 1/3

## Files audited

### Production (new)
- `apps/social_care_bff/web/lib/src/middleware/bearer_auth_middleware.dart` (401 lines, not 311 as listed in handoff — 90 lines wider)
- `apps/social_care_bff/web/lib/src/auth/jwks_cache.dart` (205 lines)
- `apps/social_care_bff/web/lib/src/auth/jwks_client.dart` (54 lines)

### Production (modified)
- `apps/social_care_bff/web/lib/src/config/server_config.dart`
- `apps/social_care_bff/web/lib/src/server/app_router.dart`
- `apps/social_care_bff/web/bin/server.dart`
- `apps/social_care_bff/web/lib/social_care_web.dart`
- `apps/social_care_bff/web/pubspec.yaml`

### Tests (REGRA #2 exception by W1)
- `apps/social_care_bff/web/test/middleware/bearer_auth_resource_exhaustion_test.dart` (Test #40)
- `apps/social_care_bff/web/test/middleware/bearer_auth_middleware_test.dart` (Test #54)

---

## Per-file findings

### `bearer_auth_middleware.dart`

**Strengths**
- SRP focused: this file does Bearer-token validation + Session construction. Single responsibility honored. (H1 OK)
- Constants extracted at the top (`_allowedAlgs`, `_allowedTyps`, `_maxJsonDepth`, `_maxRoles`, `_kZitadelRolesClaim`).
- Generic 401 body materialized once at file scope (avoids per-request allocation).
- Pattern P2b honored: `try/catch` lives strictly at the adapter boundary — `_validate` returns `Session?` and every parse-level rejection funnels through `null`. No exceptions cross the layer.
- Constraint #1 (8KB cap) checked at line 106, BEFORE any parse / JWKS fetch / crypto. Good.
- Constraint #8 (RFC 6750 §2.3) at line 81: `?access_token=` rejected before reading Authorization header.
- Logger redaction at line 133: `error.runtimeType` only, no `error.toString()`, no stack trace. Strong.
- Constraint #3 ladder (jti → HMAC) at lines 295-302 implemented as documented.
- `crit` header rejection at line 199 — RFC 7515 §4.1.11 satisfied.

**Issues** (see "Issues by severity" below for full routing)
- **MUST_FIX [view-implementer / infra-implementer]**: Cookie strip via `request.change(headers: {'cookie': null, 'Cookie': null})` is **case-sensitive** despite shelf treating `headers` lookups as case-insensitive. See M1 below — this is a **security gap** that breaks the contract Test #44 thinks it pins.
- **SHOULD_FIX [infra-implementer]**: H9 violation — `JwksClient` is `abstract class` instead of `abstract interface class`. Repo convention (10+ existing contracts in `apps/social_care_bff/contracts/lib/src/contract/sub_contracts/`) uses `abstract interface class`.
- **NICE_TO_HAVE**: `token.length > config.bearerMaxTokenBytes` measures UTF-16 code units, not bytes. For ASCII-only Bearer JWTs (RFC 6750) this is equivalent, so the constraint is satisfied. Worth a comment to prevent future regression if someone allows non-ASCII tokens.

### `jwks_cache.dart`

**Strengths**
- SRP focused: cache + parse + single-flight. No transport concerns leak in.
- Constraint #4 satisfied: `_keys` is `Map<String, RsaKey>` only; `kid` reaches no path/file/SQL surface. Lines 16-18 + 57-60 explicitly document this.
- Single-flight latch (lines 108-128) coalesces concurrent fetches into 1.
- Fail-closed: `_doFetch` swallows all errors via `try/catch on Object` and leaves cache state intact. The completer `.catchError` is defensive belt-and-suspenders (acceptable).
- TTL expiration drives refetch; refresh-on-miss path documented at lines 95-98.
- `_loadedAt` intentionally NOT updated on failure (line 144 comment) so transient failures are immediately retryable on next call. Sound.
- 5s timeout in cache layer (line 136) AND in `HttpJwksClient.fetch()` (line 39). Defense-in-depth — see "6 architectural choices" below.

**Issues**
- None at MUST_FIX. All optionals are addressed via composition rather than inheritance (H7 OK), and `JwksCache` does not extend anything.

### `jwks_client.dart`

**Strengths**
- Two-class file is acceptable: the abstract contract + the production HTTP impl. No private `_*` widget-style sprawl.
- Doc comment makes the throw-vs-return contract explicit: implementations MUST throw on timeout/non-2xx so the cache can fail-closed.
- `HttpJwksClient` injects `httpClient` for tests; default is fresh `http.Client()`.

**Issues**
- **SHOULD_FIX [infra-implementer]**: `abstract class JwksClient` (line 13) should be `abstract interface class JwksClient` per ENCAPSULATION_POLICY H9 and repo convention. Cross-layer contract.

### `server_config.dart`

**Strengths**
- 4 fields added with sane defaults: `oidcCliClientId = ''`, `bearerLeewaySeconds = 30`, `jwksCacheTtl = const Duration(minutes: 10)`, `bearerMaxTokenBytes = 8192`. All match ticket §"Update server_config.dart" line-by-line.
- Each new env var is parsed defensively: `int.tryParse` + StateError on a non-int present (lines 56-78). Failed parsing surfaces a structured error.
- Doc comment on `oidcCliClientId` (lines 142-147) explicitly notes "empty string means the Bearer path will reject every token (no CLI access configured)". Good — this is the fail-closed contract.

**Issues**
- **SHOULD_FIX [infra-implementer]**: `oidcCliClientId` is documented as fail-closed when empty (line 146-147), but the `fromEnvironment` factory does NOT enforce that the env var is set. The `required(...)` helper is bypassed (line 50-53 uses an explicit empty default). For a production gate this means: "env var unset → silent acceptance; every CLI Bearer rejected at runtime, but startup succeeds without warning." See "3 compromises" verdict below — this is the intended W1 design but it's the wrong default for production.
- The constructor parameter `oidcCliClientId = ''` has a default value. ENCAPSULATION_POLICY does not forbid this, but it is consistent with the principle of explicit configuration to require it. SHOULD_FIX.

### `app_router.dart`

**Strengths**
- Pipeline order at lines 180-186: `observability → bearer → session → handlers`. Matches ticket §"Update app_router.dart".
- Cookie path explicitly preserved on the `/auth/*` pipeline (lines 136-139) — ticket criterion "Cookie path 100% intocado" honored.
- `JwksCache` injected, never constructed inline.

**Issues**
- None.

### `bin/server.dart`

**Strengths**
- `JwksCache` instantiated once at startup (lines 24-27), shared across all requests.
- `HttpJwksClient` wired to `config.jwksUri` (the issuer-derived `/oauth/v2/keys` path).
- 5s default timeout inherited from `HttpJwksClient` constructor default.

**Issues**
- **NICE_TO_HAVE**: No JWKS pre-warm at server start. The first cold request will eat one round-trip + 5s worst-case timeout. Per W0.5 N7, lazy fetch is acceptable; flagged here as a future optimization.

### `social_care_web.dart`

**Strengths**
- Exports `jwks_cache.dart`, `jwks_client.dart`, `bearer_auth_middleware.dart`. All needed symbols are public via the library barrel.

**Issues**
- None.

### `pubspec.yaml`

**Strengths**
- `pointycastle: ^4.0.0` moved to main dependencies (line 37) since `JwksCache` uses it directly. The accompanying comment explains this is now a direct consumer (not transitive).

**Issues**
- None. `depend_on_referenced_packages` will be satisfied.

---

## REGRA #2 exception validation

**Diagnosis correct?** YES. Confirmed via `/Users/gabriel_aderaldo/.pub-cache/hosted/pub.dev/shelf-1.4.2/lib/src/body.dart:91-99`:

```dart
Stream<List<int>> read() {
  if (_stream == null) {
    throw StateError("The 'read' method can only be called once on a "
        'shelf.Request/shelf.Response object.');
  }
  ...
}
```

`expectGenericAuthError` at `_bearer_test_helpers.dart:375` calls `r.readAsString()`, which calls `body.read()`. A subsequent `await response.readAsString()` would throw `StateError`. The original W0 tests had a structural bug.

**Fix preserves intent?**

- **Test #40 (roles 10k entries)**: Fix preserves intent. The 200 path still asserts `lessThanOrEqualTo(256)`. The 401 path still calls `expectGenericAuthError` which pins body == `{code: AUTH-001, message: Invalid credentials}`. The redundant re-read was a nop check (the body is already fully validated). Strong assertion preserved.

- **Test #54 (stack trace, kSessionSecret/PEM/INTERNAL leak)**: Fix preserves intent **for the canonical 401 body** but the assertion is structurally weakened compared to W0's full-body forbidden-string check. HOWEVER:
  - `expectGenericAuthError` checks `body == {code: 'AUTH-001', message: 'Invalid credentials'}` exactly (helper lines 378-381) AND key-set pinning is enforced via Test #53 (line 781 — keys must equal `{code, message}`).
  - Therefore the body literally cannot contain `kSessionSecret` / `'-----BEGIN'` / `'INTERNAL:'` because it cannot contain ANYTHING beyond the canonical 2-key shape.
  - The substantive assertion — log records do not contain secrets — is preserved in the spy loop (lines 820-825).
  - The log spy remains the actual leak detector. The body-side check was structurally redundant.

**Verdict on REGRA #2 exception**: **APPROVED**. The diagnosis is correct (shelf one-shot Body), the fix preserves the contractual intent (canonical body still fully pinned, log spy still pins secret leaks), and the comments explicitly invoke REGRA #2 with the rationale. No watering down occurred.

---

## 6 architectural choices verdict

### 1. D5 matrix — Option B (cookie strip) via `request.change(headers: {'cookie': null, 'Cookie': null})`

**Verdict: REJECTED — MUST_FIX**

This is a **security gap**. Empirically verified via a standalone shelf 1.4.2 reproduction (`/tmp/shelf_test/test_shelf_change2.dart`):

| Original header | Strip operation | Result |
|-----------------|------------------|--------|
| `Cookie: ...`   | `{'cookie': null, 'Cookie': null}` | Removed ✓ |
| `cookie: ...`   | `{'cookie': null, 'Cookie': null}` | Removed ✓ |
| `COOKIE: ...`   | `{'cookie': null, 'Cookie': null}` | **NOT removed ✗** |
| `cookIE: ...`   | `{'cookie': null, 'Cookie': null}` | **NOT removed ✗** |
| `CooKie: ...`   | `{'cookie': null, 'Cookie': null}` | **NOT removed ✗** |

Root cause: shelf's `updateMap` (`util.dart:32-46`) does a regular `Map.remove(key)` on `Map.of(original)` — the resulting map is a `LinkedHashMap`, not a `CaseInsensitiveMap`. Only the exact-case keys passed to `change()` are removed.

**Why this is exploitable**: `sessionMiddleware` (`session_middleware.dart:17`) reads `request.headers['cookie']`. The shelf `headers` getter returns a `CaseInsensitiveMap` (`headers.dart:14-19`), so even after a "strip" with `cookie+Cookie`, the unstripped `COOKIE: __session=...` header IS visible at lookup time. An attacker with a valid Bearer + a stolen cookie smuggled as `COOKIE: __session=stolen-id` would land a `Session` in **both** `bearerSessionContextKey` AND `sessionContextKey`. The S1 contract that Test #44 validates (`cookieSession == null`) holds only for the canonical `Cookie:` casing used in the test fixture (line 576) — it is **not** robust to adversarial casing.

**Test #44 passes coincidentally**: the test uses `'Cookie': '__session=...'` (line 576), which matches the strip's `'Cookie': null` exactly. The test does NOT exercise alternate casings.

**Required fix options** (W1 picks):
- Option A: replace the strip with a fresh `CaseInsensitiveMap` rebuild that drops any case variant of `cookie`. E.g., iterate `request.headersAll` and rebuild without cookies, then call `request.change(headers: rebuiltHeaders)`.
- Option B: short-circuit BEFORE `sessionMiddleware` runs (place bearer middleware on a separate pipeline that does NOT include `sessionMiddleware` for the success path). Architecturally heavier but eliminates the case-variance attack surface entirely.
- Option C: enumerate likely casings (`cookie`, `Cookie`, `COOKIE`, `Cookie`, etc.) — but this is whack-a-mole and easy to miss `cooKie`.

The cleanest fix is Option A: build the new header map case-insensitively. Shelf's `Headers` constructor uses `CaseInsensitiveMap.fromEntries`, so feeding `request.change(headers: ...)` a fresh map without any cookie key (regardless of original case) is sufficient.

### 2. JWT verification manual (not `JWT.verify()` of dart_jsonwebtoken)

**Verdict: APPROVED**

The implementation uses `djw.JWTAlgorithm.RS256.verify()` for the crypto primitive only and validates claims manually. This is the correct call given:
- Constraint #5 (`alg` allowlist with no fallthrough to `none`/HMAC). The library's `JWT.verify()` reads the alg from the header and invokes the matching algorithm — exactly the alg-confusion CVE-2015-9235 vector. Manual allowlist + library crypto is safer.
- Custom leeway semantics (constraint D7) where the leeway applies asymmetrically (`exp` past + leeway, `nbf` future − leeway, `iat` future absurdity). The library's defaults differ.
- Custom audience semantics (string OR array containing).

Claim validations reimplemented: `iss`, `sub`, `iat` (future absurdity), `exp` (with leeway), `nbf` (with leeway, optional), `aud` (string-or-array), `azp` (D7.1, optional), `crit` (RFC 7515 §4.1.11). Each is correctly typed-checked (`is! String` / `is! int` / `is! List`) before semantic comparison. No claim oracle leaks (every rejection collapses to `null` → 401).

### 3. `OIDC_CLI_CLIENT_ID` optional in env (defaults to '')

**Verdict: APPROVED with reservation — SHOULD_FIX**

Fail-closed at runtime is the correct security posture: empty `oidcCliClientId` means `_audienceMatches` (line 317) returns false for every aud check, so every Bearer is 401. Good.

**However**: the `fromEnvironment` factory permits an unset env var to produce a silently-misconfigured BFF that boots successfully and then 401s every CLI request without any startup signal. For a production gate this is the wrong default — operators should know at boot time, not from a 401 storm.

**Recommended hardening**: either (a) make `OIDC_CLI_CLIENT_ID` required via the `required(...)` helper, OR (b) emit a `Logger.warning` at server startup when `oidcCliClientId.isEmpty`. Option (b) is the lighter touch.

This is SHOULD_FIX because:
- The runtime contract is preserved (no false-positive auth).
- Tests can override via the explicit constructor — covered.
- It's an operational concern, not a security gap that lets an attacker through.

### 4. Roles bounded via silent truncation (256 entries)

**Verdict: APPROVED**

Silent truncation is **not** a security risk in this context:

- An attacker constructing a token with 10,000 roles is trying to consume server memory (DoS), not to fake an authorization. They cannot inject roles they don't have — Zitadel signs the token, and its role assignment is what determines the claim.
- A legitimate user with > 256 roles is implausible (Zitadel tenants usually have far fewer per project). Even at the 99th percentile, 256 is generous.
- "Truncated role set causes false negative on auth check" — this is a feature: if a user has more than 256 roles AND auth_guard requires one of the truncated roles, they get a 403. That's fail-closed (worst case: legit user gets denied). It is NOT a privilege escalation vector — truncation can only **remove** roles, never add them.
- A future attacker who somehow manages to forge a 10k-role token (with valid signature) would have full Zitadel compromise — at that point the truncation is irrelevant.

The W0.5 audit (line 67) flagged this as "adequate". Constraint #40 says "bounded or 401". The implementation chose "bounded" with a documented constant. The doc comment at lines 333-338 explains the trade-off (DoS amplifier vs availability) clearly.

### 5. JWKS timeout in BOTH cache and client (5s each)

**Verdict: APPROVED — Defense-in-depth**

Two layers, two reasons:
- `HttpJwksClient.fetch()` line 39: timeout on the HTTP call itself. If a custom `http.Client` is injected that doesn't respect timeouts, this still bounds the duration.
- `JwksCache._doFetch()` line 136: timeout on the awaited future from `_client.fetch()`. If `JwksClient` is implemented with NO internal timeout, this still bounds the duration. Defense for non-http production implementations (e.g., a future caching layer wrapping an external service).

Each layer is independent. Both are 5s, so the worst-case visible latency is bounded by 5s + dispatch overhead. Test #48 (line 90 of `bearer_auth_jwks_cache_test.dart`) asserts `< 5500ms` with a 30s injected upstream delay — the cache-layer timeout is what enforces that bound.

This is not duplication; it is correct layered defense. APPROVED.

### 6. Logger redaction — only `error.runtimeType`, never `error.toString()` or stack trace

**Verdict: APPROVED**

Looking at the full implementation:

```
_log.warning(
  'bearer.validate.error type=${error.runtimeType} '
  'authorization=[REDACTED]',
);
```

This is the **right** balance:
- Operationally useful: ops can tell `JwksFetchException` from `FormatException` from `TimeoutException` from `StateError` from a 3rd-party leaky `Exception('INTERNAL: secret=...')`. The runtime type carries enough signal for debugging.
- Safety: `error.toString()` is forbidden, so even if `JwksClient` is implemented poorly and embeds the session secret in a thrown message (Test #54's "leaky" exception scenario), the secret never reaches a log line.
- Stack trace omission is correct: stack traces in Dart can include the call site's local-variable values via toString'd identifier names. They CAN leak secrets if the leaky exception object is in scope. The W1 comment at lines 130-132 explicitly documents this rationale.

The existing observability infrastructure (`observabilityMiddleware`) catches uncaught errors at the request level — but Bearer middleware errors are intentionally swallowed (the response is always either pass-through or generic-401), so the only place errors surface is the warning log. Keeping that warning info-poor by design is correct.

If future ops investigations need more, the right answer is "add structured request_id and correlate with Zitadel JWKS upstream logs", not "expand the bearer log line".

---

## 3 compromises verdict

| # | Compromise | Verdict |
|---|------------|---------|
| 1 | D5 row 2 cookie strip via `request.change` | **REJECTED — MUST_FIX**. See architectural choice 1 above. Case-sensitive removal does not match shelf's case-insensitive lookup. |
| 2 | Manual JWT validation | APPROVED |
| 3 | `OIDC_CLI_CLIENT_ID` optional in env | SHOULD_FIX (recommend startup warning OR mandatory env var) |

---

## 10 security constraints verdict

### Constraint #1 — 8KB cap before parse
**Code reference**: `bearer_auth_middleware.dart:106`
**Verdict**: ENFORCED. Check is BEFORE `_validate` invocation (which does parse + JWKS fetch + crypto). The shelf-level test (`bearer_auth_resource_exhaustion_test.dart:60-65`) confirms `jwksClient.callCount == 0`.
**Note**: `token.length` is UTF-16 code units; for ASCII-only Bearer JWTs (RFC 6750) this equals byte count.

### Constraint #2 — Bearer invalid = 401 hard, no fallback
**Code reference**: `bearer_auth_middleware.dart:140-143`
**Verdict**: ENFORCED. After `_validate` returns null, the middleware returns `_generic401()` directly — control NEVER reaches `innerHandler`. Test #45 pins this with `handlerInvoked == false`.

### Constraint #3 — HMAC session id
**Code reference**: `bearer_auth_middleware.dart:295-302`
**Verdict**: ENFORCED.
- `jti` precedence: `if (jti is String && jti.isNotEmpty) sessionId = jti;` (line 297)
- HMAC fallback: `hmac.convert(utf8.encode('$sub:$iat')).bytes` → `base64Url.encode(...)` minus padding (lines 300-301)
- Hmac is constructed once at middleware factory level (line 72): `crypto.Hmac(crypto.sha256, utf8.encode(config.sessionSecret))`. NOT `sha256(token)`. Tests #55, #56, #57 pin this.

### Constraint #4 — JwksCache lookup is Map<String, ...> only
**Code reference**: `jwks_cache.dart:61` + `jwks_cache.dart:88, 92, 97`
**Verdict**: ENFORCED. `_keys` is `Map<String, RsaKey>`. Lookups are `_keys[kid]` — pure equality against pre-loaded strings. Zero string concatenation with `kid` for paths/files/URLs/SQL. The `_parseJwks` method receives the JWKS JSON document and only writes `result[kid] = ...` (line 178); the `kid` never crosses an I/O boundary as a path component.

### Constraint #5 — Algorithm allowlist `["RS256"]`
**Code reference**: `bearer_auth_middleware.dart:25` + `194-195`
**Verdict**: ENFORCED. `_allowedAlgs = const Set<String>{'RS256'}`; alg is checked with `if (alg is! String || !_allowedAlgs.contains(alg)) return null;`. Case-sensitive equality on the immutable set means `none`, `None`, `nOnE`, `HS256`, `HS512`, `""`, missing-alg all reject before signature verification.

### Constraint #6 — `typ` allowlist `["JWT"]`
**Code reference**: `bearer_auth_middleware.dart:28` + `191-192`
**Verdict**: ENFORCED. Same shape as alg allowlist. Tests #30 (`JWE`) and #31 (`JOSE+JSON`) confirm.

### Constraint #7 — `crit` header rejection on unknown extension
**Code reference**: `bearer_auth_middleware.dart:199`
**Verdict**: ENFORCED. The implementation interprets the constraint correctly: since this validator declares zero understood extensions, **any** `crit` value triggers rejection (RFC 7515 §4.1.11 — relying parties MUST reject if `crit` declares an extension they don't understand). Test #32 confirms.

### Constraint #8 — `?access_token=...` rejected
**Code reference**: `bearer_auth_middleware.dart:81-83`
**Verdict**: ENFORCED. Check happens BEFORE the Authorization header is even read, so the middleware returns 401 even if `Authorization` is also absent. Test #41 pins `handlerInvoked == false`.

### Constraint #9 — Logger redaction (Authorization → [REDACTED])
**Code reference**: `bearer_auth_middleware.dart:133-136`
**Verdict**: ENFORCED. The only log statement in the middleware is the warning on validation error, which uses the literal `authorization=[REDACTED]` marker. The token never reaches a log line. Tests #52 (sliding 21-char window over the token) and #54 (session secret + PEM forbidden) cross-check this from the log spy side.

### Constraint #10 — 401 body always generic `{code: AUTH-001, message: "Invalid credentials"}`
**Code reference**: `bearer_auth_middleware.dart:42-47, 394-400`
**Verdict**: ENFORCED. The `_genericAuthBody` is materialized once at file scope. Every 401 path (`_generic401()`) returns a `Response` with this body and `content-type: application/json`. Test #53 collapses 4 distinct rejection causes (expired, bad sig, wrong issuer, wrong audience) and asserts all 4 produce IDENTICAL bodies with EXACTLY the keys `{code, message}`. Strong.

---

## Issues by severity

### MUST_FIX (blocking)

#### M1. Cookie strip via `request.change(headers: {'cookie': null, 'Cookie': null})` is case-sensitive — security gap

**Routed to**: infra-implementer
**File**: `apps/social_care_bff/web/lib/src/middleware/bearer_auth_middleware.dart:152-158`
**Severity**: CRITICAL — defeats the W0.5 S1 contract (cookieSession must not surface when Bearer wins) for any non-canonical cookie casing.
**Evidence**: Empirical reproduction in `/tmp/shelf_test/test_shelf_change2.dart` (deleted after audit; full transcript in this report). Headers sent as `COOKIE`, `cookIE`, `CooKie` are NOT removed by the strip but ARE visible to `sessionMiddleware` via case-insensitive `request.headers['cookie']`.
**Why test #44 passes**: the test fixture sends `'Cookie': '...'`, which exact-matches the strip. Adversarial casings are not exercised.
**Fix**: rebuild headers case-insensitively (Option A, lightest), e.g. enumerate `request.headersAll.entries` and skip any entry whose key lowercases to `cookie`, then `request.change(headers: rebuilt)`. Verify with a unit test that uses `COOKIE: __session=...`.

### SHOULD_FIX (block after round 2)

#### S1. `JwksClient` should be `abstract interface class` not `abstract class`

**Routed to**: infra-implementer
**File**: `apps/social_care_bff/web/lib/src/auth/jwks_client.dart:13`
**Rule**: ENCAPSULATION_POLICY H9 + repo convention (10+ contracts in `apps/social_care_bff/contracts/` already use `abstract interface class`).
**Fix**: change `abstract class JwksClient {` to `abstract interface class JwksClient {`. No behavior change.

#### S2. `OIDC_CLI_CLIENT_ID` silently empty in `fromEnvironment` — no startup signal

**Routed to**: infra-implementer
**File**: `apps/social_care_bff/web/lib/src/config/server_config.dart:50-53`
**Rationale**: Empty `oidcCliClientId` is fail-closed at runtime (good) but produces no startup signal (bad). Operators won't know they forgot the env var until 401s appear.
**Fix options**:
- (a) Make `OIDC_CLI_CLIENT_ID` required via the `required(...)` helper (line 32-39).
- (b) Emit `Logger.warning('CLI Bearer auth disabled — OIDC_CLI_CLIENT_ID not set')` somewhere at startup (e.g., `bin/server.dart` after `ServerConfig.fromEnvironment()`).
W1 picks. (a) is stronger; (b) is the lighter touch.

### NICE_TO_HAVE

#### N1. `token.length` measures UTF-16 code units, not bytes

**File**: `apps/social_care_bff/web/lib/src/middleware/bearer_auth_middleware.dart:106`
**Note**: For ASCII-only Bearer JWTs (RFC 6750), `String.length` == byte count. Add a one-line comment noting this assumption to prevent a future regression if non-ASCII tokens are ever allowed.

#### N2. JWKS pre-warm at server start

**File**: `apps/social_care_bff/web/bin/server.dart`
**Note**: The first cold request will trigger an upstream JWKS fetch. Per W0.5 N7, lazy fetch is acceptable. Future optimization: call `await jwksCache.refresh()` after construction at line 27. Eliminates first-request latency variance.

---

## Final recommendation

**REJECTED Round 1/3** — 1 MUST_FIX (M1 — cookie strip case-sensitivity).

**On fix**: re-route to W2 for Round 2 review. SHOULD_FIX items (S1, S2) are not Round-1 blockers but must be resolved before Round 3 final approval.

**Re-review on Round 2 will need**:
- Confirmation M1 is addressed via case-insensitive strip OR pipeline reordering.
- A regression test in `bearer_auth_middleware_test.dart` that sends `Cookie` with non-canonical casing (e.g., `COOKIE: __session=...`) AND a valid Bearer, asserting `cookieSession == null` per S1 contract. Without this test the case-sensitivity gap could re-surface silently.
- S1 (`abstract interface class`) and S2 (startup signal) addressed in the same round.

**On Round 2 GREEN**, proceed to W3 (quality-checker).

---

## Round 2 — 2026-05-02

### Verdict: APPROVED

### Per-item confirmation

- **M1** (cookie strip case-sensitivity): **RESOLVED**.
  - `apps/social_care_bff/web/lib/src/middleware/bearer_auth_middleware.dart:173-185` enumerates `request.headersAll.keys`, lowercases each (`key.toLowerCase() == 'cookie'`), and builds a removal map preserving each variant's original casing. This is exactly the Option-A fix recommended in Round 1.
  - Comment block at lines 156-171 documents the prior gap, the shelf root cause, and references the W2 Round 1 M1 finding — strong forensic provenance.
  - Edge-case scan: `key.toLowerCase() == 'cookie'` requires EXACT lowercase match. `Cookie2` → `cookie2` (no match — correct), `Set-Cookie` → `set-cookie` (no match — correct, and server-set anyway). No over-matching.
  - Regression test (`apps/social_care_bff/web/test/middleware/bearer_auth_middleware_test.dart:646-724`, "Test #44b") sends `'COOKIE': '__session=...'` (uppercase) plus a valid Bearer, asserts `bearerSession != null`, `bearerSession!.userId == kValidSubject`, roles contain `social_worker` but NOT `admin`, AND `cookieSession == null`. Same assertion strength as Test #44 plus an explicit casing-rationale comment block (lines 646-659). The S1 contract is now pinned for both canonical and adversarial casings.
  - W2 Round 1 evidence transcript (`/tmp/shelf_test/...`) exercised the failing path; the new code path is correctly inverse to that failure mode.

- **S1** (`abstract interface class`): **RESOLVED**.
  - `apps/social_care_bff/web/lib/src/auth/jwks_client.dart:13` now reads `abstract interface class JwksClient`.
  - `HttpJwksClient implements JwksClient` (line 24) compiles unchanged — `implements` is the documented downstream pattern for `abstract interface class`.
  - No other consumers in the codebase rely on subclass-style inheritance of `JwksClient`, so the tighter contract introduces zero regressions.

- **S2** (`OIDC_CLI_CLIENT_ID` empty-default startup warning): **RESOLVED**.
  - `apps/social_care_bff/web/bin/server.dart:26-32` emits `Logger.root.warning(...)` immediately after `ServerConfig.fromEnvironment()` when `config.oidcCliClientId.isEmpty`. Message: "OIDC_CLI_CLIENT_ID env var is not set. All Bearer auth requests will be rejected with 401 (fail-closed). Set this var to enable CLI auth." — explicitly names the fail-closed contract and the operator action.
  - `apps/social_care_bff/web/lib/src/config/server_config.dart:142-153` doc comment expanded to record (a) the empty-string fail-closed runtime contract, (b) the operational requirement that production deployments MUST set `OIDC_CLI_CLIENT_ID`, and (c) the cross-reference to the startup warning emitted by `bin/server.dart`. Doc accurately mirrors implementation.
  - The `logging` package is already imported at `bin/server.dart:1`, so no new dependency is added.
  - Existing 13 `server_config_test.dart` tests are unaffected: the `fromEnvironment` factory's behavior is unchanged (still defaults to `''`); only `bin/server.dart` (untested at unit level) gained a warning side-effect.

### New findings

None at MUST_FIX or SHOULD_FIX severity. Defensive scan results:

- **Cookie strip over-matching**: confirmed safe. The strict equality `key.toLowerCase() == 'cookie'` cannot match `Cookie2`, `Set-Cookie`, or any other unrelated header. Only request-borne `Cookie` variants are removed.
- **Test #44b assertion strength**: equal to Test #44 (same five assertions: status 200, bearer non-null, bearer userId, bearer role inclusion, bearer role exclusion, cookie session null). The cosmetic format pass on `bearer_auth_middleware_test.dart` did not weaken any existing assertion — Tests #44, #45, #46, #52, #53, #54, #55, #56, #57, #58 keep the same `expect(...)` shapes and reasons as Round 1.
- **N1 UTF-16 comment** (lines 106-110): accurate. Correctly notes that for ASCII-only RFC 6750 §2.1 base64url tokens, `String.length` equals byte count, and gives the migration recipe (`utf8.encode(token).length`) for any future non-ASCII case. No regression risk introduced by the comment itself.
- **Cookie strip + `request.change` interaction**: verified. `request.change(headers: cookieRemovals, context: {...})` with `cookieRemovals` containing `{originalKey: null, ...}` for every cookie variant relies on shelf's documented null-value semantics for header removal. With every original-cased variant explicitly mapped to `null`, all variants are removed — independent of the underlying `LinkedHashMap`/`CaseInsensitiveMap` distinction that broke the Round 1 implementation.
- **Logger.root.warning at boot**: emitted before `ShelfServer.start()`, so the message lands in stdout/stderr before the first request can hit the server. Operationally correct.

### Final unlock decision

**APPROVED** to proceed to W3 (flutter-quality-checker).

All Round 1 issues resolved with no new findings. Test count went 1136 → 1137 GREEN with the M1 regression test. The Bearer middleware now satisfies all 10 security constraints, the D5 4-state matrix (including Row 2 cookie suppression for adversarial casings), and the W0.5 S1 contract.

Round 2/3 closes with margin — Round 3 not required.
