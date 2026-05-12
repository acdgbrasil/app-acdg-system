# ADR-002: BFF (Backend for Frontend) como Mediador

**Data:** 2026-03 (reconstituído a partir de `frontend/CLAUDE.md`)
**Status:** Aceito (reconstituído)

## Contexto

Cliente Flutter direto contra backend Swift/Vapor (`social-care/`) tem dois problemas:

1. **Acoplamento alto** — qualquer mudança contratual do backend obriga release sincronizado do cliente.
2. **Lógica de negócio vazaria para o cliente** — agregações de chamadas, transformação de payload, retry strategy, cache local, autorização derivada de JWT.

## Decisão

Inserir um **BFF** entre o cliente Flutter e o backend Swift/Vapor:

- **BFF Web** — servidor Dart (Darto) no Edge, expõe Contract A.
- **BFF Desktop** — package Dart importado in-process (sem rede), mesmo Contract A.
- **Contract A** — superfície pública que o cliente consome. Versionada.
- **Contract B** — superfície interna BFF → backends. Pode mudar sem afetar cliente.

**Toda regra de negócio fica no BFF**, nunca no Flutter. Frontend trata models como **schemas puros**.

## Consequências

- Cliente Flutter fica fino — só renderização + UX.
- BFF agrega chamadas de múltiplos backends (`social-care`, `people-context`, etc.) num único `Contract A`.
- Versão de Contract A é a unidade de release do cliente.
- Two deployment surfaces (Web vs Desktop) compartilham o mesmo código BFF via package Dart importado.

## Status atual (2026-05-12)

- BFF Web em `apps/social_care_bff/web/` — Phase 3 fechada com 22/22 tickets e 2036 testes GREEN.
- BFF Desktop em `apps/social_care_bff/desktop/` — rebuild Onda 4 fechado (Drift cache + SyncEngine).
- Contract A em `apps/social_care_bff/contracts/` documentado em [CONTRACT_A_PUBLIC_API.md](../CONTRACT_A_PUBLIC_API.md).

## Relacionado

- [ADR-007](ADR-007-bff-edge-deployment.md) — deployment do BFF Web no Edge.
- [ADR-008](ADR-008-dart-aot.md) — Dart AOT para BFF Web.
- [ADR-022](ADR-022-kernel-infra-apps-layout.md) — BFF como app first-class em `apps/`.
- [ADR-023](ADR-023-bff-adapter-bearer-forwarding.md) — adapter BFF→backend encaminha `Authorization: Bearer <jwt>`.

## Superseded by

Nenhum.
