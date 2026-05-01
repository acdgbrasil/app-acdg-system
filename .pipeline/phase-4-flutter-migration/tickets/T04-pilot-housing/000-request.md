# T04 — Pilot: Housing Feature

## Onda: 2 (Fichas)
## Prioridade: P0
## Profile: `feature`
## Depende de: T01 (domain models), T02 (mappers), T03 (services split)

## Objetivo
**Piloto end-to-end** do Contract A. Migrar a ficha Housing de importar `bff/shared/` para consumir domain models próprios. Servirá de template para as outras 10 fichas.

## Por que Housing?
- 1 endpoint apenas: `PUT /api/patients/:id/assessment/housing`
- Sem modais, sem wizard, sem lookups dinâmicos
- ViewModel simples com 1 Command (save)
- Arquivos atuais:
  - `ui/housing_condition/view_models/housing_condition_view_model.dart` (importa `shared`)
  - `ui/housing_condition/view/page/housing_condition_page.dart`
  - `ui/housing_condition/view/components/*`
  - `logic/use_case/assessment/update_housing_condition_use_case.dart` (importa `shared`)
  - `logic/mappers/assessment_mapper.dart` (parcialmente)

## Waves

### Wave 0: Design
- [x] flutter-domain-modeler → confirma `HousingCondition` (já criado em T01)
- [x] flutter-test-writer → testes RED (ViewModel, Repository, Mapper)

### Wave 1: Data Layer (parallel)
- [x] flutter-service-builder → `AssessmentService.updateHousing(payload)` (se ainda não existir em T03)
- [x] flutter-mapper-engineer → `HousingConditionMapper` em `data/mappers/`, retorna `Result<HousingConditionPayload>` / `Result<HousingCondition>`

### Wave 2: Data Integration
- [x] flutter-repository-architect → `AssessmentRepository.updateHousing(String patientId, HousingCondition data)`. Internamente: mapper (domain→payload) + service.call().

### Wave 3: Logic
- [x] flutter-usecase-orchestrator → `UpdateHousingConditionUseCase` — **remove** import de `shared`, recebe/retorna domain.
  - Move de `logic/use_case/assessment/` → `ui/housing_condition/use_cases/` (alinhar com skill §Structure).

### Wave 4: UI
- [x] flutter-viewmodel-engineer → `HousingConditionViewModel` — **remove** import de `shared`, Command pattern, getters memoizados.
- [x] flutter-view-implementer → Page/Organisms/Molecules/Atoms auditados; remover imports de `shared` em componentes; usar Selectors/Connectors.

### Wave 5: Quality
- [x] flutter-code-reviewer (Non-Negotiables 1–23 + Contract A boundary check)
- [x] flutter-quality-checker (`dart analyze`, `dart format`, `run_tests` via Dart MCP Server)

## Critérios de aceitação
- [ ] Zero `import 'package:shared/shared.dart';` em `ui/housing_condition/**`.
- [ ] Zero `import 'package:shared/shared.dart';` em `logic/use_case/assessment/update_housing_condition_use_case.dart` (ou no novo path).
- [ ] `HousingCondition` domain model consumido do `domain/models/housing_condition.dart`.
- [ ] Mapper em `data/mappers/housing_condition_mapper.dart` com `Result<T>` + switch exhaustivo.
- [ ] Service em `data/services/assessment_service.dart` (1 método: `updateHousing`).
- [ ] Repository abstract: `AssessmentRepository`. Concrete: `HttpAssessmentRepository`.
- [ ] Tests GREEN (ViewModel, Repository, Mapper, Widget smoke).
- [ ] `melos run analyze` verde.
- [ ] Feature funciona em staging (validação manual).

## Template gerado
Após aprovar T04, o mesmo shape replica em T05..T12:
```
<feature>_view_model.dart   — sem import shared
<feature>_use_case.dart     — em ui/<feature>/use_cases/, sem import shared
<feature>_mapper.dart       — em data/mappers/, Result<T>
assessment_service.<method> — em data/services/assessment_service.dart
```

## Non-Regression
- Código antigo (`logic/use_case/assessment/update_housing_condition_use_case.dart`) **deletado** neste ticket.
- Se for reutilizado por outra feature (grep para confirmar), postergar o delete para T18.
- Rota `PUT /api/patients/:id/assessment/housing` NÃO MUDA no BFF — só o cliente muda.

## Artefatos esperados
```
.pipeline/phase-3-flutter-acl/tickets/T04-pilot-housing/
├── 000-request.md
├── 001-contracts/REPORT.md      (confirma HousingCondition de T01)
├── 002-tests/REPORT.md          (lista dos tests criados)
├── 003-services/REPORT.md
├── 003-mappers/REPORT.md
├── 003-repositories/REPORT.md
├── 003-usecases/REPORT.md
├── 003-viewmodels/REPORT.md
├── 003-views/REPORT.md
├── 004-code-review/REVIEW.md
├── 005-quality/QUALITY.md
├── STATE.md
└── FINAL.md
```

## Agentes responsáveis
- flutter-domain-modeler (confirm)
- flutter-test-writer
- flutter-service-builder
- flutter-mapper-engineer
- flutter-repository-architect
- flutter-usecase-orchestrator
- flutter-viewmodel-engineer
- flutter-view-implementer
- flutter-code-reviewer
- flutter-quality-checker

## Tempo estimado
1–2 sessões (4–8 h com revisão).
