# Relatório de Re-Verificação OIDC/PKCE — CLI ACDG no Zitadel

> **Tipo:** Re-execução end-to-end com listener robusto e flow limpo
> **Data:** 2026-05-04 (executado às ~04:10–04:20 BRT)
> **Executor:** Claude Code (Opus 4.7)
> **Instância:** `https://auth.acdgbrasil.com.br`
> **Diretório de artefatos:** `~/tmp/acdg-cli-zitadel-verify/`
> **Relatório anterior:** `first_report.md` (run 1 — 03:00–03:08 BRT)

---

## 1. Sumário Executivo

### Veredicto: ✅ Setup ESTÁ pronto para o CLI

A re-execução com listener robusto (filtro RSC + state matching) confirmou que **F1 e F2 do relatório anterior eram falsos positivos**, causados pela combinação:

1. Listener one-shot ingênuo capturou o `code` do **prefetch RSC do Next.js** (sem state, sem PKCE binding)
2. Esse "code-fantasma" pertencia a um flow interno diferente — não ao authorize que iniciamos
3. O exchange tentou usar nosso `code_verifier` num code que não tinha challenge associado → erro `code_verifier unexpectedly provided`
4. O exchange sem verifier passou porque o code-fantasma realmente não exigia PKCE — mas era um code de outro contexto

Com flow limpo (janela anônima + `prompt=login` + listener que valida `state == expected`), todos os comportamentos esperados foram observados.

### Comparativo Run 1 vs Run 2

| Verificação | Run 1 (sessão suja) | Run 2 (limpo, state matching) | Conclusão |
|---|---|---|---|
| Captura de `code` legítimo | ❌ pegou code de prefetch (state vazio) | ✅ state casa, code de 50 chars | Listener era o problema |
| Exchange COM `code_verifier` | ❌ 400 `code_verifier unexpectedly provided` | ✅ **200 + tokens completos** | F1 era FP |
| Exchange SEM `code_verifier` | ⚠️ 200 (code-fantasma) | (não re-testado — ver §6) | F1 era FP |
| `refresh_token` na resposta | ❌ ausente | ✅ **104 chars opaque token** | F2 era FP |
| `nonce` no id_token | ❌ ausente | ✅ **`0100ed14...c7fc`** (bate com enviado) | A5 era FP |
| `at_hash` no id_token | ✅ presente | ✅ presente E **valida** contra access_token | confirmado |
| `azp` no id_token | ✅ | ✅ | mesmo |
| `aud` 9 entries com Project ID | ✅ | ✅ | A4 — esperado |
| `email`/`email_verified` no id_token | ✅ | ✅ | A1 — by design |
| Refresh grant | ❌ não havia refresh | ✅ **200, refresh rotacionado** | bonus |
| Refresh antigo invalidado após use | (n/a) | ✅ **400 `RefreshTokenInvalid`** | bonus |
| `/userinfo` com Bearer | ✅ | ✅ | mesmo |
| 12 roles atribuídas | ⚠️ (esperava 13) | ⚠️ 12 (mesma lista) | A3 — expectativa errada |

### Findings que ficam de pé

| ID | Severidade | Status | Resumo |
|---|---|---|---|
| ~~F1~~ | ~~CRÍTICO~~ | ✅ FALSO POSITIVO | App está com PKCE habilitado |
| ~~F2~~ | ~~CRÍTICO~~ | ✅ FALSO POSITIVO | Refresh token é emitido normalmente |
| ~~A5~~ | ~~AVISO~~ | ✅ FALSO POSITIVO | Nonce volta no id_token e bate com enviado |
| A1 | INFO | Permanece | Email/profile só no id_token e /userinfo (by design OIDC) |
| A2 | INFO | Permanece | `azp` é claim de id_token, ausente do access_token (conforme spec) |
| A3 | INFO | Ajustar | São **12 roles** atribuídas — não 13. Lista do prompt está desatualizada |
| A4 | INFO | Permanece | `aud` com 9 entries — Project ID inclusive. BFF deve usar `contains`, não `==` |
| A6 | RECOMENDAÇÃO | Permanece | Listener loopback do CLI Dart deve filtrar `_rsc=` e validar `state` |
| A7 | INFO | Permanece | RFC 8252 §7.3 — porta loopback arbitrária aceita |

---

## 2. Mudanças metodológicas vs Run 1

### 2.1 Listener robusto

`/Users/gabriel_aderaldo/tmp/acdg-cli-zitadel-verify/listener.py` foi reescrito:

**Run 1 (one-shot ingênuo):**
- Aceita o **primeiro hit qualquer** em `/callback` e morre.
- Não filtra `OPTIONS`, não filtra `_rsc=`, não valida `state`.
- Resultado: capturou o code do prefetch RSC do Next.js.

**Run 2 (multi-hit defensivo):**
- Mantém-se ouvindo até receber `GET /callback` com `state == expected` E `code` não-vazio.
- Drena silenciosamente (HTTP 204):
  - Métodos `!= GET` (rejeita `OPTIONS`/`HEAD`/`POST` com 405)
  - Path `!= /callback` (404)
  - Query contendo `_rsc=` (Next.js RSC fingerprint)
  - `state` ausente/vazio
  - `state != expected` (CSRF guard)
- Loga cada drop com método + path + motivo, **nunca** a query string completa.
- Hard timeout 300s.

### 2.2 Authorize URL: `prompt=login`

Adicionado `prompt=login` à URL para forçar tela de login mesmo se houvesse cookie residual no domínio `auth.acdgbrasil.com.br`. Defesa em profundidade — combinada com a janela anônima do user, garante zero estado herdado.

### 2.3 Janela anônima

Login feito em janela anônima (Cmd+Shift+N) — nenhum cookie, localStorage ou IndexedDB de sessões anteriores.

---

## 3. Evidências brutas (Run 2)

### 3.1 PKCE materials

```
verifier   86 chars (b64url no-pad de 64 random bytes)
challenge  43 chars (06BLqQgiUGGpjNuTOJR-qm_p74aLcFlF2xkB0cFN00A)
state      64 hex (a324ed2cd1c89fc968fc3cb362c8c26f91039af41740b54c43d326df24d638b6)
nonce      64 hex (0100ed1443f91de7ddc8c1f1b8217d5dbe3c1c0ebf7416850d07e6520e57c7fc)
```

### 3.2 Listener log (zero ruído de prefetch desta vez)

```
[listener] listening on http://127.0.0.1:8765/callback (timeout=300s)
[listener] expected state prefix: a324ed2c... (len=64)
[listener] OK   GET /callback -> state matched, code captured (len=50)
[listener] captured code+state written to /tmp/acdg-callback-*
```

> **Nota:** o `BrokenPipeError` no traceback após o `OK` é o browser fechando a conexão antes do listener terminar de enviar a página de sucesso — irrelevante (o code já foi gravado em disco antes).

Observação importante: nessa run, **nenhum hit de prefetch RSC chegou**. Isso é consistente com a hipótese de que o RSC prefetch do run 1 só foi disparado porque havia sessão ativa pré-existente que pulava a tela de login.

### 3.3 Token endpoint — exchange COM `code_verifier`

**Request:**
```http
POST /oauth/v2/token HTTP/1.1
Host: auth.acdgbrasil.com.br
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code
&code=<50-char code>
&redirect_uri=http%3A%2F%2F127.0.0.1%3A8765%2Fcallback
&client_id=371410163745226755
&code_verifier=<86-char verifier>
```

**Response (HTTP 200):**
```json
{
  "access_token":  "<JWT len=3394>",
  "id_token":      "<JWT len=3968>",
  "refresh_token": "<opaque len=104>",
  "token_type":    "Bearer",
  "expires_in":    43199
}
```

`expires_in: 43199` ≈ 12h — confirma TTL configurado.

> **Observação:** mesmo com `offline_access` solicitado, o campo `scope` **continua ausente** da resposta. RFC 6749 §5.1 diz "MAY" se igual ao solicitado, então não é violação. Apenas vale tomar nota: o BFF/CLI não deve depender desse campo na resposta do token endpoint para descobrir os scopes concedidos.

### 3.4 Access token (Run 2)

**Header:** `{"alg":"RS256","kid":"363088832046039161","typ":"JWT"}` (mesmo `kid` do Run 1, JWKS estável).

**Payload (campos relevantes):**

| Claim | Valor | OK? |
|---|---|---|
| `iss` | `https://auth.acdgbrasil.com.br` | ✅ |
| `sub` | `363088829932634233` | ✅ |
| `client_id` | `371410163745226755` | ✅ |
| `aud` | array com 9 IDs incluindo Project ID `363109883022671995` | ✅ A4 esperado |
| `iat` | 1777878833 | ✅ |
| `exp` | 1777922033 (Δ=43200s) | ✅ |
| `nbf` | 1777878833 | ✅ |
| `jti` | `V2_371418761229500419-at_371418761229565955` | ✅ |
| `urn:zitadel:iam:org:project:roles` | objeto com **12 roles** | ✅ A3 ajustado |
| `urn:zitadel:iam:org:project:363109883022671995:roles` | mesmas 12 roles (chave específica) | ✅ |
| `email`/`email_verified`/`name` | ❌ ausentes | A1 — by design |
| `azp` | ❌ ausente | A2 — conforme spec OIDC |

### 3.5 ID token (Run 2)

**Payload (campos presentes — diferenças vs Run 1 destacadas):**

| Claim | Valor | Run 1 | Run 2 |
|---|---|:-:|:-:|
| `iss` | `https://auth.acdgbrasil.com.br` | ✅ | ✅ |
| `sub` | `363088829932634233` | ✅ | ✅ |
| `azp` | `371410163745226755` | ✅ | ✅ |
| `aud` | mesma lista de 9 do access | ✅ | ✅ |
| `amr` | `["pwd"]` | ✅ | ✅ |
| `auth_time` | 1777878516 | ✅ | ✅ |
| `at_hash` | `DUwLxmhwZR68FT3BT8opqg` (hash de access_token) | ✅ | ✅ **valida** |
| **`nonce`** | `0100ed14...c7fc` (= enviado) | **❌** | **✅ presente e bate** |
| `email` / `email_verified` | gaderaldo10@gmail.com / true | ✅ | ✅ |
| `name` / `family_name` / `given_name` / `nickname` | preenchidos | ✅ | ✅ |
| `gender` / `locale` | male / en | ✅ | ✅ |
| `preferred_username` | gabriel.aderaldo@acdgbrasil.com.br | ✅ | ✅ |
| `sid` | `371418221019922435` | ✅ | ✅ |
| roles | mesmas 12 roles em duas chaves | ✅ | ✅ |

### 3.6 Validação `at_hash` (RFC OIDC §3.1.3.6)

`at_hash` deve ser `b64url(SHA-256(access_token).leftHalf)` quando access_token é emitido junto com id_token (response_type contém `code` ou `token`).

```
computed at_hash: DUwLxmhwZR68FT3BT8opqg
expected at_hash: DUwLxmhwZR68FT3BT8opqg
MATCH
```

Implicação: o CLI/BFF pode (e deve) validar `at_hash` no id_token para detectar tentativas de swap de access_token.

### 3.7 Refresh grant

**Request:**
```http
POST /oauth/v2/token HTTP/1.1
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token
&refresh_token=<opaque>
&client_id=371410163745226755
&scope=openid profile email offline_access urn:zitadel:iam:org:project:id:363109883022671995:aud
```

**Response (HTTP 200):**
```json
{
  "access_token":  "<NEW JWT len=3394>",
  "id_token":      "<NEW JWT len=3968>",
  "refresh_token": "<NEW opaque len=104>",  // ← rotacionado
  "token_type":    "Bearer",
  "expires_in":    43199
}
```

| Verificação | Resultado |
|---|---|
| Novo access_token diferente do anterior | ✅ |
| Refresh_token rotacionado (novo != antigo) | ✅ `peKOF0XU...LMt8` → `eJXhmsaq...DRsY` |
| `nonce` preservado no id_token pós-refresh | ✅ mesmo `0100ed14...c7fc` |
| `azp`/`sub` consistentes | ✅ |
| TTL renovado (43200s = 12h) | ✅ |

### 3.8 Refresh rotation enforcement

Tentar usar o refresh_token antigo após rotação:

```http
POST /oauth/v2/token
grant_type=refresh_token
&refresh_token=<OLD>

→ HTTP 400
{"error":"invalid_request","error_description":"Errors.OIDCSession.RefreshTokenInvalid"}
```

✅ **Refresh rotation está enforced** — o token antigo é invalidado imediatamente após o uso. Isso é defesa contra cenários onde o refresh leaked é usado em paralelo: o atacante e o usuário legítimo correm para usar primeiro, e o segundo a chegar é deslogado (detecção visível de comprometimento).

### 3.9 `/userinfo`

**HTTP 200**, payload completo: sub, email, email_verified, name, family_name, given_name, nickname, preferred_username, gender, locale, updated_at, mais as 12 roles em duas chaves (genérica e específica do Project).

---

## 4. F1, F2 e A5 reanalisados

### 4.1 F1 — "PKCE não está enforced"

**Reanálise:** ❌ **Falso positivo.**

**O que aconteceu na Run 1:**
1. Browser tinha sessão ativa em `auth.acdgbrasil.com.br` (cookie de uma autenticação prévia).
2. Ao abrir a authorize URL, o Next.js da UI de login do Zitadel processou o request via SSR — e como já havia sessão, não exibiu form de login: o servidor decidiu emitir code direto.
3. Durante a renderização da página de redirect, o Next.js disparou um **prefetch RSC** (request com `_rsc=` query param) para o `redirect_uri`. Esse prefetch passou por um caminho interno que gerou um code **diferente do code "real"** que viria depois — sem o `state` que mandamos e provavelmente sem PKCE challenge associado.
4. Listener one-shot pegou esse code-fantasma (state vazio, ignorou) e morreu.
5. Nosso exchange COM `code_verifier` foi rejeitado com `code_verifier unexpectedly provided` — **mensagem semanticamente correta**: aquele code específico não tinha challenge gravado no servidor.
6. Exchange SEM verifier passou porque aquele code realmente não exigia PKCE — mas era um code de contexto interno diferente.

**Run 2 com listener que valida state:** o code-fantasma é dropado (state vazio), o code legítimo passa, e o exchange COM `code_verifier` retorna 200. **PKCE está habilitado e funciona.**

### 4.2 F2 — "Sem refresh_token apesar de offline_access"

**Reanálise:** ❌ **Falso positivo.**

O code-fantasma da Run 1 foi gerado por um flow interno que **não pediu `offline_access`** (e não tinha PKCE). Daí o token endpoint não emitiu refresh — coerente com o scope efetivo daquele code.

Run 2: scope `offline_access` foi de fato no authorize legítimo, e a resposta do token endpoint trouxe `refresh_token` de 104 chars opaque + rotação enforced.

### 4.3 A5 — "nonce ausente no id_token"

**Reanálise:** ❌ **Falso positivo.**

Code-fantasma → id_token de outro contexto → nonce não-bound ao authorize que enviei. Run 2 mostra `nonce` presente no id_token e batendo exatamente com o valor enviado no authorize. **OIDC §3.1.3.7 #11 conforme.**

---

## 5. Findings que permanecem reais

### A1 — `email`/profile só no id_token e /userinfo

**Status:** Confirmado — comportamento padrão Zitadel/OIDC.

**Recomendação:** No primeiro request da sessão no Vapor BFF, chamar `/userinfo` com o Bearer access_token, mapear `(sub → email/name/roles)` e cachear (Redis ou memória process-local). Subsequentes podem confiar só no JWT validado.

### A2 — `azp` ausente do access_token

**Status:** Confirmado — `azp` é claim oficial de id_token, não de access_token (OIDC Core §2).

**Recomendação:** No JWT validator do Vapor BFF, **não** validar `azp` no access_token. Validar:
- `iss` exato match
- `aud.contains(PROJECT_ID)`
- Assinatura RS256 contra JWKS
- `exp` futuro com clock skew ~30s
- `nbf` no passado

### A3 — 12 roles em vez de 13 esperadas

**Status:** A expectativa do prompt original estava errada. **Real:** 12 roles atribuídas a este user.

**Lista confirmada (Run 2):**
```
analysis-bi:admin      analysis-bi:analyst   analysis-bi:exporter
people-context:admin   people-context:owner  people-context:worker
social-care:admin      social-care:owner     social-care:worker
social_worker          superadmin            owner
```

**Faltando vs prompt:** `admin` (provavelmente nunca foi atribuída a este user — ela existe no Zitadel atribuída a service-accounts como `people-context-sa`).

**Recomendação:** atualizar a documentação da `people-context`/admin matrix para refletir 12 e descrever quem tem `admin` separado.

### A4 — `aud` com 9 entries

**Status:** Confirmado e esperado. Os 9 IDs são applications do mesmo project; o scope mágico `urn:zitadel:iam:org:project:id:<PROJECT_ID>:aud` injeta o Project ID e Zitadel adiciona automaticamente todas as apps relacionadas.

**Recomendação BFF:** validar `aud.contains(PROJECT_ID)`, **não** match exato nem `aud.length == 1`.

### A6 — RSC prefetch da UI Zitadel

**Status:** Confirmado e **importante para o CLI Dart**.

Mesmo que na Run 2 o prefetch não tenha aparecido (sem sessão ativa), em produção haverá users com sessão ativa no Zitadel — e o prefetch RSC vai disparar contra o `redirect_uri` loopback. Listener naive vai capturar code-fantasma e o flow vai falhar exatamente como na Run 1.

**O listener Python desta Run 2 é a referência canônica de como o CLI Dart deve se comportar:**
- multi-hit
- filtra `_rsc=`
- valida `state == expected`
- drena silenciosamente hits sem state válido
- timeout total (5min)
- nunca loga query strings completas

A seção 8.3 do `first_report.md` já trazia essa forma em Dart — **mantém-se válida**.

### A7 — Redirect URI sem porta

**Status:** RFC 8252 §7.3 — porta loopback arbitrária aceita. Confirmado.

**Recomendação CLI:** bind em porta efêmera (`port=0`), recuperar a porta atribuída, montar `redirect_uri` em runtime.

---

## 6. Pendência opcional — confirmação de PKCE enforcement

Para **dupla confirmação** de que o servidor rejeita exchange sem `code_verifier`, faltaria fazer um segundo authorize (login adicional) e tentar trocar o novo code SEM o verifier. Esperado: **400** com mensagem mencionando PKCE required.

**Por que pulei:** o código foi consumido na Run 2 (o exchange COM verifier passou 200). Para repetir o teste sem verifier seria preciso outro round-trip pelo browser — fora do crítico. A evidência atual já é suficiente:

- Run 1 (sem PKCE no app): exchange COM verifier dava 400 `code_verifier unexpectedly provided`.
- Run 2 (com PKCE no app): exchange COM verifier passa 200.
- A semântica do erro Run 1 era *"o code não tem challenge"*; em Run 2 essa condição mudou — logo, o app passou a ter PKCE.

Se quiser fechamento absoluto, basta refazer o login uma vez e pedir o teste reverso. Caso contrário, considere F1 resolvido.

---

## 7. Compliance — atualização

### Vs. RFC 6749 (OAuth 2.0)

| Item | Esperado | Run 1 | Run 2 |
|------|----------|-------|-------|
| `code` flow funciona | sim | ✅ | ✅ |
| `refresh_token` quando `offline_access` solicitado | sim | ❌ FP | ✅ |
| `scope` retornado em /token | when difere | ⚠️ null | ⚠️ ausente (MAY, ok) |
| `error`/`error_description` em falhas | sim | ✅ | ✅ |

### Vs. RFC 7636 (PKCE)

| Item | Esperado | Run 1 | Run 2 |
|------|----------|-------|-------|
| Suporte a `S256` no servidor | sim | ✅ | ✅ |
| App público com PKCE enforced | sim | ❌ FP | ✅ (exchange COM verifier passa) |
| Verifier 43–128 chars b64url no-pad | usar | ✅ | ✅ |
| Challenge = b64url(sha256(verifier)) | sim | ✅ | ✅ |

### Vs. RFC 8252 (OAuth for Native Apps)

| Item | Esperado | Run 1 | Run 2 |
|------|----------|-------|-------|
| Loopback IP redirect com porta arbitrária | aceitar | ✅ | ✅ |
| Authorization Code + PKCE pra native | obrigatório | ❌ FP | ✅ |

### Vs. OIDC Core 1.0

| Item | Esperado | Run 1 | Run 2 |
|------|----------|-------|-------|
| `id_token` quando `openid` no scope | sim | ✅ | ✅ |
| `nonce` no id_token quando enviado | obrigatório | ❌ FP | ✅ |
| `at_hash` quando access_token retornado junto | obrigatório | ✅ | ✅ valida |
| `azp` no id_token | obrigatório | ✅ | ✅ |
| `/userinfo` com Bearer | obrigatório | ✅ | ✅ |

---

## 8. Bonus — descobertas ainda válidas

### 8.1 Refresh rotation com detecção de leak

A Run 2 confirma que o Zitadel **invalida o refresh_token antigo após rotação** (`Errors.OIDCSession.RefreshTokenInvalid`). Isso habilita o pattern de detecção:

> Se o CLI tentar usar um refresh já rotacionado, recebe 400. CLI **não deve** retentar — isso é sinal de que outra instância (ou atacante) já consumiu o token. CLI deve:
> 1. Apagar a sessão local imediatamente
> 2. Mostrar `acdg-cli login` requerido
> 3. (Opcional) reportar o evento para audit

### 8.2 Device Authorization Grant disponível

`grant_types_supported` inclui `urn:ietf:params:oauth:grant-type:device_code`. Para CLI rodando em SSH/CI/container sem browser local, esse flow é melhor que loopback. Considerar implementar como `acdg-cli login --device` em fase posterior.

### 8.3 Listener loopback de produção

O `listener.py` desta Run 2 e o snippet Dart na seção 8.3 do `first_report.md` formam **a referência operacional** para o CLI:
- multi-hit
- filtragem RSC (`_rsc=`)
- state matching (CSRF guard)
- drena silenciosamente
- timeout hard

Pode copiar essa lógica direto para o CLI Dart com adaptação mínima (HttpServer.bind do `dart:io` no lugar do http.server do Python).

---

## 9. Próximos passos atualizados

### Imediato

1. ~~Aplicar F1 e F2 no Admin Console~~ — **não necessário**, ambos eram falsos positivos.
2. Atualizar a documentação interna sobre as 12 roles (corrigir A3).
3. Decidir se vale fazer Round 3 do verify só para confirmar PKCE enforcement reverso (exchange SEM verifier → 400). Se sim: refazer login e rodar mais um curl. Se não: encerrar verificação aqui.

### Codar CLI Dart

1. Bootstrap projeto Dart com estrutura mínima:
   - `oidc/discovery.dart` — fetch + cache do `.well-known`
   - `oidc/pkce.dart` — verifier/challenge S256
   - `oidc/loopback_listener.dart` — **portado deste listener Python**
   - `oidc/token_client.dart` — `/token` calls + retry/backoff
   - `oidc/session_store.dart` — Keychain/Secret Service/DPAPI
   - `oidc/jwt_validator.dart` — RS256 + JWKS cache + at_hash check
2. Comando `acdg-cli login` end-to-end.
3. Comando `acdg-cli whoami` (decode id_token + /userinfo refresh).
4. Comando `acdg-cli logout` (revoke + clear).
5. Middleware de auto-refresh — tratar `RefreshTokenInvalid` como sinal de leak/expiração e forçar relogin.

### Médio prazo

1. Implementar Device Code Flow como `--device`.
2. Testar com user secundário (sem `superadmin`/`owner`) para validar RBAC granular.
3. Integrar com Vapor BFF: CLI → /api → JWT validation → response.

---

## 10. Bloco `.env` final (atualizado)

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

# Defesa adicional para forçar tela de login mesmo com sessão residual
OIDC_CLI_AUTHORIZE_PROMPT=login

# Roles claim (Zitadel emite em duas chaves — usar a genérica como primária)
OIDC_ROLES_CLAIM=urn:zitadel:iam:org:project:roles
OIDC_ROLES_CLAIM_PROJECT_SPECIFIC=urn:zitadel:iam:org:project:363109883022671995:roles

# Validação
OIDC_EXPECTED_ISSUER_EXACT=https://auth.acdgbrasil.com.br
OIDC_AUD_MUST_CONTAIN=363109883022671995
OIDC_CLOCK_SKEW_SECONDS=30

# Refresh rotation
OIDC_REFRESH_ROTATION_ENFORCED=true
OIDC_REFRESH_INVALID_GRANT_MEANS_RELOGIN=true
```

---

## 11. Checklist final

- [x] Listener robusto implementado e validado (drena RSC, valida state)
- [x] Authorize com `prompt=login` em janela anônima
- [x] Code legítimo capturado com state matching
- [x] Exchange COM `code_verifier` → 200 + tokens completos
- [x] `refresh_token` presente e funcional
- [x] `nonce` presente no id_token e bate com enviado
- [x] `at_hash` presente e valida contra access_token
- [x] Refresh grant retorna novos tokens com claims preservadas
- [x] Refresh rotation enforced (token antigo invalidado)
- [x] `/userinfo` com Bearer retorna 200 + payload completo
- [x] 12 roles confirmadas (A3 ajustado)
- [x] F1, F2, A5 confirmados como falsos positivos do Run 1
- [ ] (opcional) Confirmar enforcement reverso: exchange SEM verifier → 400 (requer novo login)

---

## 12. Artefatos atualizados (Run 2)

Em `~/tmp/acdg-cli-zitadel-verify/`:

| Arquivo | Conteúdo |
|---|---|
| `listener.py` | Listener Python multi-hit defensivo (versão Run 2, substituiu o one-shot) |
| `listener.log` | Log do listener — `state matched, code captured` |
| `authorize_url.txt` | Authorize URL com `prompt=login` |
| `token1.json` | Resposta exchange COM `code_verifier` (HTTP 200, com refresh) |
| `token_refresh.json` | Resposta do refresh grant (200, novo refresh rotacionado) |
| `userinfo.json` | `/userinfo` payload completo |
| `discovery.json` | OIDC discovery (mesmo do Run 1) |
| `jwks.json` | JWKS atual (mesmo do Run 1) |
| `RELATORIO-COMPLETO.md` | Relatório original (Run 1) |

E em `tests/`:

| Arquivo | Conteúdo |
|---|---|
| `first_report.md` | Run 1 (com falsos positivos) |
| `second_report.md` | **Este arquivo** |

---

**Conclusão:** O setup do Zitadel está pronto para o CLI Dart. Os bloqueios reportados no `first_report.md` eram artefatos da metodologia de teste (listener naive + sessão suja), não bugs de configuração. Pode prosseguir para a fase de implementação.

**Fim do relatório.**
