# Pipeline State: phase-4-flutter-migration (ON HOLD — renomeado de phase-3-flutter-acl)

## Current Phase
phase: on-hold
agent: —
status: paused — aguarda Fase 3 BFF Contract A completar

## Razão da pausa
Em 2026-04-17 o plano foi invertido: BFF-first.
Nova Fase 3 ativa: `.pipeline/phase-3-bff-contract-a/` (21 tickets, só BFF).
Quando Fase 3 terminar (A21), esta Fase 4 retoma.

## Insumos preservados (prontos para consumo em Fase 4)
- T01 ✅ — 22 domain models em `packages/social_care/lib/src/domain/models/`
- T02 ✅ — 21 mappers em `packages/social_care/lib/src/data/mappers/`
- T03 ✅ (split) — HttpSocialCareClient dividido em `data/services/http/` (8 arquivos)

## Completed (preservado)
- [x] T01 — 22 domain models + barrel created; dart analyze clean; mapping documented

## Decisions Log
- [2026-04-16] Motivação: COMPLIANCE_REPORT_2026_04_16.md identificou 63 imports de `bff/shared/` em camadas proibidas + god-interface `HttpSocialCareClient` (643 linhas) + 5 divergências estruturais.
- [2026-04-16] Usuário confirmou: aceita breaking changes; começar pelo Web; objetivo = replicar pattern Intent/UseCase que a Phase 2 criou no BFF Web, agora no cliente Flutter.
- [2026-04-16] Estratégia: **Strangler Fig** (Fowler, 2004) — migra feature por feature; velho e novo convivem; deletar legado só quando ninguém usa.
- [2026-04-16] Piloto escolhido: ficha **Housing** — simples, 1 endpoint PUT, baixo risco, boa validação do template.
- [2026-04-16] Referência oficial: `.claude/skills/flutter-expert/references/contract_a_public_api.md` (adicionado ao SKILL.md §Reference Sources item #12).
- [2026-04-16] Ordem oficial por ticket (skill §Implementation Order): Model → Service → Repository → UseCase → ViewModel → View.

## Tickets — Visão Geral
> Cada ticket é atômico (1 unidade), segue o pipeline completo (domain-modeler → … → quality-checker).

| # | Ticket | Onda | Prioridade | Depende de | Escopo |
|---|--------|------|:---------:|------------|--------|
| T01 | [domain-models-foundation](tickets/T01-domain-models-foundation/) | 1 | P0 | — | Criar `domain/models/` próprios (Patient, FamilyMember, HousingCondition, ...); só signatures |
| T02 | [mappers-migration](tickets/T02-mappers-migration/) | 1 | P1 | T01 | Mover `logic/mappers/` + `ui/home/mappers/` → `data/mappers/`; 1 mapper por endpoint, retorna `Result<T>` |
| T03 | [split-http-client](tickets/T03-split-http-client/) | 1 | P0 | T01 | Quebrar `HttpSocialCareClient` (643L/24 métodos) em 6 services especializados |
| T04 | [pilot-housing](tickets/T04-pilot-housing/) | 2 | P0 | T01, T02, T03 | **Feature piloto**: migrar Housing 100% para Contract A; remover import de `shared/` |
| T05–T12 | fichas de avaliação | 2 | P0 | T04 | Replicar template de T04 em 8 fichas (socioeconomic, work-income, education, health, community-support, social-health-summary, intake-info, social-identity) |
| T13 | [family-composition](tickets/T13-family-composition/) | 2 | P0 | T04 | Ficha de família — mais complexa (modais, lookups) |
| T14 | [violation-report](tickets/T14-violation-report/) | 2 | P0 | T04 | Relatório de violação |
| T15 | [home-detail-translator](tickets/T15-home-detail-translator/) | 2 | P0 | T02 | Mover `PatientDetailTranslator` de `ui/home/models/` → `data/mappers/` |
| T16 | [patient-registration-flow](tickets/T16-patient-registration-flow/) | 3 | P0 | T13 | Refactor wizard: 1 payload gordo para BFF (em vez de multi-request cliente) |
| T17 | [team-admin-flow](tickets/T17-team-admin-flow/) | 3 | P0 | T03 | Remover endpoints `/people/by-cpf/*` do cliente; usar `/team/*` |
| T18 | [convention-fixes](tickets/T18-convention-fixes/) | 4 | P1/P2 | — | Renomear `viewModel/` → `view_models/`; `SentryLoggerImpl` → `SentryLogger`; consertar 2 `throw`; memoizar getter |
| T19 | [activate-shared-lint](tickets/T19-activate-shared-lint/) | 4 | P0 | T16, T17 | Adicionar custom lint proibindo `package:shared/` fora de `data/{model,services,mappers}` |

Total: **19 tickets** agrupados em **4 ondas**.

## Completed Phases
- [x] Scope mapping (`handbook/reports/COMPLIANCE_REPORT_2026_04_16.md`)
- [x] Contract A reference (`handbook/architecture/CONTRACT_A_PUBLIC_API.md`)
- [x] Skill reference registered (SKILL.md §12)
- [x] Phase scaffold + 19 tickets created
- [ ] 000-discuss/CONTEXT.md — pendente de confirmação do usuário
- [ ] T01 execução

## Non-Regression Contract
> Nenhuma mudança pode quebrar o app em produção. Estratégia por ticket:
> 1. `melos run analyze` limpo ao final.
> 2. Tests passando (RED → GREEN).
> 3. Deploy Web validado manualmente em staging antes do merge.
> 4. Legado (ex: `HttpSocialCareClient`) só é deletado quando 100 % das features migraram (Onda 4 — T19).
> 5. Cada ticket abre PR próprio; PRs pequenos e revisáveis.

## Blockers
(nenhum)

## Context for Resume
Last action: phase scaffolded, 19 tickets criados como pastas vazias. Ticket detalhado (com 000-request.md próprio) foi criado apenas para T01 e T04; os demais têm stub.
Next action: usuário confirma ordem/granularidade. Se OK, executar T01 (foundation).
