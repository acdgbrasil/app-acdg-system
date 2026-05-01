# T12 — Social Identity Feature

## Onda: 2 | P0 | Profile: feature | Depende de: T04

## Escopo
Replicar template T04 para ficha **Social Identity**.
- Endpoint: `PUT /api/patients/:id/social-identity`
- Feature: `ui/social_identity/`
- Service: `PatientService.updateSocialIdentity` (pertence a Registry, não Assessment)

## Critérios
- [ ] 0 imports de `shared/` em `ui/social_identity/**`
- [ ] Tests GREEN
