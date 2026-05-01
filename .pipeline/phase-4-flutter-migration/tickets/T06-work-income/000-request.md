# T06 — Work & Income Feature

## Onda: 2 | Prioridade: P0 | Profile: `feature` | Depende de: T04

## Escopo
Replicar template T04 para ficha **Work & Income**.
- Endpoint: `PUT /api/patients/:id/assessment/work-income`
- ViewModel: `ui/work_and_income/view_models/work_and_income_view_model.dart`
- UseCase: mover para `ui/work_and_income/use_cases/`
- Mapper: `data/mappers/work_and_income_mapper.dart` (T02)
- Service: `AssessmentService.updateWorkIncome` (T03)

## Critérios
- [ ] 0 imports de `shared/` em `ui/work_and_income/**` e no UseCase
- [ ] Tests GREEN
- [ ] Valida em staging
