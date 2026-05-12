# ADR-011: Split-Token Pattern para Auth Web

**Data:** 2026-03 (reconstituído a partir de `frontend/CLAUDE.md`)
**Status:** Aceito (reconstituído)
**Relacionado:** [ADR-012](ADR-012-oidc-pkce.md), [ADR-023](ADR-023-bff-adapter-bearer-forwarding.md)

## Contexto

Frontend Web tem dois requisitos conflitantes:

1. **Refresh transparente** — sessão longa sem login a cada hora.
2. **Resistência a XSS** — token não pode ser lido por JavaScript malicioso.

Armazenar refresh token em `localStorage` / `sessionStorage` o expõe a XSS. Armazenar tudo em cookie HttpOnly impede o cliente Dart de mandar `Authorization: Bearer ...` (cookie é mandado automaticamente, mas backend espera header).

## Decisão

**Split-Token Pattern:**

| Token | Onde fica | Quem lê |
|---|---|---|
| **Access Token** (curto, ~15min) | Memória Dart (variável in-memory) | Cliente Dart → manda como `Authorization: Bearer ...` |
| **Refresh Token** (longo, ~30 dias) | Cookie HttpOnly, SameSite=Strict, Secure | Só o BFF Web — JS não consegue ler |

Fluxo de refresh:

1. Access token expira → cliente recebe `401`.
2. Cliente chama `POST /auth/refresh` (cookie HttpOnly viaja automaticamente).
3. BFF valida refresh token contra Zitadel, devolve novo access token no body.
4. Cliente atualiza memória + retenta a request original.

## Consequências

- XSS no cliente **não** consegue exfiltrar refresh token.
- Access token vive só na memória do tab — fechar o browser limpa.
- Renovação transparente sem login.
- Custo: precisa de endpoint `POST /auth/refresh` no BFF + lógica de retry no cliente.

## Anti-padrão

- ❌ Refresh token em `localStorage` / `sessionStorage`.
- ❌ Access token em cookie sem HttpOnly.
- ❌ Cookie sem `SameSite=Strict` ou `Secure`.

## Status atual (2026-05-12)

- BFF Web implementa o pattern em `apps/social_care_bff/web/lib/src/handlers/auth_handler.dart`.
- Desktop (CLI / Flutter Desktop) **não** usa este pattern — usa Keychain / Credential Manager nativo via `flutter_secure_storage` ou `keychain` package.
- CLI Phase 5 usa Keychain via `apps/cli/lib/src/auth/keychain_storage.dart` (ticket B4).

## Superseded by

Nenhum.
