# C00 — Bearer Auth Middleware no BFF Web

## Onda: 1 | Profile: middleware | Depende de: nada (gate de entrada da Phase 5)

## Motivação

D3.C γ híbrido — BFF aceita ambos: `__session` cookie (browser) + `Authorization: Bearer <jwt>` (CLI / outros clientes não-browser). Hoje o BFF Web só tem session cookie middleware. CLI precisa de Bearer.

## Decisões consolidadas (sessão 2026-05-01/02)

| ID | Decisão |
|----|---------|
| **D1** | `aud === ServerConfig.oidcCliClientId` (env var nova `OIDC_CLI_CLIENT_ID`) |
| **D2** | NATIVE_API no Zitadel **já existe** — reusa. C00 documenta como pré-req. |
| **D3** | Roles via JWT claim `urn:zitadel:iam:org:project:roles` (mesmo padrão do backend Swift `ZitadelJWTPayload.swift:13`). People-context é system-of-record; Zitadel propaga via JWT; BFF lê do JWT direto, **NÃO consulta people-context para autorizar**. |
| **D4** | TTL é autoridade (sem denylist server-side). Stateless. |
| **D5** | **Matriz de 4 estados** (corrigido após auditoria de segurança): |
|       | Bearer ausente + cookie presente → usa cookie |
|       | Bearer presente + válido → usa Bearer, **ignora cookie** |
|       | Bearer presente + inválido → **401 imediato, NÃO fallback pra cookie** |
|       | Ambos ausentes → passa pro auth_guard decidir |
| **D6** | Sem endpoint server-side de logout para Bearer. CLI faz tudo client-side (revoke direto no Zitadel + apaga `~/.config/acdg/credentials`). Documentado no ticket C02. |
| **D7** | Validações JWT mandatórias: |
|       | ✅ signature via JWKS (cache 10min + refresh on signature mismatch) |
|       | ✅ `iss === oidcIssuer` |
|       | ✅ `exp` not expired (leeway 30s) |
|       | ✅ `aud === oidcCliClientId` (string ou array contendo) |
|       | ✅ `nbf` if present (leeway 30s) |
|       | ✅ `azp === oidcCliClientId` if present (D7.1 — defense-in-depth) |
|       | ✅ `sub` present (necessário pra montar Session) |
|       | ❌ `scope` skip (não usar como gate) |

## Constraints de segurança (RFC 8725 + OWASP)

Os testes DEVEM forçar a implementação a respeitar:

1. **Max token size 8KB** — rejeitar `Authorization: Bearer ...` payload > 8KB antes de qualquer parse (proteção contra JWT bombing / DoS).
2. **Bearer inválido = 401 hard** — sem fallback pra cookie (proteção contra ataque de cookie-roubado-com-bearer-falso).
3. **Session ID via HMAC** — `hmac_sha256(serverConfig.sessionSecret, sub + ":" + iat)` quando `jti` ausente; usar `jti` se presente. **Nunca hash(token) puro** (proteção contra token leakage em logs/Sentry virando ID estável que cruza com PII).
4. **JwksCache lookup** — `Map<String, RsaKey>` apenas; `kid` é input não-confiável → só comparação por igualdade contra strings já carregadas; zero interpolação em path/file (proteção contra LFI/RCE via kid traversal).
5. **Algorithm whitelist** — `["RS256"]` (Zitadel default). Rejeitar tudo o mais incluindo `none`, case variations (`None`, `nOnE`), simétricos (`HS256`, `HS512`) — proteção contra alg confusion.
6. **`typ` allowlist** — `["JWT"]`. Rejeitar `JWE`, `JOSE+JSON`, etc. (RFC 8725 §3.11).
7. **`crit` header** — se presente com extensão desconhecida → 401 (RFC 7515 §4.1.11).
8. **Token só via `Authorization` header** — `?access_token=...` rejeitado (RFC 6750 §2.3).
9. **Logger redaction** — `Authorization` header sempre redatado para `[REDACTED]` em logs/breadcrumbs.
10. **401 body genérico** — `{code: "AUTH-001", message: "Invalid credentials"}`. Sem oracle de validação (não distinguir `expired` vs `invalid signature`).

## Escopo de implementação

### Novo: `apps/social_care_bff/web/lib/src/middleware/bearer_auth_middleware.dart`

Middleware Shelf que:
1. Lê header `Authorization: Bearer <token>`.
2. Aplica D5 matriz de 4 estados.
3. Valida 7 claims (D7) + 10 constraints de segurança.
4. Constrói `Session` (mesma classe do session cookie path) com:
   - `id`: HMAC-SHA256 conforme constraint #3
   - `accessToken`: o JWT raw
   - `refreshToken`: `""` (Bearer path não tem refresh — CLI gerencia local)
   - `userId`: claim `sub`
   - `roles`: parsed de `urn:zitadel:iam:org:project:roles`
   - `expiresAt`: claim `exp`
   - `displayName`: `null` (Bearer path não enrich do People-context)
5. Popula `request.context['session']` igual `sessionMiddleware`.

### Novo: `apps/social_care_bff/web/lib/src/auth/jwks_cache.dart`

- TTL 10min (configurável)
- Refresh on signature mismatch (1 retry, depois 401)
- Single-flight (100 requests concorrentes em cold start → 1 só fetch)
- Fail-closed em timeout (5s) ou JSON inválido → 401

### Update: `apps/social_care_bff/web/lib/src/config/server_config.dart`

Nova field obrigatória + env var:
- `oidcCliClientId` (env: `OIDC_CLI_CLIENT_ID`)
- (opcional, com default) `bearerLeewaySeconds: 30`
- (opcional, com default) `jwksCacheTtl: Duration(minutes: 10)`
- (opcional, com default) `bearerMaxTokenBytes: 8192`

### Update: `apps/social_care_bff/web/lib/src/server/app_router.dart`

Pipeline atualizada: `observability → bearer → session → handlers`.
- Bearer popula context se válido; 401 hard se inválido.
- Senão (sem Authorization header), passa adiante; session middleware tenta cookie.

### Update: `apps/social_care_bff/web/.env.example` (se existir) + `apps/social_care_bff/desktop/.env.example`

Documentar `OIDC_CLI_CLIENT_ID` como obrigatório a partir de C00.

## Pipeline TDD (5 waves)

| Wave | Agent | Output |
|------|-------|--------|
| **W0 — RED** | `test-writer` | 54 tests falhando (8 grupos A-H abaixo) |
| **W0.5 — RED-TEAM AUDIT** | `red-team-scanner` | Audit read-only dos tests + middleware design contra CVEs (alg confusion CVE-2015-9235, kid traversal CVE-2018-0114, JWT bombing, oracle leakage). APPROVED ou gaps. |
| **W1 — GREEN** | `flutter-bff-implementer` | Implementação até 54 tests GREEN |
| **W2 — REVIEW** | `flutter-code-reviewer` | Audit Non-Negotiable Rules (max 3 rounds) |
| **W3 — QUALITY** | `flutter-quality-checker` | analyze + format + test |

## Lista completa de testes (54 casos em 8 grupos)

### A. Algorithm Attacks (RFC 8725 §3.1) — 6 testes 🔴

1. `alg: "none"` → 401
2. `alg: "None"` (case variation) → 401
3. `alg: ""` (empty) → 401
4. `alg: "HS256"` com JWK público RS256 como secret → 401 (alg confusion clássico — CVE-2015-9235)
5. `alg: "HS512"` (qualquer simétrico quando esperamos RS256) → 401
6. `alg` ausente do header → 401

### B. Signature & Integrity — 6 testes 🔴

7. Signature byte tampered → 401
8. Header tampered, signature recalculada com chave atacante → 401
9. Payload tampered (ex: `role=admin` injetada), signature original → 401
10. Signature vazia (3 partes mas última é `""`) → 401
11. JWT com 2 partes (signature ausente) → 401
12. JWT com 4 partes (parece JWE) → 401

### C. Claims Validation — 17 testes 🔴

13. `exp` no passado → 401
14. `exp` ausente → 401 (não aceitar token sem expiração)
15. `exp` no passado dentro do leeway (-29s) → 200
16. `exp` no passado fora do leeway (-31s) → 401
17. `iat` no futuro absurdo (>1h) → 401
18. `nbf` no futuro além do leeway → 401
19. `nbf` no futuro dentro do leeway → 200
20. `nbf` ausente → 200 (claim opcional)
21. `iss` errado → 401
22. `iss` ausente → 401
23. `aud` string igual ao esperado → 200
24. `aud` array contendo o esperado → 200
25. `aud` array sem o esperado → 401
26. `aud` ausente → 401
27. `azp ≠ client_id` → 401
28. `azp` ausente → 200 (claim opcional)
29. `sub` ausente → 401 (não dá pra montar Session)

### D. Header & Format Attacks — 8 testes 🔴

30. `typ: "JWE"` → 401
31. `typ: "JOSE+JSON"` → 401
32. `crit: ["unknown-ext"]` → 401
33. JSON malformado em qualquer parte → 401
34. Base64 inválido em qualquer parte → 401
35. `kid` desconhecido → exatamente 1 refetch JWKS, depois 401
36. `kid` ausente quando JWKS tem múltiplas chaves → 401
37. `kid` válido mas signature feita com outra chave do JWKS (kid-key mismatch) → 401

### E. Resource Exhaustion — 3 testes 🔴

38. Token > 8KB → 401 antes de parsear
39. Payload com JSON aninhado >10 níveis → 401
40. `roles` array com 10.000 entradas → bounded ou 401

### F. Transport & Pipeline — 6 testes

41. Token em `?access_token=...` → 401 (não aceitar query)
42. Scheme `Basic <token>` → 401
43. Scheme `Bearer ` (vazio) → 401
44. Bearer válido + cookie de sessão → usa Bearer, **ignora cookie totalmente** (verificar via flag observada)
45. Bearer inválido + cookie válido → **401, NÃO fallback** (lacuna 3)
46. Bearer ausente + cookie válido → usa cookie

### G. JWKS Cache — 5 testes

47. Concorrência: 100 requests simultâneos no cold start → 1 só fetch do JWKS (single-flight)
48. JWKS endpoint timeout (5s) → fail closed, 401
49. JWKS retorna JSON inválido → fail closed, 401
50. Rotation: `kid` antigo válido até cache TTL expirar
51. Refresh on signature mismatch: `kid` conhecido mas sig falha → 1 refetch, retry, depois 401

### H. Observability/Privacy — 3 testes

52. Capturar logs do middleware → token completo NÃO aparece
53. Resposta 401 → body genérico, sem claim/motivo específico
54. Stack trace de erro → não vaza secret nem JWKS interno

## Critérios de aceitação

- [ ] 54 tests GREEN
- [ ] `dart analyze apps/social_care_bff/web/lib/` zero issues
- [ ] BFF Web baseline preservado (1075 GREEN existentes não regridem)
- [ ] Total esperado: ~1129 GREEN no BFF Web (1075 + 54)
- [ ] Cookie path 100% intocado
- [ ] W0.5 red-team-scanner: APPROVED
- [ ] REPORT.md em `tickets/C00-bearer-middleware/REPORT.md` com:
  - Decisões D1-D7 + D7.1 cristalizadas
  - 10 constraints de segurança
  - 54 test results
  - Pré-requisitos de infra (NATIVE_API client_id no Zitadel, env var `OIDC_CLI_CLIENT_ID`)
  - Trade-offs vivenciados

## Pré-requisitos de infra (out-of-band)

- ✅ NATIVE_API existente no Zitadel (confirmado pelo usuário 2026-05-01)
- 🟡 Bitwarden Secret Manager: provisionar `OIDC_CLI_CLIENT_ID` para DEV/STG/PROD do BFF Web
- 🟡 `.env.example` documentando a nova var

## Status
ready — kickoff aguardando green light final do usuário
