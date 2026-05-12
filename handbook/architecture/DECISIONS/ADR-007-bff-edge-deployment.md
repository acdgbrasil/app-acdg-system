# ADR-007: BFF Web Deployment no Edge

**Data:** 2026-03 (reconstituído a partir de `frontend/CLAUDE.md`)
**Status:** Aceito (reconstituído)
**Relacionado:** [ADR-002](ADR-002-bff-backend-for-frontend.md), [ADR-008](ADR-008-dart-aot.md)

## Contexto

BFF Web (`apps/social_care_bff/web/`) precisa estar próximo do cliente geograficamente para reduzir latência, mas também próximo do backend Swift/Vapor para reduzir hops internos.

## Decisão

BFF Web é deployado em **Edge** (camada próxima ao cliente final), via servidor Dart **Darto** (HTTP server).

- Frontend Flutter Web → BFF Edge → backend Swift/Vapor (data center).
- BFF Edge proxia + agrega + traduz Contract B (backend) em Contract A (cliente).

## Consequências

- Latência cliente → BFF baixa (Edge).
- Agregação de chamadas múltiplas ao backend acontece no Edge, reduzindo round-trips do cliente.
- TLS termina no Edge.
- Tokens (Bearer JWT) são extraídos / validados no Edge via [ADR-023](ADR-023-bff-adapter-bearer-forwarding.md).

## Status atual (2026-05-12)

- BFF Web em `apps/social_care_bff/web/` — produção via container Docker no Kubernetes (Flux CD).
- Infraestrutura definida em `edge-cloud-infra/` (repo separado).

## Superseded by

Nenhum.
