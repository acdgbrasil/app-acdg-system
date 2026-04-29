# A09 — Web: Registry (Family + Social Identity + Audit)

## Onda: 3 | Profile: bff/social_care_web | Depende de: A08

## Escopo
Endpoints complementares de Registry:
- `POST /api/patients/:id/family` (add family member — orquestra PeopleContext + SocialCare)
- `DELETE /api/patients/:id/family/:memberId`
- `PUT /api/patients/:id/family/:memberId/primary-caregiver`
- `PUT /api/patients/:id/social-identity`
- `GET /api/patients/:id/audit-trail`

## Critérios
- [ ] 5 endpoints funcionais
- [ ] Intents + UseCases consumindo `RegistryContract`
- [ ] Zero `SocialCareContract`
- [ ] `dart analyze bff/social_care_web` verde

## Status
pending — blocked by A08
