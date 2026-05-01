# T07 — Educational Status Feature

## Onda: 2 | P0 | Profile: feature | Depende de: T04

## Escopo
Replicar template T04 para ficha **Educational Status**.
- Endpoint: `PUT /api/patients/:id/assessment/education`
- Feature: `ui/educational_status/`
- UseCase: mover para `ui/educational_status/use_cases/`
- Mapper (T02) + Service (T03) já prontos.

## Critérios
- [ ] 0 imports de `shared/` em `ui/educational_status/**`
- [ ] Tests GREEN
- [ ] Valida em staging
