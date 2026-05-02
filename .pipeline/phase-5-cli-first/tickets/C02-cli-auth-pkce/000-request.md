# C02 — CLI Auth (PKCE Loopback estilo gh CLI)

## Onda: 2 | Profile: auth | Depende de: C00, C01

## Escopo

### Comandos

```bash
acdg auth login         # PKCE Loopback flow
acdg auth status        # mostra usuário logado, expiração do token
acdg auth logout        # revoga refresh + apaga credentials
acdg auth refresh       # força refresh manual
```

### Flow PKCE Loopback (RFC 8252 — OAuth 2.0 for Native Apps)

1. Gerar `code_verifier` (43-128 chars, [A-Z][a-z][0-9]-._~) + `code_challenge` (BASE64URL(SHA256(verifier)))
2. Iniciar `HttpServer` em `127.0.0.1:0` (porta dinâmica)
3. Construir authorize URL:
   ```
   <issuer>/oauth/v2/authorize?
     response_type=code&
     client_id=<ACDG_CLI_CLIENT_ID>&
     redirect_uri=http://127.0.0.1:<porta>/callback&
     code_challenge=<challenge>&
     code_challenge_method=S256&
     state=<random-csrf>&
     scope=openid profile email offline_access
   ```
4. Imprimir URL + abrir browser via `Process.run` (`open` / `xdg-open` / `start` por plataforma)
5. Aguardar callback (timeout 5min); validar `state` matches CSRF
6. Trocar code por tokens: POST `<issuer>/oauth/v2/token` com `code_verifier`
7. Persistir `access_token`, `refresh_token`, `id_token`, `expires_at` em `~/.config/acdg/credentials` (chmod 600)
8. Imprimir `Logged in as <email>` + roles do JWT

### Storage

- `~/.config/acdg/credentials` — JSON com chmod 600
- Schema: `{access_token, refresh_token, id_token, expires_at, issuer, client_id}`
- `CredentialStore` interface com impl `FileCredentialStore`; futura impl `KeychainCredentialStore` deferida

### Refresh automático

- `BffClient` (Dio wrapper) intercepta 401 → tenta refresh → retry uma vez
- Se refresh expirado, imprime `Session expired. Run: acdg auth login` e retorna exit 2

### Env / config

- `ACDG_OIDC_ISSUER` (default: https://auth.acdgbrasil.com.br)
- `ACDG_CLI_CLIENT_ID` (Native app no Zitadel — pode reusar Desktop client OU criar dedicado `acdg-cli`)
- `ACDG_BFF_URL` (default: http://localhost:3000)

### Native App no Zitadel (pré-requisito de infra)

- Aplicação Native (não Web)
- Redirect URIs: `http://127.0.0.1:*` (Zitadel suporta wildcard de porta para Native apps)
- PKCE obrigatório
- Refresh tokens enabled

## Pipeline

W0 (test-writer) → W1 (flutter-bff-implementer) → W2 (flutter-code-reviewer) → W3 (flutter-quality-checker)

## Critérios

- [ ] `acdg auth login` em ambiente real (Zitadel staging) bate em handshake completo
- [ ] Tests: PKCE generation, state validation, callback parsing, token exchange, file storage permissions, refresh flow
- [ ] Credential file chmod 600 verificado
- [ ] `acdg auth status` lê file e imprime expiração formatada
- [ ] `acdg auth logout` revoga refresh + apaga file (com prompt de confirmação opcional)

## Status
pending — blocked by C00, C01
