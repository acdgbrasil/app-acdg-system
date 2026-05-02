# C00 — Bearer Auth Middleware — REPORT

## Status: GREEN
Closed: 2026-05-02

## Pipeline executada (5 waves, 7 dispatches de agente)

| Wave | Agent | Resultado |
|------|-------|-----------|
| W0 | test-writer | 54 RED tests em 5 arquivos (1563 LoC), 8 itens flagados |
| **W0.5** | auth-auditor | **GAPS_FOUND** — 3 MUST_FIX (M1 HMAC session id, M2 jti path, M3 pointycastle dev_dep) + 5 SHOULD_FIX |
| W0-bis | test-writer | 61 RED tests (Group D +3, Group I novo +4); todos os 8 gaps closed |
| W0.5b | auth-auditor | **APPROVED** (1 observação minor não-bloqueante: kid #37b literal vs comentário) |
| W1 R1 | flutter-bff-implementer | 1136 GREEN, 6 arch choices + 2 compromises flagged |
| **W2 R1** | flutter-code-reviewer | **REJECTED** — M1 case-sensitive cookie strip bypass (security gap real) + S1 abstract interface class + S2 OIDC_CLI_CLIENT_ID warning |
| W1 R2 | flutter-bff-implementer | M1+S1+S2 closed; 1137 GREEN (+1 regression Test #44b) |
| W2 R2 | flutter-code-reviewer | **APPROVED** Round 2/3, Round 3 não necessário |
| W3 | flutter-quality-checker | **PASSED** — 2098 GREEN total, dart analyze 0/0/0, format clean |

## Decisões consolidadas (D1–D7.1)

| ID | Decisão |
|----|---------|
| **D1** | `aud === ServerConfig.oidcCliClientId` (env var `OIDC_CLI_CLIENT_ID`) |
| **D2** | NATIVE_API no Zitadel já existe — reusa |
| **D3** | Roles via JWT claim `urn:zitadel:iam:org:project:roles` (people-context é system-of-record; Zitadel propaga; BFF lê direto, não consulta people-context) |
| **D4** | TTL é autoridade (sem denylist server-side) |
| **D5** | Matriz 4 estados — Bearer presente+inválido = **401 hard sem fallback**. Implementado via Option B (case-insensitive cookie strip). |
| **D6** | Sem endpoint server-side de logout para Bearer. CLI faz client-side (revoke + delete file) |
| **D7** | ✅ signature (JWKS cache 10min) ✅ iss ✅ exp (leeway 30s) ✅ aud ✅ nbf if present ✅ azp if present ✅ sub ❌ scope |

## 10 security constraints enforce (RFC 8725 + OWASP)

| # | Constraint | Validação |
|---|-----------|-----------|
| 1 | Token cap 8KB antes de parse | Test #38 (spy on JwksClient.fetch never called) |
| 2 | Bearer inválido = 401 hard, sem fallback | Test #45 + matriz 4 estados |
| 3 | Session ID via HMAC (jti precedence, nunca sha256(token)) | Tests #55-#57 |
| 4 | JwksCache lookup só por Map equality, sem path interpolation | Tests #37a/b/c (malicious kid) |
| 5 | Algorithm allowlist `["RS256"]` | Tests #1-#6 |
| 6 | typ allowlist `["JWT"]` | Tests #30-#31 |
| 7 | crit unknown extension → 401 | Test #32 |
| 8 | Token só via Authorization header (não query) | Test #41 |
| 9 | Logger redaction (sliding 21-char window) | Test #52 |
| 10 | 401 body genérico `{code: "AUTH-001", message: "Invalid credentials"}` | Test #53 |

## CVEs cobertas (catalogadas pelo W0.5)

- **CVE-2015-9235** — alg=none — Tests #1-#3
- **CVE-2016-10555** — alg confusion HS/RS — Tests #4-#5
- **CVE-2018-0114** — kid traversal — Tests #35-#37 + #37a/b/c

## Test layout final (61 tests em 8 grupos + 1 regression)

| Grupo | Count | Tests |
|-------|------:|-------|
| A. Algorithm attacks | 6 | #1-#6 |
| B. Signature & Integrity | 6 | #7-#12 |
| C. Claims Validation | 17 | #13-#29 |
| D. Header & Format | 11 | #30-#37 + #37a/b/c |
| E. Resource Exhaustion | 3 | #38-#40 |
| F. Transport & Pipeline | 7 | #41-#46 + #44b (regression case-insensitive cookie) |
| G. JWKS Cache | 5 | #47-#51 |
| H. Observability/Privacy | 3 | #52-#54 |
| **I. Session Construction (NEW)** | 4 | #55-#58 (HMAC, sha256 negative, jti, Session shape) |
| **Total** | **62** | (61 from W0-bis + 1 #44b regression in W1 R2) |

## Files

### Production code (created)
- `apps/social_care_bff/web/lib/src/middleware/bearer_auth_middleware.dart` (~325 LoC após R2)
- `apps/social_care_bff/web/lib/src/auth/jwks_cache.dart` (205 LoC)
- `apps/social_care_bff/web/lib/src/auth/jwks_client.dart` (47 LoC, `abstract interface class`)

### Production code (modified)
- `apps/social_care_bff/web/lib/src/config/server_config.dart` — 4 fields novos: `oidcCliClientId`, `bearerLeewaySeconds=30`, `jwksCacheTtl=10min`, `bearerMaxTokenBytes=8192`
- `apps/social_care_bff/web/lib/src/server/app_router.dart` — pipeline order `observability → bearer → session → handlers`
- `apps/social_care_bff/web/bin/server.dart` — instancia JwksCache + HttpJwksClient + warning startup quando `OIDC_CLI_CLIENT_ID` vazio
- `apps/social_care_bff/web/lib/social_care_web.dart` — exports
- `apps/social_care_bff/web/pubspec.yaml` — `pointycastle: ^4.0.0` (deps + dev_dependencies)

### Test code
- `apps/social_care_bff/web/test/middleware/_bearer_test_fixtures.dart` (54 LoC)
- `apps/social_care_bff/web/test/middleware/_bearer_test_helpers.dart` (432+ LoC após M1+S2)
- `apps/social_care_bff/web/test/middleware/bearer_auth_middleware_test.dart` (~850 LoC após M1+S1+S3+S4 + Test #44b)
- `apps/social_care_bff/web/test/middleware/bearer_auth_resource_exhaustion_test.dart` (~120 LoC)
- `apps/social_care_bff/web/test/middleware/bearer_auth_jwks_cache_test.dart` (~160 LoC após S5)

### REGRA #2 EXCEPTION (W1 R1)

W1 editou 2 testes (Test #40, Test #54) — fix legítimo de bug shelf `Body.read()` one-shot. `expectGenericAuthError` já lia o body, asserts redundantes causavam StateError. W2 validou exception correto. Documentado inline em cada teste.

## Architectural choices APPROVADAS (W2)

1. **D5 Option B** — case-insensitive cookie strip via `headersAll` enumeration (corrigido após Round 1 — case-sensitive era bypass)
2. **JWT verification manual** — `djw.JWTAlgorithm.RS256.verify()` para crypto, claims validados manualmente com leeway (controle exato D7)
3. **`OIDC_CLI_CLIENT_ID` optional in env, fail-closed when empty** — preserva 13 server_config_test.dart; warning em startup (Logger.root.warning)
4. **Roles bounded por silent truncation (256)** — não DoS-amplifier vs availability
5. **JWKS timeout dual (cache + client, 5s cada)** — defense-in-depth
6. **Logger redaction agressiva** — só `error.runtimeType`, nunca `toString()` ou stack trace

## Quality gate (W3)

- ✅ `dart analyze apps/social_care_bff/web/lib/ apps/social_care_bff/web/bin/` — 0 errors, 0 warnings, 0 infos
- ✅ `dart format` — 0 changes em arquivos C00 (7 Dart files)
- ✅ Test counts:
  - `apps/social_care_bff/web` — **1137 GREEN** (1075 prior + 62 C00)
  - `apps/social_care_bff/contracts` — 535 GREEN preserved
  - `apps/social_care_bff/desktop` — 426 GREEN +1 skip preserved
  - **Total BFF: 2098 GREEN +1 skip** (era 2036, +62 = 2098)
- ⚠️ Pre-existing format drift em 28 arquivos `lib/src/{intents,handlers,use_cases}/` — débito do commit `af81393` (reorganização monorepo). NÃO é regressão C00. Recomendado ticket separado.

## Pré-requisitos de infra

- ✅ NATIVE_API no Zitadel já existe (confirmado pelo usuário 2026-05-01)
- 🟡 **AÇÃO PENDENTE:** provisionar `OIDC_CLI_CLIENT_ID` no Bitwarden Secret Manager para DEV/STG/PROD
- 🟡 **AÇÃO PENDENTE:** quando UI Web Flutter (Phase 6+) ressuscitar, decidir se cria audience comum (`acdg-api`) que ambos clients (browser + CLI) declaram

## Próximo ticket

**C01 — CLI Scaffold** (`apps/cli/`) — depende deste C00 já que CLI vai bater no BFF Web com Bearer.

## Comandos de verificação

```bash
# Analyze
dart analyze apps/social_care_bff/web/lib/ apps/social_care_bff/web/bin/

# Format check
dart format --output=none --set-exit-if-changed \
  apps/social_care_bff/web/lib/src/middleware/bearer_auth_middleware.dart \
  apps/social_care_bff/web/lib/src/auth/jwks_cache.dart \
  apps/social_care_bff/web/lib/src/auth/jwks_client.dart \
  apps/social_care_bff/web/lib/src/config/server_config.dart \
  apps/social_care_bff/web/lib/src/server/app_router.dart \
  apps/social_care_bff/web/bin/server.dart \
  apps/social_care_bff/web/lib/social_care_web.dart

# Tests
cd apps/social_care_bff/web && dart test  # 1137 GREEN

# Cross-package non-regression
cd apps/social_care_bff/contracts && flutter test  # 535 GREEN
cd apps/social_care_bff/desktop && flutter test    # 426 GREEN +1 skip
```
