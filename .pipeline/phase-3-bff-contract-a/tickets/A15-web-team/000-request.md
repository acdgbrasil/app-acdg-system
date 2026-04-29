# A15 — Web: Team (sem vazamento de topologia)

## Onda: 3 | Profile: bff/social_care_web | Depende de: A06

## Escopo
Endpoints de equipe **sem expor `/people/*`**:
- `GET /api/team` (listar profissionais)
- `POST /api/team` (cria — orquestra PeopleContext internamente)
- `GET /api/team/:id`
- `PUT /api/team/:id/deactivate`
- `PUT /api/team/:id/reactivate`
- `POST /api/team/:id/reset-password`
- `POST /api/team/:id/roles`
- `PUT /api/team/:id/roles/:roleId/deactivate`
- `PUT /api/team/:id/roles/:roleId/reactivate`

**Deletar rotas:**
- `/api/people/by-cpf/:cpf`
- `/api/team/people/*` (todas)

Orquestração interna pode usar PeopleContext, mas o APP não sabe disso.

## Critérios
- [ ] 9 endpoints funcionais
- [ ] Rotas `/people/*` e `/team/people/*` removidas
- [ ] Zero `SocialCareContract`
- [ ] `dart analyze bff/social_care_web` verde

## Status
pending — blocked by A06
