# T17 — Team Admin Flow

## Onda: 3 | P0 | Profile: `feature`
## Depende de: T03 (services split — `PatientService` ou novo `TeamService`)

## Escopo
Migrar feature de administração de equipe (professionals/roles) para Contract A. Remover do cliente o conhecimento de que existe "People Context" (vazamento de topologia).

## Estado atual (BFF Web)
- Rotas já existentes: `/team/*` (boa) + `/team/people/*` (VAZA — "people" é implementação interna)
- Flutter hoje provavelmente consome ambas

## Contract A alvo
Apenas endpoints `/team/*` (nenhum `/people/*` visível ao cliente):
```
GET  /api/team
POST /api/team
GET  /api/team/{id}
PUT  /api/team/{id}/deactivate
PUT  /api/team/{id}/reactivate
POST /api/team/{id}/reset-password
POST /api/team/{id}/roles
PUT  /api/team/{id}/roles/{roleId}/deactivate
PUT  /api/team/{id}/roles/{roleId}/reactivate
```

## Arquivos afetados (BFF + Flutter)
- BFF Web: `handlers/team_handler.dart` (já tem a maioria); remover endpoints `/team/people/*` (migrar para `/team/*`)
- BFF Web: adicionar `TeamIntent` + `TeamUseCase` se ainda não existirem (mais orquestração)
- Flutter: procurar chamadas a `/team/people/*` no cliente e remover

## Critérios
- [ ] 0 rotas `/team/people/*` consumidas pelo Flutter
- [ ] 0 rotas `/people/by-cpf/*` consumidas pelo Flutter (se existir)
- [ ] `TeamService.*` em `data/services/team_service.dart`
- [ ] Tests GREEN
