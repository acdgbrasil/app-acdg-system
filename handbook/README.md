# Handbook — frontend (Conecta Raros)

> Documentacao viva do ecossistema frontend da ACDG.
> Este handbook centraliza decisoes, convencoes e guias para todos os micro-apps Flutter, BFFs Dart e o design system compartilhado.

---

## Objetivo

Manter um registro unico e rastreavel de todas as decisoes tecnicas, padroes arquiteturais e convencoes do frontend. Este documento evolui junto com o codigo — cada mudanca significativa deve ser refletida aqui.

## Metas Imediatas

- Operar como ecossistema de micro-apps independentes com experiencia unificada
- Garantir rastreabilidade de decisoes tecnicas e de dominio
- Documentar evolucoes junto com o codigo
- Servir como onboarding para novos contribuidores

## Estrutura

| Secao | Descricao |
|-------|-----------|
| [architecture/](architecture/) | Decisoes arquiteturais, diagramas, ADRs |
| [principles/](principles/) | Diretrizes de design, patterns, convencoes de codigo |
| [codebase/](codebase/) | Mapa de modulos, contratos, convencoes de pastas |
| [tooling/](tooling/) | Stack tecnologico, bibliotecas, automacoes |
| [process/](process/) | Fluxo de trabalho, versionamento, PRs, operacional |
| [quality/](quality/) | Testes, cobertura, acessibilidade, performance |
| [cicd/](cicd/) | Pipelines, ambientes, deploy, rollback |
| [reports/](reports/) | Registros historicos de sessoes e decisoes |
| [references/](references/) | Material de apoio, links, artigos |
| [Agents/](Agents/) | Prompts de agentes AI para review e implementacao |

## Principios Norteadores

- **Offline First** — O app funciona sem internet. Acoes sao enfileiradas e sincronizadas automaticamente.
- **Seguranca Maxima** — BFF como barramento. Cliente web ZERO informacao sensivel. Desktop com DB local.
- **Imutabilidade Total** — Todos os models sao imutaveis. Zero efeitos colaterais.
- **MVVM Estrito** — ViewModel concentra estado. View nao decide nada.
- **Micro-Frontend** — Cada dominio e um package independente com lazy loading.
- **Adaptive Design** — Pages diferentes por plataforma (Desktop/Web/Mobile), mesma ViewModel.
- **GoF na veia** — OOP real com Design Patterns (Factory, Strategy, Observer, Command, Repository).
