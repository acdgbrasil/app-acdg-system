# ADRs — Architecture Decision Records (Índice)

> Registro formal de todas as decisões arquiteturais do frontend.
> Cada decisão é **imutável** após aceita. Novas decisões podem substituir anteriores referenciando o ADR original via campo `Supersede`.
>
> Cada ADR vive como arquivo individual em [`DECISIONS/`](DECISIONS/) — esta página é apenas o **índice**.

---

## Como criar um novo ADR

1. Próximo número: consulta a tabela abaixo, soma 1 ao maior ADR existente.
2. Crie `DECISIONS/ADR-NNN-<slug-kebab>.md` seguindo o template:
   - `**Data:**` (YYYY-MM-DD)
   - `**Status:**` (Aceito / Adiado / Superseded por ADR-XXX)
   - `## Contexto`
   - `## Decisão`
   - `## Consequências`
   - `## Superseded by` (opcional, no final)
3. Adicione a linha no índice abaixo.
4. Atualize cross-references em ADRs relacionados.
5. Commit: `docs(handbook): add ADR-NNN <slug>`.

## Reconstituição histórica (2026-05-12)

ADRs 001–014 originalmente nunca tiveram corpo expandido (o `DECISIONS.md` antigo dizia *"consulte o histórico"*). Em 2026-05-12 foram **reconstituídos como stubs** a partir de `frontend/CLAUDE.md` — cada um marcado `Status: Aceito (reconstituído)` no arquivo. Detalhes históricos profundos podem ser caçados no git log.

ADRs 015–022 foram **extraídos** do `DECISIONS.md` antigo (que era um arquivo único de 427 linhas) para arquivos individuais. Conteúdo idêntico, apenas reformatado.

ADR-023 já estava em arquivo individual desde a sua criação.

---

## Índice

| ADR | Título | Data | Status |
|---|---|---|---|
| [001](DECISIONS/ADR-001-flutter-stack.md) | Stack Flutter como Plataforma Cliente | 2026-03 | Aceito (reconstituído) |
| [002](DECISIONS/ADR-002-bff-backend-for-frontend.md) | BFF (Backend for Frontend) como Mediador | 2026-03 | Aceito (reconstituído) |
| [003](DECISIONS/ADR-003-mvvm-logic-layer.md) | MVVM + Logic Layer como Padrão Arquitetural | 2026-03 | Aceito (reconstituído) |
| [004](DECISIONS/ADR-004-micro-frontend.md) | Micro-Frontend por Domínio | 2026-03 | Aceito (reconstituído, dormente — Phase 6+) |
| [005](DECISIONS/ADR-005-isar-offline-storage.md) | Isar para Offline Storage | 2026-03-08 | ⚠️ **Superseded por [ADR-021](DECISIONS/ADR-021-drift-over-isar.md)** |
| [006](DECISIONS/ADR-006-adaptive-design-3-pages.md) | Adaptive Design — 3 Pages por Feature | 2026-03 | Aceito (dormente Phase 6+; **escopo Web parcialmente superseded por [ADR-024](DECISIONS/ADR-024-web-app-stack-and-topology.md)**) |
| [007](DECISIONS/ADR-007-bff-edge-deployment.md) | BFF Web Deployment no Edge | 2026-03 | Aceito (reconstituído) |
| [008](DECISIONS/ADR-008-dart-aot.md) | Dart AOT para BFF (Produção) | 2026-03 | Aceito (reconstituído) |
| [009](DECISIONS/ADR-009-provider-di.md) | Provider como Injeção de Dependência | 2026-03 | Aceito (reconstituído) |
| [010](DECISIONS/ADR-010-immutable-models.md) | Models Imutáveis (Schemas Puros) | 2026-03 | Aceito (reconstituído) |
| [011](DECISIONS/ADR-011-split-token-pattern.md) | Split-Token Pattern para Auth Web | 2026-03 | Aceito (reconstituído) |
| [012](DECISIONS/ADR-012-oidc-pkce.md) | OIDC com PKCE para Autenticação | 2026-03 | Aceito (reconstituído) |
| [013](DECISIONS/ADR-013-mvvm-usecase-mandatory.md) | MVVM Estrito + UseCase Obrigatório + Pastas Padronizadas | 2026-03 | Aceito (reconstituído) |
| [014](DECISIONS/ADR-014-result-pattern.md) | Result&lt;T&gt; End-to-End — Erros como Valores | 2026-03 | Aceito (reconstituído) |
| [015](DECISIONS/ADR-015-command-pattern.md) | Uso Mandatório do Padrão Command para Ações de UI | 2026-03-13 | Aceito |
| [016](DECISIONS/ADR-016-usecase-orchestration.md) | UseCases como Camada de Orquestração Mandatória | 2026-03-13 | Aceito |
| [017](DECISIONS/ADR-017-atomic-design.md) | Organização de UI via Atomic Design | 2026-03-13 | Aceito (dormente — Phase 6+) |
| [018](DECISIONS/ADR-018-root-main-injection.md) | Separação Root / Main e Injeção por Camadas | 2026-03-13 | Aceito |
| [019](DECISIONS/ADR-019-parsers-p2-p2b.md) | Parsers em Fronteira Adapter — P2 `if-case` / P2b `try/catch` | 2026-04-17 | Aceito |
| [020](DECISIONS/ADR-020-intent-payload-record-deferred.md) | `IntentPayload` Record Carrier — Consideração Adiada | 2026-04-17 | Adiado |
| [021](DECISIONS/ADR-021-drift-over-isar.md) | Pivot Drift sobre Isar para Offline Storage | 2026-04-30 | Aceito (supersede [ADR-005](DECISIONS/ADR-005-isar-offline-storage.md)) |
| [022](DECISIONS/ADR-022-kernel-infra-apps-layout.md) | Reorganização do Monorepo — kernel/infra/apps Layout | 2026-05-01 | Aceito |
| [023](DECISIONS/ADR-023-bff-adapter-bearer-forwarding.md) | BFF Adapter — Bearer Token Forwarding | 2026-05-02 | Aceito |
| [024](DECISIONS/ADR-024-web-app-stack-and-topology.md) | Web App Stack & Topology (Vite + React + TS6, servido pelo BFF Shelf) | 2026-05-12 | Aceito (parcialmente supersede [ADR-006](DECISIONS/ADR-006-adaptive-design-3-pages.md) no escopo Web) |
| [025](DECISIONS/ADR-025-api-contract-codegen.md) | API Contract & Codegen (OpenAPI 3, Dart-authoritative, TS via openapi-typescript) | 2026-05-12 | Aceito |
| [026](DECISIONS/ADR-026-web-app-security-hardening.md) | Web App Security Hardening (CSP, COEP, supply chain, LGPD) | 2026-05-12 | Aceito |
| [027](DECISIONS/ADR-027-authentik-replaces-zitadel.md) | Authentik substitui Zitadel como IdP único | 2026-05-13 | Proposed (parcialmente supersede [ADR-011](DECISIONS/ADR-011-split-token-pattern.md) e [ADR-012](DECISIONS/ADR-012-oidc-pkce.md) onde citam Zitadel) |
| [028](DECISIONS/ADR-028-oidc-discovery-source-of-truth.md) | OIDC discovery document como fonte de verdade | 2026-05-13 | Proposed |
| [029](DECISIONS/ADR-029-authentik-blueprints-versioned.md) | Property mappings e configuração Authentik versionadas em Blueprint YAML | 2026-05-13 | Proposed |
| [030](DECISIONS/ADR-030-idp-events-via-people-context.md) | Eventos de identidade publicados pelo `people-context`, não por webhook do IdP | 2026-05-13 | Proposed |
| [031](DECISIONS/ADR-031-identity-migration-legacy-sub.md) | Migração de identidade preserva ADR-023 via `legacy_sub` attribute | 2026-05-13 | Proposed |

---

## Mapa de relacionamentos

```
ADR-001 (Flutter — Native only após ADR-024) ── base do app Native
├── ADR-002 (BFF) ─────────────────────────────────────────────┐
│   ├── ADR-007 (BFF Edge)                                     │
│   ├── ADR-008 (Dart AOT)                                     │
│   ├── ADR-023 (Bearer forwarding adapter)                    │
│   └── ADR-024 (Web App servido pelo BFF Shelf)                │
├── ADR-003 (MVVM + Logic) ── refinado por ──> ADR-013          │
│   ├── ADR-015 (Command pattern)                              │
│   ├── ADR-016 (UseCase obrigatório)                          │
│   ├── ADR-017 (Atomic Design)                                │
│   └── ADR-018 (Root/Main injection)                          │
├── ADR-004 (Micro-frontend) ── dormente (Phase 6+)             │
├── ADR-005 (Isar) ── superseded por ──> ADR-021 (Drift)        │
├── ADR-006 (Adaptive 3 Pages) ── dormente; Web parcialmente    │
│   superseded por ──> ADR-024                                  │
├── ADR-009 (Provider DI) ── usado por ──> ADR-018              │
├── ADR-010 (Models imutáveis)                                  │
├── ADR-011 (Split-Token) ── relacionado a ──> ADR-012, ADR-023,│
│   ADR-026                                                     │
├── ADR-012 (OIDC PKCE) ── relacionado a ──> ADR-011, ADR-023,  │
│   ADR-026                                                     │
├── ADR-014 (Result<T>) ── refinado por ──> ADR-019             │
├── ADR-019 (Parsers P2/P2b) ── relacionado a ──> ADR-020       │
├── ADR-020 (IntentPayload) ── adiado                           │
├── ADR-022 (kernel/infra/apps) ── layout atual ────────────────┘
└── Web App (Phase 6+, ADR-024/025/026)
    ├── ADR-024 (Vite + React + TS6, servido pelo BFF Shelf)
    ├── ADR-025 (API Contract — OpenAPI 3 dual codegen)
    └── ADR-026 (Security Hardening — CSP, COEP, supply chain, LGPD)
```

## ADRs dormentes (Phase 6+)

Decisões aceitas mas atualmente sem código vivo. Voltam ao escopo quando UI Flutter ressuscitar:

- [ADR-004](DECISIONS/ADR-004-micro-frontend.md) — Micro-frontend por domínio.
- [ADR-006](DECISIONS/ADR-006-adaptive-design-3-pages.md) — 3 Pages por feature.
- [ADR-017](DECISIONS/ADR-017-atomic-design.md) — Atomic Design.

## ADRs superseded

Decisões revogadas mas preservadas como histórico:

- [ADR-005](DECISIONS/ADR-005-isar-offline-storage.md) (Isar) ⟶ [ADR-021](DECISIONS/ADR-021-drift-over-isar.md) (Drift).

## ADRs adiados

Decisões registradas mas aguardando gatilho:

- [ADR-020](DECISIONS/ADR-020-intent-payload-record-deferred.md) — `IntentPayload` Record Carrier (YAGNI até router dinâmico / fuzz testing emergir).
