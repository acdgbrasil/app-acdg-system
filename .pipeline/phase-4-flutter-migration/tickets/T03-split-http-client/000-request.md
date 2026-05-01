# T03 — Split HttpSocialCareClient

## Onda: 1 | Prioridade: P0 | Profile: `data-layer` (services + repositories)
## Depende de: T01 (domain models)

## Escopo
Quebrar `packages/social_care/lib/src/data/services/http_social_care_client.dart` (643 linhas, 24 métodos, implementa `SocialCareContract`) em **6 services especializados**.

## Arquitetura alvo

```
packages/social_care/lib/src/data/services/
├── patient_service.dart       → /api/patients/* (register, get, list, lifecycle)
├── assessment_service.dart    → /api/patients/:id/assessment/* (9 fichas)
├── care_service.dart          → /api/patients/:id/appointments, /intake
├── protection_service.dart    → /api/patients/:id/{violations,referrals,placement-history}
├── lookup_service.dart        → /api/lookups/* + /api/lookup-requests/*
└── audit_service.dart         → /api/patients/:id/audit-trail
```

Cada service:
- **Stateless**, Dio injetado via construtor.
- **Não implementa** `SocialCareContract` (god-interface morre).
- Retorna `Result<Payload>` (tipo do `data/model/`), nunca domain.
- 1 método = 1 endpoint do Contract A.

## Repositories associados
Uma vez que services estão split, criar/ajustar repositórios:
```
packages/social_care/lib/src/data/repositories/
├── patient_repository.dart       (abstract + HttpPatientRepository)
├── assessment_repository.dart    (abstract + HttpAssessmentRepository)
├── care_repository.dart
├── protection_repository.dart
├── lookup_repository.dart        (já existe — ajustar)
└── audit_repository.dart
```

## Waves
- Wave 1: flutter-service-builder (6 services em paralelo)
- Wave 2: flutter-repository-architect (6 repositories, services privados)
- Wave 5: code-reviewer + quality-checker

## Critérios de aceitação
- [ ] 6 services criados, cada um ≤ 200 linhas.
- [ ] Zero `implements SocialCareContract` nos services novos.
- [ ] `HttpSocialCareClient` marcado `@deprecated` (delete em T19).
- [ ] Repositories com service **privado** (`final PatientService _service`).
- [ ] `dart analyze` verde.
- [ ] Tests GREEN (se existirem tests para `HttpSocialCareClient`, migrar ou adaptar).

## Non-Regression
`HttpSocialCareClient` continua existindo e funcional até T19. Fichas migradas em T04+ passam a usar services novos; fichas não-migradas continuam usando o god-client.
