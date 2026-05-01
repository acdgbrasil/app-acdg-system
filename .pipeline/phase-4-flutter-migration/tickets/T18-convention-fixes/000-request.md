# T18 — Convention Fixes

## Onda: 4 | P1/P2 | Profile: custom (chore, multi-file)
## Depende de: — (pode correr em paralelo com outras ondas 2 e 3)

## Escopo
Resolver pendências menores de convenção identificadas no COMPLIANCE_REPORT.

## Checklist

### Rename pastas (P1)
- [ ] `packages/social_care/lib/src/ui/home/viewModel/` → `view_models/`
- [ ] `packages/social_care/lib/src/ui/patient_registration/viewModel/` → `view_models/`
- [ ] Atualizar todos os imports afetados

### Rename classes (P2)
- [ ] `packages/core/lib/src/infrastructure/logging/sentry_logger_impl.dart` → `sentry_logger.dart`
- [ ] Classe `SentryLoggerImpl` → `SentryLogger` (strategy name)
- [ ] Atualizar consumidores

### Conserta throws fora de adapters (P2)
- [ ] `packages/social_care/lib/src/logic/mappers/intervention_mapper.dart:91` — `throw StateError(...)` → `return Error(...)`
- [ ] Verificar se `patient_registration_view_model.dart:310` é padrão de exaustão (manter) ou refactor

### Memoize getter (P2)
- [ ] `packages/social_care/lib/src/ui/patient_registration/viewModel/patient_registration_view_model.dart:90-94` — `refPersonName` getter → cache + invalidar em `notifyListeners()`

### Decisões finais do discuss
- [ ] `data/commands/` — decisão Q1 aplicada (renomear para `data/model/*_payload.dart` ou mover para `ui/<feature>/models/`)
- [ ] `domain/schemas/` — decisão Q2 aplicada (validators para `data/model/` ou inlinar em UseCases)

### Cleanup
- [ ] Deletar pasta `logic/` se vazia após T02 + T05–T14
- [ ] Remover pasta `ui/home/mappers/` se vazia após T02 + T15

## Critérios
- [ ] Zero pastas com nome camelCase em `packages/social_care/lib/src/`.
- [ ] Zero classes com sufixo `Impl` em `packages/core/`.
- [ ] `dart analyze` verde.
- [ ] Tests GREEN.
