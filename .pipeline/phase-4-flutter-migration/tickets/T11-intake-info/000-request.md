# T11 — Intake Info Feature

## Onda: 2 | P0 | Profile: feature | Depende de: T04

## Escopo
Replicar template T04 para ficha **Intake Info**.
- Endpoint: `PUT /api/patients/:id/intake` (não é sob `/assessment/`)
- Feature: `ui/intake_info/` (tem `programs_section.dart`, `ingress_type_section.dart`)
- Service: `CareService.updateIntakeInfo`

## Critérios
- [ ] 0 imports de `shared/` em `ui/intake_info/**` (hoje: 3 violações)
- [ ] Tests GREEN
