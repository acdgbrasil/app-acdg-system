# C02 — CLI Auth (PKCE Loopback estilo gh CLI)

## Onda: 2 | Profile: auth | Depende de: C00 ✅ (closed), C01 ✅ (closed)

## Status
**UNBLOCKED 2026-05-04** — Native App PKCE "ACDG CLI" provisionado no Zitadel self-hosted e validado end-to-end em 2 rounds. Pipeline 4-wave kicked.

## Spec source-of-truth
**`handbook/spikes/OICD_AUTH_SPIKE.md` v1.0 final (2026-05-04)** — esta spike é o contrato canônico para o W0 (test-writer). Contém setup Zitadel verificado, claims observadas, listener Python de referência, casos de teste obrigatórios, e bloco `.env` final.

## Comandos

```bash
acdg auth login         # PKCE Loopback flow (estilo `gh auth login`)
acdg auth status        # mostra usuário logado, expiração, roles
acdg auth logout        # revoga refresh + apaga credentials
acdg auth refresh       # força refresh manual
```

## Identidade do CLI no Zitadel (provisionada)

| Campo | Valor |
|---|---|
| Native App ID | `371410163745161219` |
| **Client ID** | `371410163745226755` |
| Project ID | `363109883022671995` |
| Org ID | `363109592139300987` |
| Issuer | `https://auth.acdgbrasil.com.br` |
| Authentication | None (PKCE-only, sem secret) |
| Redirect URIs | `http://127.0.0.1/callback`, `http://[::1]/callback` |

Constants em `apps/cli/lib/src/config/oidc_config.dart` (committed).

## Flow PKCE Loopback (RFC 8252)

1. Discovery: `GET <issuer>/.well-known/openid-configuration`; valida `issuer ==` esperado; cacheia endpoints.
2. `PkcePair.generate()` — verifier (64 random bytes → b64url no-pad) + challenge (b64url no-pad de SHA-256(verifier)). **S256 only.**
3. `HttpServer.bind(InternetAddress.loopbackIPv4, 0)` — porta efêmera, recupera `server.port`.
4. Authorize URL com `prompt=login` (defesa contra cookie residual + RSC prefetch):
   ```
   <issuer>/oauth/v2/authorize?response_type=code&client_id=371410163745226755
     &redirect_uri=http://127.0.0.1:<porta>/callback
     &code_challenge=<challenge>&code_challenge_method=S256
     &state=<random>&nonce=<random>
     &scope=openid profile email offline_access urn:zitadel:iam:org:project:id:363109883022671995:aud
     &prompt=login
   ```
5. Abre browser via `Process.run` (`open` macOS / `xdg-open` Linux / `rundll32 url.dll,FileProtocolHandler` Windows). Fallback: imprimir URL.
6. **LoopbackListener defensivo** captura callback (ver §Requirements não-negociáveis).
7. Trocar code por tokens: `POST <issuer>/oauth/v2/token` (form-urlencoded) com `code_verifier` — **sem `client_secret`** (PKCE-only).
8. Persistir `OidcSession {accessToken, refreshToken, idToken, accessExpiresAt, sub, email, roles}` via `CredentialStore` (estender `Credentials` do C01).
9. (Opcional/UX) `GET /oidc/v1/userinfo` com Bearer pra confirmar identidade no `whoami`.

## Requirements não-negociáveis (extraídos da spike §3.4-§5.15)

### LoopbackListener (CRÍTICO — não simplificar para one-shot)

1. **Multi-hit** — continua ouvindo até receber `GET /callback` com `state == expected` AND `code` não-vazio.
2. **Filtra `_rsc=`** — Next.js RSC prefetch dispara antes do user clicar; drena com `204`.
3. **Filtra método** — só `GET` em `/callback`; outros metodos ⇒ 405; outros paths ⇒ 404.
4. **Valida state** — CSRF guard. Estado vazio ou `!= expected` ⇒ drop silencioso (204), continua ouvindo.
5. **Bind porta efêmera** — `InternetAddress.loopbackIPv4` + porta `0`; recupera `server.port` runtime.
6. **Hard timeout** — 5min (300s); `Timer` cancela completer com erro.
7. **NÃO logar query strings** — log só método + path + motivo do drop.

### Authorize URL

- **`prompt=login`** sempre — defesa contra cookie residual no domínio Zitadel.
- `state` = 32 random bytes hex; `nonce` = 32 random bytes hex; ambos dos PKCE materials.
- Scopes: `openid profile email offline_access urn:zitadel:iam:org:project:id:363109883022671995:aud` (scope mágico injeta Project ID em `aud`).

### Validação JWT (no CLI — leve; rigorosa fica no BFF)

- `iss` exato match.
- `aud.contains(PROJECT_ID)` — **nunca** `==` (token vem com 9 entries — outras apps do project).
- `exp` futuro com clock skew tolerável (~30s).
- `nbf` no passado.
- **NÃO** validar `azp` no access_token (`azp` é claim de id_token apenas, OIDC Core §2).
- **NÃO** esperar `email`/`name` no access_token — só id_token e `/userinfo`.

### Refresh handling

- `invalid_grant: RefreshTokenInvalid` ⇒ **SEM retry**. Apaga sessão local, imprime "Sessão invalidada — execute `acdg auth login`", `exit 7`.
- Refresh rotation enforced pelo Zitadel (validado): a cada refresh, novo refresh_token vem; o antigo invalidado.
- Refresh proativo: se `accessExpiresAt - now < 60s`, refresh antes de chamar BFF.

### `BffClient` (estender o de C01)

C01 ship: Bearer interceptor já presente. C02 adiciona:
- 401 → tenta refresh → retry **uma** vez. Se refresh falhar com `RefreshTokenInvalid`, propaga `AuthRequiredError` + clear sessão.
- Logging seguro: redact tokens (primeiros 8 + últimos 4 chars).

## Storage

- Estender `Credentials` (C01) → `OidcSession` adicionando `idToken`, `sub`, `email`, `roles`. Mantém schema retrocompatível ou migra (decisão do W0/W1).
- Path: `XDG_CONFIG_HOME/acdg/credentials` ou `$HOME/.config/acdg/credentials` (já implementado em C01).
- chmod 600 (já implementado).

## Pipeline 4-wave (idêntica a C01/D01/D02/D03)

| Wave | Agent | Output |
|------|-------|--------|
| W0 — RED | `test-writer` | Tests RED descrevendo contrato esperado. **Lê spike + ticket. NÃO lê impls.** |
| W1 — GREEN | `flutter-bff-implementer` | Implementação até GREEN. Result<T> end-to-end. try/catch só em adapter boundary. |
| W2 — REVIEW | `flutter-code-reviewer` | Audit read-only (max 3 rounds). APPROVED ou REJECTED. |
| W3 — QUALITY | `flutter-quality-checker` | `dart analyze` zero issues + `dart format` + `dart test` GREEN. |

## Critérios de aceite (DoD)

- [ ] `acdg auth login` em ambiente real (Zitadel staging) bate handshake completo end-to-end.
- [ ] Tests RED ≥ 30 cobrindo: PKCE generation, state CSRF, callback parsing, RSC filter, token exchange, file storage permissions, refresh flow, RefreshTokenInvalid handling.
- [ ] Credential file chmod 600 verificado (já em C01).
- [ ] `acdg auth status` lê file e imprime: `Logged in as <email>` + roles + expiration humanizada.
- [ ] `acdg auth logout` revoga refresh remoto (best-effort) + apaga file.
- [ ] `dart analyze` zero issues.
- [ ] Total GREEN do CLI ≥ 110 (era 77 fim do C01; +30 mínimo do C02).

## O que NÃO fazer no C02

- **Não** validar JWT contra JWKS no CLI (validação rigorosa fica no BFF Bearer middleware C00 — já closed).
- **Não** implementar Device Code Flow (`--device`) — fica para C02-bis ou C10+.
- **Não** mexer em `Credentials.fromJson` de forma incompatível sem migração explícita (C01 já depende da forma atual).
- **Não** logar tokens completos em nenhum lugar.
