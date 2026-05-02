# C09 — CLI Team Commands

## Onda: 4 | Profile: feature | Depende de: C08

## Escopo

9 endpoints team (sem `/people/by-cpf/*` removidos em A15):

```bash
# Read
acdg team list [--role=X] [--active=true|false] [--search=Y]
acdg team get <member-id>

# Worker lifecycle
acdg team register --cpf=X --first-name=Y --role=Z [...]
acdg team deactivate <member-id>
acdg team reactivate <member-id>
acdg team reset-password <member-id>

# Roles
acdg team role assign <member-id> --role=X --system=Y
acdg team role deactivate <member-id> <role-id>
acdg team role reactivate <member-id> <role-id>
```

### Sub-contracts BFF consumidos
- `TeamContract` (listTeam, getTeamMember, registerWorker, deactivate, reactivate, resetPassword, assignRole, deactivateRole, reactivateRole)

### Detalhes

- **register** é endpoint composto — PeopleContext.register + Team.createWorker + Team.assignRole inicial.
- **list** scatter-gather (Team + PeopleContext + roles) em 1 request.
- **role assign** distingue entre sistemas (`social_care`, `analytics_bi`, etc.) via `--system`.

## Pipeline

W0 → W1 → W2 → W3

## Critérios

- [ ] 9 comandos funcionais
- [ ] register saga compensação tested
- [ ] `dart analyze` zero issues

## Status
pending — blocked by C08
