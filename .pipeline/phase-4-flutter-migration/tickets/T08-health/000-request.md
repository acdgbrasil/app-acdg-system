# T08 — Health Status Feature

## Onda: 2 | P0 | Profile: feature | Depende de: T04

## Escopo
Replicar template T04 para ficha **Health Status**.
- Endpoint: `PUT /api/patients/:id/assessment/health`
- Feature: `ui/health_status/` (tem componentes complexos: deficiencies, lookups)
- UseCase: mover para `ui/health_status/use_cases/`

## Critérios
- [ ] 0 imports de `shared/` em `ui/health_status/**` (hoje: 4 violações — `*_view_model.dart`, `health_deficiency_card.dart`, `health_deficiencies_section.dart`, `health_lookup_dropdown.dart`)
- [ ] Tests GREEN
- [ ] Valida em staging
