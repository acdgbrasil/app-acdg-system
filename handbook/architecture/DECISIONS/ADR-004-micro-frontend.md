# ADR-004: Micro-Frontend por Domínio

**Data:** 2026-03 (reconstituído a partir de `frontend/CLAUDE.md`)
**Status:** Aceito (reconstituído)

## Contexto

Aplicação monolítica frontal cresce em complexidade conforme novos domínios entram (`social_care`, `people_admin`, `analytics_bi`, `form_conversions`, `queue_manager`). Build time, coupling de mudanças e ownership ficam complicados.

## Decisão

Cada domínio é um **package Dart independente** no monorepo Flutter. Shell importa e registra rotas via **deferred loading** ([GoRouter](https://pub.dev/packages/go_router)).

**Um único binário final** — micro-frontend é organizacional, não runtime (não há iframe, não há remote loading).

## Consequências

- Cada domínio tem ciclo próprio de testes e validação.
- Equipes diferentes podem ownar packages diferentes sem pisar uma na outra.
- Deferred loading mantém startup leve mesmo com muitos domínios.
- Build é Melos-orquestrado.

## Status atual (2026-05-12)

- **Suspenso temporariamente.** D1.C delete (commit `33626f0`, 2026-05-01) removeu `packages/social_care/`, `packages/people_admin/`, `packages/design_system/`, `packages/auth/`, `apps/acdg_system/`.
- Layout atual ([ADR-022](ADR-022-kernel-infra-apps-layout.md)) mantém a estrutura `apps/<x>/` que permite reintroduzir micro-frontends em Phase 6+ quando UI Flutter ressuscitar.

## Superseded by

Nenhum (parcialmente dormente — esperando Phase 6+).
