# ADR-027 — Authentik substitui Zitadel como IdP único

**Status:** Proposed
**Date:** 2026-05-13
**Deciders:** Authentik Evaluation Spike (`acdg/auth-spike/REPORT.md`)
**Supersedes:** Partes de [ADR-011](ADR-011-split-token-pattern.md) e [ADR-012](ADR-012-oidc-pkce.md) que referenciam Zitadel especificamente
**Related:** [ADR-023](ADR-023-bff-adapter-bearer-forwarding.md), [ADR-028](ADR-028-oidc-discovery-source-of-truth.md), [ADR-029](ADR-029-authentik-blueprints-versioned.md), [ADR-030](ADR-030-idp-events-via-people-context.md), [ADR-031](ADR-031-identity-migration-legacy-sub.md)

---

## Contexto

Hoje o ecossistema ACDG usa **Zitadel** como IdP (configurado em `auth.acdgbrasil.com.br`). A integracao acopla 3 servicos:

- **`acdg/social-care/`** (Swift/Vapor) — valida JWT via JWKS Zitadel em `IO/HTTP/Auth/ZitadelJWTPayload.swift` + `IO/HTTP/Middleware/JWTAuthMiddleware.swift`. JWKS URL em env `JWKS_URL=https://auth.acdgbrasil.com.br/oauth/v2/keys`.
- **`acdg/people-context/`** (TypeScript/Elysia) — consome Management API v2 do Zitadel em `src/zitadel/client.ts` (operacoes: `createUser`, `deactivateUser`, `requestPasswordReset`, `addUserGrant`, `removeUserGrant`, `listUserGrants`).
- **`acdg/frontend/apps/social_care_bff/web/`** (Dart/Shelf) — driver do OIDC Authorization Code + PKCE em `lib/src/auth/oidc_server_client.dart` e `lib/src/auth/jwks_client.dart`.

Tres dores recorrentes ao operar Zitadel hoje:

1. **Complexidade de configuracao** — Console + Management API trabalham com modelo `Instance > Org > Project > App > Grant(user × project × roles)` que e overkill para o caso atual (1 organizacao ACDG, dezenas de usuarios). Cada mudanca exige multiplos passos.
2. **Footprint operacional** — Zitadel cluster + CockroachDB consomem recursos significativos no `edge-cloud-infra`. Para uma instancia decente (~3GB+ RAM minimo).
3. **Falta de IA-friendliness para operacao** — sem MCP oficial, sem llms.txt, sem postura clara sobre agentes. Inspecionar/modificar config exige UI manual ou scripts curl.

Em 2026-05-13 conduzi spike completo (13 tasks, 11 notes tecnicos + REPORT consolidado em `acdg/auth-spike/`) avaliando **Authentik 2026.2.3** como substituto. Achados em ordem de impacto:

- **Cobertura funcional equivalente** para o caso ACDG: OIDC RS256, PKCE S256, refresh com `offline_access`, Management API REST completa, RBAC com 698 permissions granulares, multi-brand para multi-org futuro.
- **Footprint menor** — postgres + server + worker (~1.5GB RAM total). Redis removido em 2025.10 (task processing via Postgres).
- **IA-friendly de verdade** — Authentik publicou em mar/2026 ["A note to AI agents about authentik"](https://goauthentik.io/blog/2026-03-16-a-note-to-ai-agents-about-authentik/) tratando agentes como cidadaos de primeira classe. Existe MCP server da comunidade ([`@samik081/mcp-authentik`](https://github.com/Samik081/mcp-authentik), MIT) com 245 tools e modo `read-only` (121 tools).
- **Configuracao 100% versionavel** — Flow Engine, Brands, Property Mappings, Providers, Policies — tudo exportavel como Blueprint YAML. Snapshot da instancia do spike capturado em `acdg/auth-spike/authentik/seed/00-baseline.yaml` (210 entries).
- **Custo de migracao quantificado** — ~27 dias-pessoa (~5-6 sprints), distribuido por 9 frentes detalhadas no REPORT.

3 riscos identificados, todos com mitigacao concreta (detalhes nos ADRs relacionados):

- **`sub` muda formato** (snowflake numerico Zitadel → hash hex64 Authentik) — afeta ADR-023 → resolvido em [ADR-031](ADR-031-identity-migration-legacy-sub.md).
- **PT-BR e community-driven** — `pt-BR` esta nos targetLocales oficiais, mas cobertura pode ter buracos. Validar com user real e contribuir via Transifex se necessario.
- **Property mappings em Python rodam no IdP** — codigo dinamico fora do nosso build pipeline → resolvido em [ADR-029](ADR-029-authentik-blueprints-versioned.md).

## Decisao

**Authentik 2026.2.3+ substitui Zitadel como Identity Provider unico do ecossistema ACDG.**

Regras fundadoras:

1. **Servico unico de identidade** — toda autenticacao (Web BFF Dart, CLI, futura UI Flutter) passa por Authentik. Sem fallback Zitadel apos cutover.
2. **Multi-tenancy via Brand quando 2a organizacao chegar** — para hoje (1 org ACDG), basta o Brand default. Nao implementar multi-brand prematuramente.
3. **Service accounts dedicados por consumer M2M** — `people-context` recebe seu proprio service account com Role minima (apenas permissions necessarias para CRUD de users/groups). Token rotacionado via CI/CD a cada 360 dias.
4. **Custom domain `auth.acdgbrasil.com.br` mantido no cutover** — DNS aponta para Authentik. Branding em [ADR-029](ADR-029-authentik-blueprints-versioned.md).
5. **Plano de fases respeitado** — sem cutover atomico. Authentik e Zitadel rodam em paralelo durante Sprint 3-4 (multi-issuer JWKS) ate validacao completa, conforme `acdg/auth-spike/notes/11-user-migration.md`.

### Plano de fases (resumo do REPORT)

```
SPRINT 1-2 — Preparacao (paralela ao Zitadel atual)
   AuthentikClient + types (people-context)
   OIDCJWTPayload + multi-issuer JWKS (social-care)
   OidcServerClient discovery-driven (BFF Dart)
   Property mapping acdg-roles versionada em blueprint
   Helm chart em edge-cloud-infra

SPRINT 3 — Migracao de users
   Script de import com dry-run + reconciliation
   Coluna idp_user_id em people-context (paralela a zitadel_user_id)
   Feature flag no BFF Dart

SPRINT 4 — Switchover
   Authentik em prod paralelo a Zitadel
   Feature flag ligado para users escolhidos
   Monitorar metricas + audit trail

SPRINT 5 — Cutover total
   Zitadel em read-only
   100% dos logins novos via Authentik
   Recovery automatico para sessoes expiradas

SPRINT 6 — Cleanup
   Remover ZitadelClient + ZitadelJWTPayload
   Drop coluna zitadel_user_id
   Apagar Zitadel da infra
```

## Consequencias

### Positivas

- **Reducao de footprint** na infraestrutura (~50% RAM, sem CockroachDB).
- **Configuracao como codigo** — Blueprints YAML versionadas garantem reproducibilidade e revisao por PR.
- **Inspecao por IA** — Claude Code + MCP read-only oferece introspecao da instancia sem riscos.
- **Custom claims e flows mais flexiveis** — Flow Engine visual + Property Mappings Python cobrem casos que no Zitadel exigiam Actions JavaScript.
- **API REST OpenAPI completa** em `/api/v3/schema/` — clientes Python/Go/TS gerados automaticamente.

### Negativas

- **`sub` muda formato** — exige migracao com tabela de correlacao (`legacy_sub`) — ver [ADR-031](ADR-031-identity-migration-legacy-sub.md).
- **Senhas existentes nao migram** (hashes Zitadel diferentes) — todos os usuarios passam por recovery flow no primeiro login pos-cutover.
- **MFA factors nao migram** (TOTP segredo diferente) — re-enrollment obrigatorio.
- **PT-BR community-driven** — qualidade pode ter buracos ate consolidacao da traducao.
- **Lock-in moderado em Python expressions** — mitigado por blueprints versionadas (ADR-029).

### Componentes impactados

| Servico                                                          | Esforco | Detalhe                                                  |
|------------------------------------------------------------------|---------|-----------------------------------------------------------|
| `acdg/people-context/`                                           | ~4.5d   | Reescrita do client IdP (`src/zitadel/` → `src/idp/`)    |
| `acdg/social-care/`                                              | ~1d     | `JWKS_URL`, `OIDCJWTPayload`, multi-issuer middleware     |
| `acdg/frontend/apps/social_care_bff/web/`                        | ~3.25d  | Refactor discovery-driven OIDC                           |
| `acdg/edge-cloud-infra/`                                         | ~5d     | Helm chart Authentik substituindo Zitadel                |
| Migracao usuarios                                                | ~6d     | Script + multi-issuer + recovery flow                    |

Total: **~27 dias-pessoa** (5-6 sprints).

## Decisoes operacionais (atualizacao 2026-05-13)

Apos validacao pratica das 3 prioridades do user (CRUD facil, ADM facil, executar planejado), as seguintes decisoes complementam esta ADR:

1. **Reset de senha autorizado em massa** — senhas Zitadel nao migram. Todos usuarios passam por recovery flow no primeiro login pos-cutover. Reduz Sprint 3 em ~2 dias.
2. **Recovery email via `queue-manager`**, nao via Authentik Email Stage. `people-context` chama `/core/users/{pk}/recovery/`, recebe link, publica evento NATS. `queue-manager` monta template PT-BR com branding ACDG e envia.
3. **Logo via volume mount** em `edge-cloud-infra/authentik/assets/` montado read-only em `/web/dist/assets/custom/`. Brand referencia path estatico (sem blueprint base64).
4. **Multi-org com `attribute.org_id` desde Sprint 1** — toda conta cadastrada tem `attributes.org_id = "acdg-default"`. Property mapping `acdg-roles` inclui no JWT. `social-care` filtra registros por `org_id`. Permite multi-org futuro sem refactor de groups.
5. **Custom domain `auth.acdgbrasil.com.br` mantido** no cutover. Authentik 100% publico (mesma exposicao do Zitadel hoje).

### Principio de exposicao

**Customizacoes minimalistas e justificadas.** Toda custom (logo, CSS, theme) so e aplicada onde tem proposito de UX externa real. Admin UI nao recebe custom branding desnecessario alem da paleta ACDG basica (consistencia com a tela de login).

Em pratica:
- Authentik 100% publico em `auth.acdgbrasil.com.br`.
- Custom CSS minimalista no Brand — paleta `--ak-accent` + tipografia + esconde "Powered by authentik" no footer.
- Logo + favicon servidos publicamente (visiveis na tela de login).
- Assets sem proposito publico (mockups, screenshots) ficam fora do volume mount.

## Alternativas consideradas

- **Manter Zitadel** — descartado pelos motivos descritos no Contexto.
- **Keycloak** — mais maduro mas mais complexo de operar e menos foco em IA-friendliness. Footprint similar ao Authentik mas com Java stack (vs Python). Brand customization mais limitado.
- **Auth0/Okta managed** — descartado por custo recorrente + saida de dados sensiveis (LGPD).
- **WorkOS** — mesmo motivo.

## Plano de implementacao

Detalhado em `acdg/auth-spike/REPORT.md` e nos 11 notes tecnicos em `acdg/auth-spike/notes/`.

Para retomar:

```bash
cd acdg/auth-spike/authentik
docker compose up -d
open http://localhost:9000/if/admin/
```

MCP read-only ja registrado em `acdg/.mcp.json` (escopo de projeto).
