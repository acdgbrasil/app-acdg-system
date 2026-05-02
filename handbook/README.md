# Handbook — frontend (Conecta Raros)

> Documentacao viva do ecossistema frontend da ACDG.
> Este handbook centraliza decisoes, convencoes e guias para BFFs, CLI, e (futuramente) micro-apps Flutter.
>
> **Atualizado 2026-05-01** — pos D1.C delete + ADR-022 (kernel/infra/apps) + Phase 5 CLI-first kickoff.
> **Layout canonico:** [architecture/MONOREPO_LAYOUT.md](architecture/MONOREPO_LAYOUT.md).
> **Diretriz operacional:** [principles/HANDBOOK_AS_SOURCE_OF_TRUTH.md](principles/HANDBOOK_AS_SOURCE_OF_TRUTH.md).

---

## Objetivo

Manter um registro unico e rastreavel de todas as decisoes tecnicas, padroes arquiteturais e convencoes do frontend. Este documento evolui junto com o codigo — cada mudanca significativa deve ser refletida aqui antes (ou junto) com o codigo.

## Estado atual (2026-05-01)

**Fases concluidas:**
- **Phase 1** — DTOs do BFF (55 DTOs + 8 sub-contracts).
- **Phase 2** — API clients migrados (superseded por Phase 3 Onda 4 rebuild).
- **Phase 3** — BFF Contract A reescrito do zero (22/22 tickets, 2036 testes GREEN).

**Em curso:**
- **Phase 5 CLI-first** — `apps/cli/` Dart puro consumindo BFF Web via HTTP. 12 tickets C00-C11 em scaffold. Pipeline TDD 4-agent.

**Em hold (substituida):**
- Phase 4 (Flutter migration) foi superseded por Phase 5. UI Flutter sera revisitada em Phase 6+ apos CLI estabilizar.

**Layout do monorepo (ADR-022):**
- `kernel/` — Dart-pure foundation (`contracts`, `lints`)
- `infra/` — Flutter-coupled implementacao concreta (`runtime`, `transport`, `storage`)
- `apps/` — unidades entregaveis (`social_care_bff/{contracts,web,desktop}` hoje; `cli`, `social_care_ui`, `analytics_bi` no futuro)

## Estrutura

| Secao | Descricao | Estado |
|-------|-----------|--------|
| [architecture/](architecture/) | Decisoes arquiteturais, diagramas, ADRs (ADR-022 = layout atual) | viva |
| [principles/](principles/) | Diretrizes de design, patterns, convencoes; HANDBOOK_AS_SOURCE_OF_TRUTH = diretriz nuclear | viva |
| [codebase/](codebase/) | Mapa de packages e contratos | viva |
| [tooling/](tooling/) | Stack tecnologico e bibliotecas | viva |
| [process/](process/) | Fluxo de trabalho, versionamento, PRs | viva |
| [quality/](quality/) | Testes, cobertura, performance | viva |
| [cicd/](cicd/) | Pipelines, deploy, rollback | viva |
| [Agents/](Agents/) | Prompts de agentes AI | viva |
| [references/](references/) | Material de apoio externo | semi-viva |
| [chat/](chat/) | Logs de sessoes inter-agente | **historico — nao atualizar** |
| [audit/](audit/) | Auditorias de epoca | **historico — nao atualizar** |
| [missions/](missions/) | Missoes resolvidas | **historico — nao atualizar** |
| [reports/](reports/) | Reports de fase concluida | **historico — nao atualizar** |
| [research/](research/) | Pesquisas que embasaram decisoes | **historico — nao atualizar** |
| [implementation_plans/](implementation_plans/) | Planos antigos de implementacao | **historico — nao atualizar** |
| [social_care_implementation/](social_care_implementation/) | Implementacao do social_care anterior (deletado D1.C) | **historico — nao atualizar** |
| [web-migration/](web-migration/) | Migracao Flutter Web (anterior) | **historico — nao atualizar** |

## Principios Norteadores (cross-cutting)

Validos independente da camada (BFF, CLI, future UI):

- **BFF e a fonte de verdade de regra de negocio.** APP/CLI consome via Contract A; nao replica logica.
- **Result<T> end-to-end.** Erros sao valores, nao excecoes. `try/catch` so em adapter boundary.
- **Imutabilidade.** Models com `final` em tudo, `copyWith()` para mutacoes.
- **Path packages para dev local.** Names dos packages preservados ao mover pastas (ADR-022).
- **Handbook como fonte unica de verdade.** Memoria de agente nao e canonica; commit no handbook e.

### Por camada

- **BFF** — Sub-contracts (11), Intents/UseCases/Handlers, Cascade DI, ENCAPSULATION_POLICY H1-H9, PATTERN_MATCHING_POLICY P1-P5, Result<T> via map/flatMap/combineWith (NUNCA sealed-class downcast).
- **CLI (Phase 5)** — args parser, output formatters (table/json/yaml), OIDC PKCE Loopback (RFC 8252), Bearer auth no BFF (D3.C), commands estilo `gh`.
- **Future UI Flutter (Phase 6+)** — MVVM estrito, ValueNotifier por campo, Atomic Design, GoRouter deferred loading. Contexto adormecido ate Phase 5 fechar.

## Como contribuir com docs

1. **Antes de codar coisa nova:** leia `architecture/MONOREPO_LAYOUT.md`, `architecture/DECISIONS.md`, `principles/README.md`.
2. **Se o handbook estiver errado:** PARE, verbalize a inconsistencia (CLAUDE.md REGRA #2 aplicada a docs), atualize antes de seguir.
3. **Decisao nova:** cria ADR em `architecture/DECISIONS.md` (numera sequencial: ADR-NNN).
4. **Diretriz/convencao nova:** doc em `principles/`.
5. **Stack/ferramenta nova:** atualiza `tooling/README.md`.
6. **Nao mexer em `chat/`, `audit/`, `missions/`, `reports/`, `research/`, `implementation_plans/`, `social_care_implementation/`, `web-migration/`** — sao history imutavel.
