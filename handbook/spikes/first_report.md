# Relatório Completo — Validação OIDC/PKCE do CLI ACDG no Zitadel

> **Tipo:** Verificação end-to-end de Native App PKCE no Zitadel self-hosted
> **Data:** 2026-05-04 (executado às ~03:00–03:08 BRT)
> **Executor:** Claude Code (Opus 4.7)
> **Instância:** `https://auth.acdgbrasil.com.br` (Zitadel self-hosted)
> **Diretório de artefatos:** `~/tmp/acdg-cli-zitadel-verify/`

---

## 1. Sumário Executivo

### Veredicto: ❌ Setup NÃO está pronto pro CLI

Foram executadas as 11 fases planejadas. **9 passaram**, **2 falharam de forma crítica** e há **7 avisos** que precisam de decisão arquitetural. O bloqueio é no Admin Console do Zitadel — não no código que ainda nem foi escrito.

| Severidade | Issue | Resumo |
|------------|-------|--------|
| 🔴 CRÍTICO | F1 — PKCE não enforced | App aceita exchange sem `code_verifier`; rejeita com. PKCE não está habilitado no app. |
| 🔴 CRÍTICO | F2 — Sem `refresh_token` | Apesar de `offline_access` no scope, resposta vem sem refresh — CLI forçaria re-login a cada 12h. |
| 🟡 AVISO | A1 — Access token sem `email`/`email_verified` | Só id_token e /userinfo carregam email. BFF precisa decidir estratégia. |
| 🟡 AVISO | A2 — Access token sem `azp` | Presente no id_token. Não bloqueia, mas validators que exigem `azp` precisam relaxar. |
| 🟡 AVISO | A3 — 12 de 13 roles esperadas | Falta `admin`. Pode ser ausência real ou expectativa errada. |
| 🟡 AVISO | A4 — `aud` com 9 entries | BFF deve validar `contains`, não match exato. Project ID está presente. |
| 🟡 AVISO | A5 — `nonce` ausente no id_token | Possivelmente artefato do prefetch RSC; revalidar após F1+F2. |
| 🟡 AVISO | A6 — RSC prefetch da UI Zitadel | Vaza `code` (sem `state`) em `/callback` antes do user clicar. CLI precisa de listener robusto. |
| 🟡 AVISO | A7 — Redirect URI sem porta registrada | Funcionou (RFC 8252 §7.3), mas vale documentar a expectativa. |

### Validações que passaram

- ✅ Discovery do issuer
- ✅ Endpoints OIDC (authorize, token, userinfo, jwks)
- ✅ Suporte a `S256` PKCE no servidor
- ✅ Suporte a auth method `none`
- ✅ JWKS legível, `kid` do JWT presente
- ✅ Issuer match exato (sem trailing slash)
- ✅ Token type `Bearer`
- ✅ `aud` contém Project ID (scope mágico funcionou)
- ✅ `/userinfo` retorna 200 com email, name, roles consolidadas
- ✅ Loopback com porta arbitrária aceito (RFC 8252 §7.3)

---

## 2. Configuração testada

### Parâmetros (do prompt original)

```
ISSUER          = https://auth.acdgbrasil.com.br
CLIENT_ID       = 371410163745226755
PROJECT_ID      = 363109883022671995
REDIRECT_URI    = http://127.0.0.1:8765/callback
SCOPES          = openid profile email offline_access
                  urn:zitadel:iam:org:project:id:363109883022671995:aud
```

### App esperado (segundo o prompt)

| Setting | Esperado |
|---------|----------|
| Tipo | Native |
| Authentication Method | None (PKCE-only, sem secret) |
| Grant Types | Authorization Code + Refresh Token |
| Response Types | Code |
| Redirect URIs | `http://127.0.0.1/callback`, `http://[::1]/callback` |
| Token type | JWT (não opaque) |
| Roles e User Info incluídos no token | Sim |

### Ambiente do executor

```
OS:       darwin 25.3.0
Shell:    zsh
curl:     8.7.1 (LibreSSL/3.3.6)
jq:       jq-1.7.1-apple
openssl:  OpenSSL 3.6.1 (27 Jan 2026)
python3:  3.14.3
```

### Identidade testada

- **Sub:** `363088829932634233`
- **Email:** gaderaldo10@gmail.com (verified)
- **Username:** gabriel.aderaldo@acdgbrasil.com.br
- **Name:** Gabriel Aderaldo | Super Admin

### Sobre o `.env` recebido

O arquivo `.env` no diretório do projeto contém:
```
SECRET_CLIENT_ID=371410163745226755
```

A nomenclatura é enganosa — o valor é **client_id** (público), não secret. Bate exatamente com o `CLIENT_ID` do prompt. Foi tratado como `client_id`, **nunca** enviado como `client_secret` (PKCE-only). Recomendo renomear pra `OIDC_CLI_CLIENT_ID` pra evitar futuras confusões.

---

## 3. Timeline da execução

| Hora local | Fase | Resultado |
|-----------|------|-----------|
| 03:00:24 | FASE 0 — deps | ✅ todas presentes |
| 03:00:30 | FASE 1 — discovery | ✅ HTTP 200, 2328 bytes em 313ms |
| 03:01:08 | FASE 2 — PKCE gen | ✅ verifier+challenge+state+nonce gerados, chmod 600 |
| 03:01:30 | FASE 3 — listener (try 1) | ✅ subiu em :8765 |
| 03:02:15 | FASE 4 — authorize URL printada | ✅ aguardando user |
| 03:02:36 | callback try 1 | ❌ state vazio (RSC prefetch) — listener morreu sem code válido |
| 03:03:00 | FASE 3 — listener (try 2) | ✅ ressubiu, mesmo state/nonce |
| 03:04:00 | callback try 2 | ❌ mesmo problema, mas log revelou `_rsc=dcpyb` e `code` real |
| 03:04:30 | FASE 5 — exchange COM verifier | ❌ HTTP 400 `code_verifier unexpectedly provided` |
| 03:05:00 | FASE 5b — exchange SEM verifier | ⚠️ HTTP 200 — confirmou ausência de PKCE enforcement |
| 03:05:15 | FASE 6 — decode access_token | ⚠️ tokens redacted, claims incompletas |
| 03:05:30 | FASE 7 — decode id_token | ⚠️ nonce ausente, mas tem profile completo |
| 03:05:45 | FASE 8 — JWKS | ✅ 2 keys, kid casa |
| 03:06:00 | FASE 9 — refresh grant | ❌ não há refresh_token pra testar |
| 03:06:15 | FASE 10 — /userinfo | ✅ HTTP 200, payload completo |
| 03:08:00 | FASE 11 — cleanup + relatório | ✅ |

**Tempo total ativo:** ~8 min (excluindo espera por user no browser).

---

## 4. Evidências brutas

### 4.1 Discovery (resumo)

`GET https://auth.acdgbrasil.com.br/.well-known/openid-configuration` → 200

Endpoints relevantes:

| Campo | Valor |
|-------|-------|
| `issuer` | `https://auth.acdgbrasil.com.br` |
| `authorization_endpoint` | `https://auth.acdgbrasil.com.br/oauth/v2/authorize` |
| `token_endpoint` | `https://auth.acdgbrasil.com.br/oauth/v2/token` |
| `userinfo_endpoint` | `https://auth.acdgbrasil.com.br/oidc/v1/userinfo` |
| `jwks_uri` | `https://auth.acdgbrasil.com.br/oauth/v2/keys` |
| `revocation_endpoint` | `https://auth.acdgbrasil.com.br/oauth/v2/revoke` |
| `end_session_endpoint` | `https://auth.acdgbrasil.com.br/oidc/v1/end_session` |
| `device_authorization_endpoint` | `https://auth.acdgbrasil.com.br/oauth/v2/device_authorization` |
| `introspection_endpoint` | `https://auth.acdgbrasil.com.br/oauth/v2/introspect` |

Capabilities:

- `grant_types_supported`: `authorization_code`, `implicit`, `refresh_token`, `client_credentials`, `urn:ietf:params:oauth:grant-type:jwt-bearer`, `urn:ietf:params:oauth:grant-type:device_code`
- `code_challenge_methods_supported`: **`S256`** (sem `plain`, ✅)
- `token_endpoint_auth_methods_supported`: `none`, `client_secret_basic`, `client_secret_post`, `private_key_jwt`
- `id_token_signing_alg_values_supported`: `EdDSA`, `RS256`, `RS384`, `RS512`, `ES256`, `ES384`, `ES512`
- `subject_types_supported`: `public` (sub estável e visível, vs `pairwise`)
- `response_types_supported`: `code`, `id_token`, `id_token token`
- `response_modes_supported`: `query`, `fragment`, `form_post`
- `scopes_supported`: `openid`, `profile`, `email`, `phone`, `address`, `offline_access`
- `claims_supported`: inclui `sub`, `email`, `name`, `azp`, `nonce`, `at_hash`, etc.
- `backchannel_logout_supported`: `true`
- `request_parameter_supported`: `true` (mas `request_uri_parameter_supported`: `false`)

**Bonus descoberto:** o Zitadel suporta **Device Authorization Grant** (`urn:ietf:params:oauth:grant-type:device_code`). É o flow ideal para CLI quando o user não tem browser na mesma máquina (ex: SSH em servidor). Não foi pedido no prompt, mas vale considerar.

### 4.2 PKCE gerado

```
verifier   = 86 chars (b64url no-pad de 64 random bytes)
challenge  = 43 chars (b64url no-pad do SHA-256 do verifier)
state      = 64 hex chars (32 random bytes)
nonce      = 64 hex chars (32 random bytes)
```

Salvos em `/tmp/acdg-pkce-{verifier,challenge,state,nonce}` com `chmod 600`. Removidos no cleanup.

### 4.3 Authorize URL gerada

```
https://auth.acdgbrasil.com.br/oauth/v2/authorize
  ?response_type=code
  &client_id=371410163745226755
  &redirect_uri=http%3A%2F%2F127.0.0.1%3A8765%2Fcallback
  &scope=openid%20profile%20email%20offline_access%20urn%3Azitadel%3Aiam%3Aorg%3Aproject%3Aid%3A363109883022671995%3Aaud
  &state=ed9596555fda3a1e454f14c17526b87bdae65583931eb589e314401324d929e7
  &nonce=6d3fac8265cbb155539fc6e5979bacbf38ebc4806b7e5d4853658bc2a91a0fcb
  &code_challenge=1lyJssBPkXN2oYEPGHAtIWtFQHGdrlg-UDbhLnIRD_g
  &code_challenge_method=S256
```

### 4.4 Log do listener (revelando RSC prefetch)

```
[listener] listening on http://127.0.0.1:8765/callback
[listener] code 501, message Unsupported method ('OPTIONS')
[listener] "OPTIONS /callback?code=gEMwnViWV8MAfqcLEu9VSMgz0swlp-VdsxD82GQzCMq6jYITvQ&state=&_rsc=dcpyb HTTP/1.1" 501 -
[listener] "GET /callback?code=gEMwnViWV8MAfqcLEu9VSMgz0swlp-VdsxD82GQzCMq6jYITvQ&state= HTTP/1.1" 400 -
[listener] one-shot done, exiting
```

**Evidências:**
- `OPTIONS` precedeu `GET` → CORS preflight. Listener naive responde 501.
- Query `_rsc=dcpyb` → fingerprint do **Next.js RSC** (React Server Components). A UI de login do Zitadel é Next.js e dispara prefetch.
- `state=` **vazio** em ambos os hits → o `state` não foi propagado pro prefetch. Mas o `code` foi.
- O listener morreu após o `GET` 400 (one-shot), antes de o user efetivamente concluir o login.

### 4.5 Token endpoint — exchange COM `code_verifier`

**Request:**
```http
POST /oauth/v2/token HTTP/1.1
Host: auth.acdgbrasil.com.br
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code
&code=gEMwnViWV8MAfqcLEu9VSMgz0swlp-VdsxD82GQzCMq6jYITvQ
&redirect_uri=http%3A%2F%2F127.0.0.1%3A8765%2Fcallback
&client_id=371410163745226755
&code_verifier=<86-char base64url verifier>
```

**Response:**
```http
HTTP/1.1 400 Bad Request
Content-Type: application/json

{
  "error": "invalid_request",
  "error_description": "code_verifier unexpectedly provided"
}
```

### 4.6 Token endpoint — exchange SEM `code_verifier`

**Request:** mesmo, sem o param `code_verifier`.

**Response:**
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "access_token": "<JWT redacted>",
  "id_token":     "<JWT redacted>",
  "token_type":   "Bearer",
  "expires_in":   43199
  // ⚠️ AUSENTES: refresh_token, scope
}
```

`expires_in: 43199` ≈ 12h. Sem `refresh_token` apesar de `offline_access` ter sido pedido.

### 4.7 Access token decodificado

**Header:**
```json
{ "alg": "RS256", "kid": "363088832046039161", "typ": "JWT" }
```

**Payload (campos presentes):**
| Claim | Valor | OK? |
|-------|-------|-----|
| `iss` | `https://auth.acdgbrasil.com.br` | ✅ |
| `sub` | `363088829932634233` | ✅ |
| `client_id` | `371410163745226755` | ✅ |
| `aud` | array com 9 IDs incluindo Project ID `363109883022671995` | ⚠️ A4 |
| `iat` | 1777874715 | ✅ |
| `exp` | 1777917915 (Δ = 43200s = 12h) | ✅ |
| `nbf` | 1777874715 | ✅ |
| `jti` | `V2_371411852103516163-at_371411852103581699` | ✅ |
| `urn:zitadel:iam:org:project:roles` | objeto com 12 roles | ⚠️ A3 |
| `urn:zitadel:iam:org:project:363109883022671995:roles` | objeto com 12 roles (duplicado) | ✅ |

**Payload (campos ESPERADOS mas AUSENTES):**
| Claim | Esperado em | Implicação |
|-------|-------------|------------|
| `azp` | RFC OIDC: opcional em access_token (oficial só em id_token) | Aviso A2 |
| `email` | Esperado pelo prompt | **A1 — bloqueia auth via JWT-only** |
| `email_verified` | Esperado pelo prompt | **A1** |
| `name` / profile | Esperado pelo prompt | A1 |

### 4.8 ID token decodificado

**Header:** mesmo do access (`RS256`, kid `363088832046039161`).

**Payload (campos presentes):**

| Claim | Valor |
|-------|-------|
| `iss` | `https://auth.acdgbrasil.com.br` |
| `sub` | `363088829932634233` |
| `azp` | `371410163745226755` ✅ |
| `aud` | mesma lista de 9 do access |
| `amr` | `["pwd"]` |
| `auth_time` | 1777874657 |
| `at_hash` | `dlyWnrZMBBQ_lTaGdsuihQ` (hash do access_token) ✅ |
| `iat` | 1777874715 |
| `exp` | 1777917915 |
| `email` | `gaderaldo10@gmail.com` ✅ |
| `email_verified` | `true` ✅ |
| `name` | `Gabriel Aderaldo \| Super Admin` |
| `family_name` | `Vieira Soriano Aderaldo` |
| `given_name` | `Gabriel` |
| `nickname` | `Gabriel Aderaldo` |
| `gender` | `male` |
| `locale` | `en` |
| `preferred_username` | `gabriel.aderaldo@acdgbrasil.com.br` |
| `sid` | `371411741139009539` (session id) |
| `updated_at` | 1776154976 |
| `client_id` | `371410163745226755` |
| `urn:...roles` | mesmas 12 roles (em duas chaves) |

**Payload (AUSENTE):**
- `nonce` ❌ — Aviso A5 (RFC OIDC §3.1.3.7 #11 exige se nonce foi enviado)

### 4.9 JWKS

```json
{
  "keys": [
    {
      "use": "sig", "kty": "RSA", "alg": "RS256",
      "kid": "363088832046039161",
      "n":   "vNwVmsDvfrfsswV1wJoAIeEwJoSlqK0e...nu5NgykZLMlhXPewAZWUZ7LQDeGMRk7IIWtpU9ojUjKFQ-mhp-hu9NJW1o2jHFDdw0o2PyrI84jxoloxbT9xQ027w",
      "e":   "AQAB"
    },
    {
      "use": "sig", "kty": "RSA", "alg": "RS256",
      "kid": "363088832632979577",
      "n":   "rGoIh-wzF217zFOUfRTNJFOjtVMMA21Y...LXBOiHrO0CGQJkc3dVNDQLPHdrPBlTZVdzaKS4edMwavPd18emwh1Xo3vh6vUgw",
      "e":   "AQAB"
    }
  ]
}
```

O `kid` do header dos JWTs (`363088832046039161`) ✅ está presente no JWKS. Duas chaves indicam rotação preparada (uma ativa, uma stand-by).

### 4.10 Userinfo

**Request:**
```http
GET /oidc/v1/userinfo HTTP/1.1
Host: auth.acdgbrasil.com.br
Authorization: Bearer <access_token>
```

**Response:** HTTP 200, payload completo:
```json
{
  "sub": "363088829932634233",
  "email": "gaderaldo10@gmail.com",
  "email_verified": true,
  "name": "Gabriel Aderaldo | Super Admin",
  "family_name": "Vieira Soriano Aderaldo",
  "given_name": "Gabriel",
  "nickname": "Gabriel Aderaldo",
  "preferred_username": "gabriel.aderaldo@acdgbrasil.com.br",
  "gender": "male",
  "locale": "en",
  "updated_at": 1776154976,
  "urn:zitadel:iam:org:project:roles":            { ...12 roles... },
  "urn:zitadel:iam:org:project:363109883022671995:roles": { ...12 roles... }
}
```

### 4.11 Roles encontradas vs esperadas

**Esperadas (13 segundo o prompt):**
```
admin, owner, superadmin, social_worker,
social-care:admin, social-care:worker, social-care:owner,
people-context:admin, people-context:worker, people-context:owner,
analysis-bi:admin, analysis-bi:analyst, analysis-bi:exporter
```

**Encontradas (12):**
```
✅ owner
✅ superadmin
✅ social_worker
✅ social-care:admin
✅ social-care:worker
✅ social-care:owner
✅ people-context:admin
✅ people-context:worker
✅ people-context:owner
✅ analysis-bi:admin
✅ analysis-bi:analyst
✅ analysis-bi:exporter
❌ admin  ← faltando
```

Cada role é mapeada como objeto: `{ "<orgId>": "<orgDomain>" }` — formato Zitadel padrão. Org ID `363109592139300987`, domain `acdg.auth.acdgbrasil.com.br`.

---

## 5. Findings detalhadas

### 🔴 F1 — PKCE não está enforced no app

**Severidade:** Crítica
**Categoria:** Authentication / Configuration

#### Evidência

Duas requests idênticas, exceto pelo `code_verifier`:

| Tentativa | code_verifier? | HTTP | Body |
|-----------|---------------|------|------|
| Com PKCE | sim | **400** | `{"error":"invalid_request","error_description":"code_verifier unexpectedly provided"}` |
| Sem PKCE | não | **200** | Tokens emitidos |

#### Análise

O Zitadel rejeita explicitamente o `code_verifier` quando o app não está configurado pra PKCE. Esse erro não é o esperado — em apps PKCE-only, ausência de verifier deveria dar `invalid_request: pkce_required` ou similar, e presença deveria validar a hash.

A causa-raiz é: o app está como **public sem PKCE**. Em Zitadel, "Authentication Method: None" sozinho **não** ativa PKCE — é só uma flag de "client público sem secret". PKCE é uma config separada.

#### Por que importa

CLI distribuído tem 0 segredo opaco no binário. O único defesa contra "um malware local intercepta o code no `/callback` loopback e troca por tokens" **é** o PKCE: o malware não consegue forjar o verifier (pré-imagem do challenge SHA-256).

Sem PKCE, qualquer processo na máquina que escute :8765 antes do listener legítimo, ou que faça MITM no loopback (improvável mas possível em multi-user), pega o `code` e gera tokens válidos.

#### Como corrigir

No Zitadel Console:

1. Navegar: **Projects → \<seu projeto\> → Applications → \<seu app Native\>**.
2. Aba **Authentication** ou **Configuration** (varia por versão).
3. Localizar **Authentication Method**.
4. Se houver opção `PKCE` separada de `None`: trocar de `None` pra `PKCE`.
5. Se houver checkbox separado **"Force PKCE for code exchange"** ou **"Require PKCE"**: marcar.
6. **Salvar**.

#### Como confirmar o fix

Refazer o teste:
- Exchange **com** `code_verifier` deve retornar **200**.
- Exchange **sem** `code_verifier` deve retornar **400** com `error=invalid_request` + descrição mencionando PKCE.

---

### 🔴 F2 — `refresh_token` não é emitido

**Severidade:** Crítica (UX-bloqueador para CLI)
**Categoria:** Token issuance

#### Evidência

Authorize foi feito com:
```
scope=openid profile email offline_access urn:zitadel:iam:org:project:id:...:aud
```

Resposta do `/token`:
```json
{
  "access_token": "...",
  "id_token":     "...",
  "token_type":   "Bearer",
  "expires_in":   43199
  // refresh_token: AUSENTE
  // scope: null
}
```

O `scope: null` na resposta também é suspeito — RFC 6749 §5.1 diz que o servidor DEVE retornar `scope` se for diferente do solicitado, e MAY se for igual. Ausência total junto com falta de `refresh_token` sugere que o `offline_access` foi **silenciosamente ignorado**.

#### Análise

Possíveis causas, em ordem de probabilidade:

1. **Grant `Refresh Token` não está habilitado no app.** Verificar no console.
2. **Scope `offline_access` não está nos scopes permitidos do app.** Em alguns Zitadels o app tem allow-list de scopes.
3. **Idle/Inactivity timeout zerado** — refresh tokens podem ter sido desabilitados globalmente no project ou no instance.
4. **User precisa consentir explicitamente** o `offline_access` na tela de consent — confirmar se houve consent screen.

#### Por que importa

`expires_in: 43200s` = 12h. Sem refresh, o user faz **re-login interativo (browser)** a cada 12h. Pra CLI usado em script, automação, scheduled jobs, é matador.

Refresh token permite background renewal silencioso por dias/semanas até o refresh em si expirar.

#### Como corrigir

No Zitadel Console:

1. **Projects → \<projeto\> → Applications → \<app\>**.
2. Aba **Token Settings** (ou similar).
3. Verificar se "Refresh Token" está habilitado / TTL > 0.
4. Aba **Grant Types**.
5. Confirmar **Refresh Token** marcado (já era esperado segundo o prompt — revalidar).
6. Aba **Scopes** (se existir): garantir `offline_access` permitido.
7. **Salvar**.

#### Como confirmar o fix

Refazer authorize com `offline_access` no scope. Resposta do `/token` deve trazer `refresh_token` e `scope` populado.

---

### 🟡 A1 — `email`/`email_verified` ausentes no access_token

**Severidade:** Aviso (decisão de arquitetura)
**Categoria:** Claim mapping

#### Evidência

| Token | tem `email`? | tem `email_verified`? |
|-------|-------------|----------------------|
| access_token | ❌ | ❌ |
| id_token | ✅ | ✅ |
| /userinfo | ✅ | ✅ |

#### Análise

No Zitadel, o access_token JWT tipicamente carrega só dados de autorização (sub, aud, roles, scopes). Identidade fica no id_token e em `/userinfo`. Isso é coerente com OIDC — o access_token é "para o backend autorizar", não pra "ler quem é o user".

O prompt esperava email no access_token. Isso só seria possível se houvesse mapping customizado configurado no project ("Action" no Zitadel).

#### Implicação pro Vapor BFF

O `social-care` BFF Swift hoje valida JWT. Se ele precisa do email do user pra audit log ou cross-reference no banco:

- **Opção 1 (recomendada):** No primeiro request da sessão, BFF chama `/userinfo` com o Bearer e cacheia `(sub → email/name)` no Redis/memória por algum tempo. Subsequentes pulam.
- **Opção 2:** Configurar uma Action no Zitadel pra injetar `email` no access_token (mais complexidade, mais surface de bug).
- **Opção 3:** CLI envia `id_token` no header além do `access_token`. Não-padrão, evitar.

**Recomendação:** Opção 1.

---

### 🟡 A2 — `azp` ausente no access_token

**Severidade:** Aviso (decisão de validação)
**Categoria:** Claim mapping

#### Evidência

| Token | `azp` |
|-------|-------|
| access_token | ❌ ausente |
| id_token | ✅ `371410163745226755` |

#### Análise

OIDC Core §2 define `azp` (Authorized Party) como **claim de id_token**, não de access_token. Ausência no access_token é **conforme spec**. Algumas libs JWT validam `azp` no access_token erroneamente — se a `vapor/jwt` no `social-care` faz isso, vai precisar relaxar.

#### Mitigação

- No BFF, validar `aud` (presença do Project ID) e `client_id` (caso a lib use), **não** `azp` no access_token.

---

### 🟡 A3 — 12 roles em vez de 13 esperadas

**Severidade:** Aviso (verificação de expectativa)
**Categoria:** RBAC

#### Falta: `admin`

#### Análise

A lista esperada inclui `admin` separado de `superadmin`/`owner`. Possíveis motivos:

1. A role `admin` simplesmente **não existe** nesse project — foi `superadmin` no lugar e o prompt está desatualizado.
2. A role existe mas **não foi atribuída** a esse user.
3. A role existe e foi atribuída em **outra org**, mas só roles da org corrente aparecem no token.

#### Próximo passo

Verificar no Zitadel Console: **Project → Roles**. Se `admin` não estiver listado, ajustar a expectativa para 12 roles.

---

### 🟡 A4 — `aud` com 9 entries

**Severidade:** Informativo
**Categoria:** Token shape

#### Evidência

```json
"aud": [
  "363678038996549834", "363679353508266186", "363684701061251274",
  "363110312318140539", "367375117048610966", "367617280390987926",
  "367349956392059030",
  "371410163745226755",   // CLI client_id
  "363109883022671995"    // Project ID (esperado)
]
```

#### Análise

O scope mágico `urn:zitadel:iam:org:project:id:<PROJECT_ID>:aud` **funcionou**: o Project ID foi adicionado ao `aud`. Os outros 7 IDs são provavelmente outros applications no mesmo project (cada app no Zitadel tem ID próprio e pode aparecer em `aud` se o user tem grants).

#### Implicação pro BFF

Validar:
- ✅ `aud` é array (não string)
- ✅ `aud.contains(PROJECT_ID)` — não match exato
- ❌ NÃO validar `aud.length == 1`
- ❌ NÃO validar `aud == [<algum valor único>]`

---

### 🟡 A5 — `nonce` ausente no id_token

**Severidade:** Aviso (revalidar após F1+F2)
**Categoria:** RFC compliance

#### Análise

OIDC Core §3.1.3.7 #11: *"if a nonce value was sent in the Authentication Request, a nonce Claim MUST be present and its value checked"*.

Enviei `nonce=6d3fac8...` no authorize. Id_token veio sem nonce.

**MAS:** o `code` que conseguimos veio do **prefetch RSC do Next.js** (vide A6) — não é o flow normal completo. É possível que:

- O prefetch enviou um authorize "alternativo" sem nonce, e o code retornado não está vinculado ao nonce original.
- Ou Zitadel realmente não está propagando nonce.

**Plano:** revalidar após F1+F2 corrigidos, com flow normal completo.

#### Por que importa

Sem nonce no id_token, ataques de replay/swap de id_token entre sessões ficam possíveis (mesmo improváveis em flow code+PKCE). É defense-in-depth.

---

### 🟡 A6 — RSC prefetch da UI Zitadel quebra listener naive

**Severidade:** Aviso de implementação (CLI Dart)
**Categoria:** Loopback callback handling

#### Evidência

Log do listener:
```
"OPTIONS /callback?code=gEMw...&state=&_rsc=dcpyb HTTP/1.1" 501
"GET /callback?code=gEMw...&state= HTTP/1.1" 400
```

Características do request "fake":
- Método `OPTIONS` antes de `GET` (CORS preflight).
- Query inclui `_rsc=` (fingerprint Next.js React Server Components).
- `state=` **vazio**.
- `code` real, ainda não consumido pelo `/token`.

#### Análise

A UI de login do Zitadel é Next.js. Quando o navegador renderiza a página de "Authorize", o RSC **prefetch** o redirect_uri pra otimizar perceived latency. Isso bate em `/callback` antes do user clicar em qualquer coisa.

#### Implicação de segurança

O `code` é **vazado pro loopback** antes do user concluir interação. Em si, não é vulnerabilidade do PKCE (sem o `code_verifier`, exchange falha). Mas:

- O `code` aparece em logs de listeners ingênuos.
- Cuidado pra não logar query strings de `/callback`.

#### Implicação pra implementação do CLI

O listener Python que usei era **one-shot** — consumia o primeiro hit e morria. Resultado: o prefetch matou o listener antes do user clicar.

**O CLI Dart precisa de um listener mais inteligente.** Ver Seção 8 abaixo.

---

### 🟡 A7 — Redirect URI registrado sem porta

**Severidade:** Informativo
**Categoria:** RFC 8252 conformance

#### Evidência

App tem `http://127.0.0.1/callback` (sem porta) registrado. Teste usou `:8765`. Funcionou.

#### Análise

RFC 8252 §7.3 (OAuth for Native Apps) explicita que para `127.0.0.1` e `[::1]`, o servidor de auth **deve** aceitar qualquer porta efêmera, mesmo que a registrada não tenha porta. Zitadel honra isso ✅.

Implicação: o CLI pode bind em porta efêmera (`0`), recuperar a porta atribuída pelo OS, e construir o `redirect_uri` dinamicamente.

---

## 6. Validações que passaram (confirmações ✅)

| # | Verificação | Resultado |
|---|-------------|-----------|
| OK1 | Issuer match exato (sem trailing slash) | ✅ `https://auth.acdgbrasil.com.br` |
| OK2 | `code_challenge_methods_supported` inclui `S256` | ✅ |
| OK3 | `token_endpoint_auth_methods_supported` inclui `none` | ✅ |
| OK4 | `grant_types_supported` inclui `authorization_code` + `refresh_token` | ✅ |
| OK5 | JWKS acessível, retorna 2 keys RSA RS256 | ✅ |
| OK6 | `kid` do JWT presente no JWKS | ✅ `363088832046039161` |
| OK7 | Token type retornado é `Bearer` | ✅ |
| OK8 | `expires_in` razoável (43200s = 12h) | ✅ |
| OK9 | `aud` contém o Project ID (scope mágico funcionou) | ✅ |
| OK10 | `/userinfo` autentica com Bearer e retorna 200 | ✅ |
| OK11 | `sub` é consistente entre access, id_token e userinfo | ✅ `363088829932634233` |
| OK12 | RFC 8252 §7.3 — porta loopback arbitrária aceita | ✅ |
| OK13 | Discovery completo, todos endpoints presentes | ✅ |
| OK14 | `at_hash` presente no id_token | ✅ |
| OK15 | `auth_time`, `amr` presentes no id_token | ✅ |

---

## 7. Tabela de conformidade

### Vs. RFC 6749 (OAuth 2.0)

| Item | Esperado | Observado |
|------|----------|-----------|
| `code` flow funciona | sim | ✅ sim |
| `refresh_token` quando `offline_access` solicitado | sim | ❌ não emitido |
| `scope` retornado em /token quando difere | quando difere | ⚠️ veio `null` |
| `error`/`error_description` em falhas | sim | ✅ sim |

### Vs. RFC 7636 (PKCE)

| Item | Esperado | Observado |
|------|----------|-----------|
| Suporte a `S256` no servidor | sim | ✅ |
| App público com PKCE enforced | sim | ❌ **F1** |
| Verifier 43–128 chars b64url no-pad | usar | ✅ usado (86 chars) |
| Challenge = b64url(sha256(verifier)) | sim | ✅ |

### Vs. RFC 8252 (OAuth for Native Apps)

| Item | Esperado | Observado |
|------|----------|-----------|
| Loopback IP redirect com porta arbitrária | aceitar | ✅ A7 |
| Authorization Code + PKCE pra native | obrigatório | ❌ PKCE não enforced (F1) |
| Custom URL schemes / claimed HTTPS | opcional | (não testado) |

### Vs. OIDC Core 1.0

| Item | Esperado | Observado |
|------|----------|-----------|
| `id_token` quando `openid` no scope | sim | ✅ |
| `nonce` no id_token quando enviado no authorize | obrigatório | ❌ **A5** |
| `at_hash` quando access_token retornado junto | obrigatório | ✅ |
| `azp` no id_token quando aud > 1 ou multi-client | obrigatório | ✅ |
| `/userinfo` com Bearer | obrigatório | ✅ |

---

## 8. Recomendações pro CLI Dart

### 8.1 Discovery dinâmico no boot

Não hardcode endpoints. Faça `GET /.well-known/openid-configuration` no startup, valide `issuer == OIDC_ISSUER`, e use os endpoints da resposta.

```dart
class OidcDiscovery {
  final String issuer;
  final String authorizationEndpoint;
  final String tokenEndpoint;
  final String jwksUri;
  final String userinfoEndpoint;
  final String endSessionEndpoint;

  static Future<OidcDiscovery> load(String issuer) async {
    final url = '$issuer/.well-known/openid-configuration';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) throw OidcException('discovery_failed', res.body);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    if (j['issuer'] != issuer) {
      throw OidcException('issuer_mismatch', '${j['issuer']} != $issuer');
    }
    return OidcDiscovery(
      issuer: j['issuer'],
      authorizationEndpoint: j['authorization_endpoint'],
      tokenEndpoint: j['token_endpoint'],
      jwksUri: j['jwks_uri'],
      userinfoEndpoint: j['userinfo_endpoint'],
      endSessionEndpoint: j['end_session_endpoint'],
    );
  }
}
```

### 8.2 PKCE com S256 apenas

```dart
String _b64Url(List<int> bytes) =>
    base64UrlEncode(bytes).replaceAll('=', '');

({String verifier, String challenge}) generatePkce() {
  final rand = Random.secure();
  final bytes = List<int>.generate(64, (_) => rand.nextInt(256));
  final verifier = _b64Url(bytes);
  final challenge = _b64Url(sha256.convert(utf8.encode(verifier)).bytes);
  return (verifier: verifier, challenge: challenge);
}
```

Recusar fallback `plain` (não usar `code_challenge_method=plain` jamais).

### 8.3 Listener loopback robusto

Crítico — pq A6 mostrou que one-shot ingênuo quebra. Requirements:

1. **Bind em porta efêmera** (`0`), recuperar porta real, montar `redirect_uri` com ela.
2. **Aceitar múltiplos hits** durante a janela.
3. **Filtrar/ignorar** hits inválidos:
   - Método != `GET`
   - Path != `/callback`
   - Query contém `_rsc=` (Next.js prefetch)
   - `state` ausente ou vazio
   - `state != expected` (CSRF guard)
4. **Só fechar** após receber `GET /callback` com `state == expected` e `code` não vazio.
5. **Timeout total** ~5min, com cancelamento via Ctrl+C handler.
6. **NÃO logar** query strings de `/callback`.

```dart
Future<String> awaitAuthCode({
  required String expectedState,
  required Duration timeout,
}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final port = server.port;

  final completer = Completer<String>();
  final timer = Timer(timeout, () {
    if (!completer.isCompleted) {
      completer.completeError(TimeoutException('callback timeout'));
    }
  });

  server.listen((req) async {
    if (req.method != 'GET' || req.uri.path != '/callback') {
      req.response.statusCode = 404;
      await req.response.close();
      return;
    }
    final q = req.uri.queryParameters;
    if (q.containsKey('_rsc')) {
      // Next.js RSC prefetch — drain silently
      req.response.statusCode = 204;
      await req.response.close();
      return;
    }
    if (q['error'] != null) {
      req.response..statusCode = 400
        ..write('<h1>Auth error: ${_esc(q['error']!)}</h1>');
      await req.response.close();
      if (!completer.isCompleted) {
        completer.completeError(OidcException(q['error']!, q['error_description'] ?? ''));
      }
      return;
    }
    final state = q['state'] ?? '';
    final code = q['code'] ?? '';
    if (state.isEmpty || state != expectedState || code.isEmpty) {
      // Likely prefetch or stray request — ignore, keep listening
      req.response.statusCode = 204;
      await req.response.close();
      return;
    }
    req.response..statusCode = 200
      ..headers.contentType = ContentType.html
      ..write(_loginOkHtml());
    await req.response.close();
    if (!completer.isCompleted) completer.complete(code);
  });

  try {
    return await completer.future;
  } finally {
    timer.cancel();
    await server.close(force: true);
  }
}
```

### 8.4 Validação JWT do BFF

No CLI, basta confiar no `/token` HTTPS pra obter o JWT. **Validar localmente** se quiser:
- `iss` exato match
- `aud.contains(PROJECT_ID)` — não match exato
- `exp` futuro com clock skew tolerável (~30s)
- `nbf` no passado
- Assinatura RS256 contra JWKS (com cache + refresh em rotação de kid)
- **NÃO** validar `azp` no access_token (A2)

No **Vapor BFF**, validação rigorosa é onde realmente importa. Mesmo conjunto de regras.

### 8.5 Storage de tokens

Não em arquivo plaintext. Use:
- **macOS:** Keychain (via `flutter_secure_storage` ou FFI direto pra Security framework)
- **Linux:** Secret Service / libsecret / KWallet
- **Windows:** DPAPI / Credential Manager

Estrutura mínima por sessão:
```dart
class OidcSession {
  final String accessToken;        // 12h TTL
  final String refreshToken;       // dias/semanas
  final String idToken;            // sub, name, email
  final DateTime accessExpiresAt;
  final String sub;                 // user id
}
```

### 8.6 Refresh com retry/backoff

```dart
Future<OidcSession> refresh(OidcSession current) async {
  final res = await http.post(
    Uri.parse(discovery.tokenEndpoint),
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: {
      'grant_type': 'refresh_token',
      'refresh_token': current.refreshToken,
      'client_id': clientId,
      'scope': scopes,
    },
  );
  if (res.statusCode == 400) {
    final body = jsonDecode(res.body);
    if (body['error'] == 'invalid_grant') {
      throw NeedsReloginException();
    }
    throw OidcException(body['error'], body['error_description'] ?? '');
  }
  if (res.statusCode >= 500) {
    // retry with exponential backoff up to 3x
    ...
  }
  if (res.statusCode != 200) {
    throw OidcException('refresh_unexpected', '${res.statusCode}: ${res.body}');
  }
  return _parseSession(res.body);
}
```

### 8.7 `/userinfo` no primeiro login

Mostrar pro user logado (UX):
```
$ acdg-cli login
Opening browser...
✅ Logged in as Gabriel Aderaldo (gabriel.aderaldo@acdgbrasil.com.br)
   Roles: superadmin, owner, social_worker, social-care:admin (+8 more)
   Token expires in 12h, refresh until 7 days
```

### 8.8 Logging seguro

**Whitelisted:** `kid`, `sub`, `expires_at`, `client_id`, log de fluxo (etapas).

**Banido:** query string de `/callback`, `code`, `code_verifier`, `state`, `nonce`, `access_token`, `id_token`, `refresh_token`, qualquer JWT inteiro.

Para debugging, log primeiros 8 + últimos 4 chars de tokens, **nunca** o middle.

### 8.9 Considerar Device Authorization Grant (bonus)

Discovery mostra que Zitadel suporta `urn:ietf:params:oauth:grant-type:device_code`. Para CLI usado em ambientes sem browser local (SSH, container), Device Code Flow (RFC 8628) é a UX correta:

```
$ acdg-cli login --device
Visit: https://auth.acdgbrasil.com.br/device
Enter code: ABCD-EFGH
Waiting...
```

CLI faz polling no `/token` até o user terminar. Considerar como flow alternativo no CLI.

---

## 9. Bloco `.env` pronto

Já contemplando os fixes pendentes (PKCE, refresh):

```env
# OIDC / Zitadel — CLI ACDG
OIDC_ISSUER=https://auth.acdgbrasil.com.br
OIDC_DISCOVERY=https://auth.acdgbrasil.com.br/.well-known/openid-configuration

# Endpoints (confirmados; CLI deve fazer discovery dinâmico mesmo assim)
OIDC_AUTHORIZE_ENDPOINT=https://auth.acdgbrasil.com.br/oauth/v2/authorize
OIDC_TOKEN_ENDPOINT=https://auth.acdgbrasil.com.br/oauth/v2/token
OIDC_JWKS_URI=https://auth.acdgbrasil.com.br/oauth/v2/keys
OIDC_USERINFO_ENDPOINT=https://auth.acdgbrasil.com.br/oidc/v1/userinfo
OIDC_END_SESSION_ENDPOINT=https://auth.acdgbrasil.com.br/oidc/v1/end_session
OIDC_DEVICE_AUTH_ENDPOINT=https://auth.acdgbrasil.com.br/oauth/v2/device_authorization
OIDC_REVOCATION_ENDPOINT=https://auth.acdgbrasil.com.br/oauth/v2/revoke

# Identidade do CLI
OIDC_CLI_CLIENT_ID=371410163745226755
OIDC_PROJECT_ID=363109883022671995

# Loopback redirect (porta efêmera substitui {port} em runtime)
OIDC_CLI_REDIRECT_URI_TEMPLATE=http://127.0.0.1:{port}/callback

# Scopes (offline_access garante refresh; scope mágico injeta Project ID em aud)
OIDC_CLI_SCOPES=openid profile email offline_access urn:zitadel:iam:org:project:id:363109883022671995:aud

# Roles claim (Zitadel emite em duas chaves — usar a genérica como primária)
OIDC_ROLES_CLAIM=urn:zitadel:iam:org:project:roles
OIDC_ROLES_CLAIM_PROJECT_SPECIFIC=urn:zitadel:iam:org:project:363109883022671995:roles

# Validação
OIDC_EXPECTED_ISSUER_EXACT=https://auth.acdgbrasil.com.br
OIDC_AUD_MUST_CONTAIN=363109883022671995
OIDC_CLOCK_SKEW_SECONDS=30
```

---

## 10. Checklist de fix (Zitadel Console)

Imprima e tique conforme for fazendo:

- [ ] **F1 — Habilitar PKCE** no Native App (Authentication Method).
- [ ] **F2 — Verificar Refresh Token** em Grant Types e Token Settings.
- [ ] **F2b — Verificar Scopes permitidos** — incluir `offline_access` se houver allow-list.
- [ ] (opcional) **A3** — Confirmar se role `admin` deve existir e atribuir, OU ajustar expectativa pra 12 roles.
- [ ] (opcional) **A4** — Auditar quais 7 outros IDs aparecem em `aud`; reduzir se possível.
- [ ] **Re-rodar este verify** (script base abaixo) e confirmar:
  - Exchange COM `code_verifier` → 200
  - Exchange SEM `code_verifier` → 400
  - `refresh_token` presente na resposta
  - `nonce` presente no id_token (revalida A5)
  - `scope` populado na resposta

---

## 11. Próximos passos sugeridos

### Imediato (você)

1. Aplicar F1 e F2 no Admin Console.
2. Re-rodar este verify (mesmo prompt) e atualizar este relatório.
3. Decidir A3 (role `admin`).

### Depois (codar CLI)

1. Bootstrap projeto Dart com estrutura mínima:
   - `oidc/discovery.dart`
   - `oidc/pkce.dart`
   - `oidc/loopback_listener.dart` (com proteção A6)
   - `oidc/token_client.dart`
   - `oidc/session_store.dart` (Keychain/Secret Service/DPAPI)
   - `oidc/jwt_validator.dart` (RS256 + JWKS cache)
2. Comando `acdg-cli login` end-to-end.
3. Comando `acdg-cli whoami` (lê sessão, mostra dados).
4. Comando `acdg-cli logout` (revoke + clear).
5. Middleware de auto-refresh nos comandos autenticados.

### Médio prazo

1. Implementar Device Code Flow como alternativa (`--device`).
2. Testar com user secundário (sem `superadmin`/`owner`) pra validar RBAC granular.
3. Integrar com BFF Vapor pra validar fluxo completo: CLI → /api → JWT validation → response.

---

## 12. Artefatos gerados

Tudo em `~/tmp/acdg-cli-zitadel-verify/`:

| Arquivo | Conteúdo |
|---------|----------|
| `discovery.json` | OIDC discovery completo (2.3KB) |
| `jwks.json` | JWKS atual (2 keys, 865B) |
| `authorize_url.txt` | URL de authorize gerada |
| `listener.py` | Listener Python one-shot usado |
| `listener.log` | Log do listener — evidência do RSC prefetch |
| `decode_jwt.sh` | Utilitário pra decodificar JWT (header + payload) |
| `token1.json` | Resposta do exchange COM `code_verifier` (400) |
| `token2.json` | Resposta do exchange SEM `code_verifier` (200) |
| `userinfo.json` | Resposta do /userinfo |
| `verify-report.md` | Relatório resumido (versão anterior) |
| `RELATORIO-COMPLETO.md` | **Este arquivo** |

Tokens em `/tmp/acdg-{access,id}-token` — agendar deletion após inspeção.

---

## 13. Apêndice — Exemplo de saída esperada após fix

Pós F1+F2, executando o mesmo verify, espero ver:

```
FASE 5 — Token exchange (com PKCE)
HTTP 200
{
  "access_token": "eyJhbGc...",
  "id_token":     "eyJhbGc...",
  "refresh_token": "v1_...",        ← agora presente
  "token_type":   "Bearer",
  "expires_in":   43199,
  "scope":        "openid profile email offline_access urn:zitadel:iam:org:project:id:363109883022671995:aud"
}

FASE 5b — Token exchange (sem PKCE)  [validação reverso]
HTTP 400
{
  "error": "invalid_request",
  "error_description": "code_verifier required" / similar
}

FASE 6 — Access token
✅ aud contém Project ID
✅ roles 12+ chaves (genérica + específica)
⚠️ email/email_verified ainda ausentes (decisão arquitetural — ok via /userinfo)

FASE 7 — Id token
✅ nonce presente e bate com enviado
✅ azp = client_id
✅ at_hash presente

FASE 9 — Refresh grant
✅ novo access_token (diferente do anterior)
✅ novo refresh_token (rotacionado — antigo invalidado)
✅ mesmas claims

FASE 10 — Userinfo
✅ HTTP 200 com email, name, roles
```

Quando tudo isso passar, o setup do Zitadel está pronto pra implementar o CLI Dart com confiança.

---

**Fim do relatório.**
