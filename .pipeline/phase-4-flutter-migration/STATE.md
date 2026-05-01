# Pipeline State: phase-4-flutter-migration

## Current Phase
phase: ready
agent: —
status: **DESTRAVADA 2026-05-01 — Phase 3 BFF Contract A fechou (22/22 tickets, A19+A20+A21 closed).** Aguarda kickoff do usuário.

## Razão da retomada
Em 2026-04-17 o plano foi invertido: BFF-first.
Phase 3 (`.pipeline/phase-3-bff-contract-a/`) fechou em 2026-05-01 com 22/22 tickets.
Esta Phase 4 destravou e absorve cleanup deferido (ver "Herança de A21" abaixo).

## Insumos preservados (prontos para consumo em Fase 4)
- T01 ✅ — 22 domain models em `packages/social_care/lib/src/domain/models/`
- T02 ✅ — 21 mappers em `packages/social_care/lib/src/data/mappers/`
- T03 ✅ (split) — HttpSocialCareClient dividido em `data/services/http/` (8 arquivos)

## Herança de A21 (cleanup deferido a Phase 4)

A21 BFF-side fechou; packages-side ficou para esta fase. Inventário a deletar quando cada feature for migrada:

### packages/social_care/lib/src/
- `data/services/http_social_care_client.dart` (643 LoC, implementa `SocialCareContract` deletada)
- `data/services/http/` split (8 arquivos):
  - `_http_shared.dart`, `assessment_http_client.dart`, `care_http_client.dart`,
    `health_http_client.dart`, `lookup_http_client.dart`, `people_http_client.dart`,
    `protection_http_client.dart`, `registry_http_client.dart`, `http_clients.dart`
- `data/services/patient_service.dart` (consome `SocialCareContract`)
- `data/repositories/bff_patient_repository.dart` (consome `SocialCareContract`)
- `data/repositories/bff_lookup_repository.dart` (consome `SocialCareContract`)
- `logic/use_case/registry/register_patient_use_case.dart` (consome `PatientTranslator`)

### packages/social_care/test/
- `data/services/http_social_care_client_test.dart`
- `ui/family_composition/family_composition_bugs_test.dart`

### apps/acdg_system/lib/logic/di/
- `infrastructure_providers.dart` — referência a `SocialCareContract`
- `app_providers.dart`
- `dependency_builders.dart`
- `social_care_providers.dart`

### bff/shared/lib/src/infrastructure/dtos/ (deferido — usados só por packages/)
- `patient_remote.dart` (+ `.g.dart`)
- `patient_overview.dart` (+ `.g.dart`)
- Test: `bff/shared/test/infrastructure/dtos/patient_remote_test.dart`
- **Phase 4** vai deletar simultaneamente: consumers em packages/ + DTOs no BFF + testes (evita janela de quebra).

### Verificação pós-Phase-4
```bash
grep -rln "SocialCareContract\b\|PatientTranslator\b\|HttpSocialCareClient\b" .  # esperado: vazio
```

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
Last action: Phase 3 fechou 2026-05-01 (A19+A20+A21 closed). Esta fase destravou; herança de A21 (cleanup deferido) foi absorvida na seção "Herança de A21" acima. T01 já tem progresso parcial (domain models criados). Os demais tickets têm stub — apenas T01 e T04 têm 000-request.md próprio.

Next action: usuário confirma se quer começar com T04 (Housing piloto, conforme spec original) ou se quer revisar a ordem dada que A21 herança ampliou o escopo Phase 4 com `apps/acdg_system/lib/logic/di/` rewire.
