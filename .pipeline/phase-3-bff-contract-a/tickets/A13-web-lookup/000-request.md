# A13 — Web: Lookup (governance)

## Onda: 3 | Profile: bff/social_care_web | Depende de: A06

## Escopo
Endpoints individuais de lookup (1 tabela por request):
- `GET /api/lookups/:tableName`
- `POST /api/lookups/:tableName` (admin)
- `PUT /api/lookups/:tableName/:id`
- `PATCH /api/lookups/:tableName/:id/toggle`
- `GET /api/lookup-requests`
- `POST /api/lookup-requests`
- `PUT /api/lookup-requests/:id/approve`
- `PUT /api/lookup-requests/:id/reject`

Intents + UseCases consumindo `LookupContract`.

## Critérios
- [ ] 8 endpoints funcionais
- [ ] Zero `SocialCareContract`
- [ ] `dart analyze bff/social_care_web` verde

## Status
pending — blocked by A06
