# Report — 2026-03-07 — Definicao de Arquitetura Frontend

## Contexto

Backend social-care (Swift/Vapor) finalizado (~98%). JWT/RBAC com Zitadel implementado. Hora de planejar e documentar a arquitetura do ecossistema frontend antes de implementar.

## Decisoes Tomadas

1. **Flutter/Dart** como framework unico (Web WASM + Desktop nativo sem webview)
2. **BFF em Dart** (AOT) com EDD + DDD — mesma linguagem do front
3. **MVVM + Logic Layer (UseCase)** como padrao arquitetural por feature
4. **Estado atomico** com ChangeNotifier + ValueNotifier (sem BLoC, sem Riverpod)
5. **Provider** para Dependency Injection
6. **Micro-frontend** via packages Dart no monorepo + deferred loading
7. **Offline First** com Isar (NoSQL) + queue CRDT-like com timestamps
8. **Adaptive Design** — 3 Pages por feature (Desktop/Web/Mobile), ViewModel unica
9. **Atomic Design** — Page > Template > Cell > Atom
10. **Imutabilidade total** — models final, copyWith, zero side effects
11. **GoF Design Patterns** — Factory, Strategy, Observer, Command, Repository, Adapter, Builder
12. **BFF Desktop** = in-process (package Dart importado, chamadas diretas)
13. **BFF Web** = servidor Darto (HTTP), cliente nunca fala direto com API
14. **Dio** como HTTP client, **Darto** como HTTP server
15. **Zitadel OIDC PKCE** para autenticacao, role-based routing no Shell
16. **Code EN / UI PT-BR** — variaveis em ingles, interface em portugues
17. **Figma existente** da ACDG como design system

## Artefatos Produzidos

- `frontend/handbook/` — Handbook completo (9 secoes)
- `frontend/handbook/architecture/ARCHITECTURE.md` — Visao geral
- `frontend/handbook/architecture/DECISIONS.md` — 10 ADRs
- `frontend/handbook/architecture/DIAGRAMS.md` — 8 diagramas Mermaid
- `frontend/handbook/principles/README.md` — Principios e convencoes
- `frontend/handbook/codebase/README.md` — Mapa de modulos e features
- `frontend/handbook/tooling/README.md` — Stack tecnologico
- `frontend/handbook/process/README.md` — Fluxo de trabalho
- `frontend/handbook/quality/README.md` — Estrategia de testes
- `frontend/handbook/cicd/README.md` — Pipelines e deploy
- `frontend/handbook/Agents/` — Prompts de agentes AI
- `frontend/IMPLEMENTATION_PLAN.md` — Plano de implementacao
- `frontend/CLAUDE.md` — Instrucoes para Claude Code

## Proximos Passos

- Fase 1: Setup do monorepo Flutter (shell + packages + BFF)
- Fase 2: Shell + Auth (Zitadel OIDC PKCE)
- Fase 3: BFF Social Care (EDD + DDD)
- Fase 4: Offline Engine (Isar + SyncQueue)
- Fase 5: Features Social Care (12 features)
- Fase 6: Polish + Desktop Build
