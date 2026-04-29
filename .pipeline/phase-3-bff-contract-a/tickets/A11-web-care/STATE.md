# Ticket State: A11-web-care

## Current Phase
phase: done
agent: implementer (Wave 1 GREEN)
status: completed — 57 new tests GREEN; 482 canon total GREEN

## Completed Phases
- [x] 000-request — 2 endpoints (POST /appointments + PUT /intake)
- [x] 002-tests — Wave 0 RED (55 tests, decisão P2 pinada)
- [x] 003-implementation — Wave 1 GREEN (4 prod + 1 rewrite + 2 wiring)

## Resultado
- 2 Intents P2 if-case (1 const error + 1 dynamic missing enumeration)
- 2 UseCases tríade canônica (1 retorna id, 1 void)
- 1 Handler CareHandler rewrite (legacy A05 deletado)
- `app_router.dart` com CareContract injetado + Cascade patient→family→assessment→care
- 57 tests A11 GREEN + 425 prévios = **482 GREEN**
- `dart analyze` zero errors no escopo A11

## Invariantes arquiteturais confirmadas
- **P2 vs P2b decision tree funcionou** — 1ª aplicação pós-ADR-019 do path "default"
- Gatilho P2b falhou (≤2 required, non-PII-dense) → P2 if-case manual
- Enumeração de missing em mensagem (Intake) só é possível com P2, não try/catch
- Lints Camada 2 (`empty_catches`, `exhaustive_cases`, `no_default_cases`, `unnecessary_lambdas`) passam clean no escopo A11

## Débito técnico
- Handlers legacy A12–A15 (lookup, protection, health, team) ainda quebrados por `SocialCareContract` undefined — cada ticket resolve próprio
- `FakeCareBff()` no `bin/server.dart` até adapter HTTP real (A21)
