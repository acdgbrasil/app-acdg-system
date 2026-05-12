# ADR-012: OIDC com PKCE para Autenticação

**Data:** 2026-03 (reconstituído a partir de `frontend/CLAUDE.md`)
**Status:** Aceito (reconstituído)
**Relacionado:** [ADR-011](ADR-011-split-token-pattern.md), [ADR-023](ADR-023-bff-adapter-bearer-forwarding.md), [OIDC_IMPLEMENTATION_GUIDE.md](../OIDC_IMPLEMENTATION_GUIDE.md)

## Contexto

Autenticação centralizada via **Zitadel** (provider OIDC). Cliente público (sem secret) não pode usar Authorization Code Flow vanilla — precisa de **PKCE** (Proof Key for Code Exchange, RFC 7636) para evitar interceptação de authorization code.

## Decisão

Adotar **OIDC Authorization Code Flow + PKCE** para todas as plataformas, via `package:oidc` (Bdaya-Dev):

| Plataforma | Redirect / callback |
|---|---|
| **Web** | `http://localhost:<port>/auth/callback` (dev) ou `https://<domain>/auth/callback` (prod) |
| **Desktop** | Custom URI scheme (ex: `acdg://callback`) |
| **Mobile** | Universal Link / App Link |
| **CLI** (Phase 5) | **Loopback Address** (RFC 8252) — server HTTP ephemeral em `127.0.0.1:<random>` |

### Roles (3)

| Role | Permissões |
|---|---|
| `social_worker` | CRUD em pacientes e prontuários |
| `owner` | Read-only |
| `admin` | Read + gestão de usuários e configuração |

## Consequências

- Cliente nunca vê secret — PKCE garante segurança sem secret no app.
- Mesma identidade Zitadel autentica Web, Desktop, Mobile, CLI.
- Roles vêm como claims do JWT — extraídos no BFF, encaminhados via `X-Actor-Id` ou direto via Bearer ([ADR-023](ADR-023-bff-adapter-bearer-forwarding.md)).
- Refresh segue Split-Token ([ADR-011](ADR-011-split-token-pattern.md)) no Web; nativo (Keychain) em Desktop / Mobile / CLI.

## Status atual (2026-05-12)

- Implementado em `apps/social_care_bff/web/` (Web) e `apps/cli/` (CLI Loopback Phase 5).
- Detalhes em [OIDC_IMPLEMENTATION_GUIDE.md](../OIDC_IMPLEMENTATION_GUIDE.md).
- CLI Loopback inspirado em `gh CLI` — abre browser, ouve callback local, troca code por tokens.

## Superseded by

Nenhum.
