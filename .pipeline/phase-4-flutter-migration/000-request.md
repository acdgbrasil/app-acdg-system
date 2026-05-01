# Phase 3 — Flutter ACL (Contract A Boundary)

## Escopo macro
Migrar `packages/social_care/` para consumir **Contract A** (próprio do Flutter) em vez de importar diretamente `package:shared/shared.dart`, estabelecendo ACL real entre Flutter e BFF.

## Motivação
`handbook/reports/COMPLIANCE_REPORT_2026_04_16.md` identificou:
- **63 imports** de `package:shared/` em camadas proibidas (ViewModels, UseCases, Views).
- **God-interface** `HttpSocialCareClient` (643 linhas, 24 métodos, 5 bounded contexts).
- **5 divergências estruturais** (`logic/`, `data/commands/`, `domain/schemas/`, `viewModel/` camelCase × 2).
- **2 ACLs primitivos** (`PatientTranslator`, `PatientDetailTranslator`) com responsabilidade de mapper em camadas erradas.

## Referências arquiteturais
- `.claude/skills/flutter-expert/SKILL.md` — 23 Non-Negotiables
- `.claude/skills/flutter-expert/references/contract_a_public_api.md` — Contract A
- `handbook/architecture/CONTRACT_A_PUBLIC_API.md` — documento canonical
- `handbook/reports/COMPLIANCE_REPORT_2026_04_16.md` — auditoria base

## Ondas e tickets

### Onda 1 — Infraestrutura (P0/P1)
Criar as bases sem mudar comportamento visível.

- **T01 — Domain Models Foundation** (P0)
  Criar `packages/social_care/lib/src/domain/models/` com entidades próprias (Patient, FamilyMember, HousingCondition, Assessment sub-types, Person, Role, Referral, ViolationReport, Appointment). Todas: `with Equatable`, `copyWith`, imutáveis, **sem fromJson/toJson**.

- **T02 — Mappers Migration** (P1)
  Mover `packages/social_care/lib/src/logic/mappers/*.dart` + `packages/social_care/lib/src/ui/home/mappers/*.dart` → `packages/social_care/lib/src/data/mappers/`. Reorganizar: 1 mapper por endpoint do Contract A, retorna `Result<T>`, switch exhaustivo.

- **T03 — Split HttpSocialCareClient** (P0)
  Quebrar o god-service em 6 services:
  - `patient_service.dart` (Registry)
  - `assessment_service.dart` (9 fichas)
  - `care_service.dart` (Appointments, Intake)
  - `protection_service.dart` (Violations, Referrals, Placement)
  - `lookup_service.dart` (Dominios + Requests)
  - `audit_service.dart` (Audit trail)

### Onda 2 — Fichas (P0)
Piloto + replicação por ficha. Cada uma remove `package:shared/` da ViewModel/UseCase/View e consome domain models próprios.

- **T04 — Pilot: Housing** — validar template end-to-end.
- **T05 — Socioeconomic** (após T04)
- **T06 — Work & Income**
- **T07 — Education**
- **T08 — Health**
- **T09 — Community Support**
- **T10 — Social Health Summary**
- **T11 — Intake Info**
- **T12 — Social Identity**
- **T13 — Family Composition** (mais complexo: modais + lookups)
- **T14 — Violation Report**
- **T15 — Home Detail Translator** — migrar `PatientDetailTranslator` de `ui/home/models/` → `data/mappers/`.

### Onda 3 — Fluxos compostos (P0)
Features que orquestram múltiplos endpoints no cliente — refactor para 1 request.

- **T16 — Patient Registration Flow**
  Hoje: 5–15 requests do cliente (PeopleContext + SocialCare + updates).
  Depois: 1 `POST /api/patients` com payload gordo; BFF orquestra (UseCase do BFF Web já existe).

- **T17 — Team Admin Flow**
  Remover endpoints `/people/by-cpf/*` do cliente; consolidar em `/team/*`.

### Onda 4 — Convenções e guardrail (P1/P2)

- **T18 — Convention Fixes**
  - Renomear `ui/home/viewModel/` → `view_models/`
  - Renomear `ui/patient_registration/viewModel/` → `view_models/`
  - Renomear `SentryLoggerImpl` → `SentryLogger`
  - Consertar `logic/mappers/intervention_mapper.dart:91` (`throw` → `Result.error`)
  - Memoizar `refPersonName` getter em `patient_registration_view_model.dart`
  - Mover ou eliminar `data/commands/` (decisão no discuss)
  - Mover ou eliminar `domain/schemas/` (decisão no discuss)
  - Eliminar pasta `logic/` após T02 + T05…T14 (todos os UseCases/mappers migrados)

- **T19 — Activate Shared Lint** (P0 no final)
  Adicionar custom lint em `packages/social_care/analysis_options.yaml` que proíbe `package:shared/shared.dart` fora de `data/{model,services,mappers}`. Garantia contra regressão.

## Pipeline por ticket
Cada ticket segue o pipeline-maestro com agentes especializados da skill `flutter-expert`:

```
000-request.md (scope) → 000-discuss/CONTEXT.md (decisões) →
 flutter-domain-modeler → flutter-test-writer →
 flutter-service-builder + flutter-mapper-engineer (parallel) →
 flutter-repository-architect → flutter-usecase-orchestrator →
 flutter-viewmodel-engineer → flutter-view-implementer →
 flutter-code-reviewer → flutter-quality-checker → FINAL.md
```

Waves dentro de cada ticket são selecionadas conforme o perfil (`domain-only`, `data-layer`, `ui-only`, `feature`).

## Critérios de aceitação da fase
- [ ] 0 imports de `package:shared/` fora de `data/{model,services,mappers}` em `packages/social_care/`.
- [ ] `HttpSocialCareClient` deletado.
- [ ] `PatientTranslator` e `PatientDetailTranslator` deletados (substituídos por `data/mappers/`).
- [ ] Pasta `logic/` eliminada.
- [ ] Pastas `viewModel/` renomeadas para `view_models/`.
- [ ] Custom lint ativo e passando no CI.
- [ ] `melos run analyze` verde.
- [ ] `melos run test` verde.
- [ ] Staging validado manualmente.
- [ ] Score `COMPLIANCE_REPORT` re-rodado: 100 % Contract A, 100 % Non-Negotiables.

## Estratégia de merge
- 1 ticket = 1 PR
- PRs pequenos (< 500 linhas de diff idealmente)
- CI verde obrigatório
- Review manual antes do merge
- Merges em `dev`; deploy após cada onda completa.

## Riscos
- **Regressão silenciosa** em fichas já estáveis → mitigar com widget tests por feature (flutter-test-writer obrigatório).
- **Divergência entre Flutter e BFF Web** durante migração — mitigar com monitoramento de erros em staging.
- **Scope creep** — regra: 1 ticket não pode mexer em mais de 1 feature (exceto T01, T02, T03 que são infraestrutura).
