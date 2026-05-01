# T05 — Socioeconomic Feature

## Onda: 2 | Prioridade: P0 | Profile: `feature`
## Depende de: T04 (pilot template aprovado)

## Escopo
Replicar o template de T04 (Housing) para a ficha **Socioeconomic**.

- Endpoint: `PUT /api/patients/:id/assessment/socioeconomic`
- ViewModel: `ui/socio_economic/view_models/socio_economic_view_model.dart`
- UseCase: `logic/use_case/assessment/update_socio_economic_use_case.dart` → mover para `ui/socio_economic/use_cases/`
- Mapper: `data/mappers/socioeconomic_mapper.dart` (já em T02)
- Service: `AssessmentService.updateSocioeconomic` (já em T03)

## Waves
Pipeline completo (como T04): domain-check → test-writer → service+mapper → repository → usecase → viewmodel → view → reviewer → quality.

## Critérios de aceitação
- [ ] 0 imports de `package:shared/` em `ui/socio_economic/**`
- [ ] 0 imports de `package:shared/` no UseCase (agora em `ui/<feature>/use_cases/`)
- [ ] Tests GREEN
- [ ] Feature funciona em staging
