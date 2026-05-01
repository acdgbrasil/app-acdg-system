# Ticket State: T03-split-http-client

## Current Phase
phase: request
agent: —
status: rolled-back — timeout at ~42min, artifacts incomplete (9 files missing, broken exports)

## Rollback realizado em 2026-04-17
- `git restore` em: `social_care.dart`, `patient_repository.dart`, `bff_patient_repository.dart`, `http_social_care_client.dart`, `patient_service.dart`
- Removido: `legacy_patient_service.dart`

## Lição aprendida
Escopo do ticket era grande demais (11 arquivos + 6 bounded contexts). Próxima tentativa: fatiar em 6 sub-tickets paralelos, 1 por bounded context.

## Profile: data-layer (services only)

## Next Action
flutter-service-builder + flutter-repository-architect quebram `HttpSocialCareClient` (643L) em 6 services.
