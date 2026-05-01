# T14 — Violation Report Feature

## Onda: 2 | P0 | Profile: feature | Depende de: T04

## Escopo
Replicar template T04 para ficha **Violation Report**.
- Endpoint: `POST /api/patients/:id/violations`
- Feature: `ui/violation_report/`
- Service: `ProtectionService.reportViolation` (T03)
- UseCase: `logic/use_case/protection/report_violation_use_case.dart` → `ui/violation_report/use_cases/`

## Critérios
- [ ] 0 imports de `shared/` em `ui/violation_report/**`
- [ ] Tests GREEN
