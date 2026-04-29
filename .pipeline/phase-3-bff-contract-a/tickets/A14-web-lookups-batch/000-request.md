# A14 — Web: Lookup Batch Composto

## Onda: 3 | Profile: bff/social_care_web | Depende de: A13

## Escopo
Endpoint composto:
- `GET /api/lookups?tables=parentesco,identidade,ingresso,programas`

Retorna várias tables em 1 response. Elimina os `Future.wait` que o Flutter faz hoje em `PatientRegistrationViewModel`.

Payload de resposta: `LookupsBatchResponse { Map<String, List<LookupItem>> tables }`.

## Critérios
- [ ] Endpoint funcional
- [ ] Intent + UseCase dedicado (batching interno)
- [ ] Zero `SocialCareContract`
- [ ] `dart analyze bff/social_care_web` verde

## Status
pending — blocked by A13
