# Ticket State: A12-web-protection

## Current Phase
phase: done
agent: implementer (Wave 1 GREEN)
status: completed — 100 new tests GREEN; 590 canon total GREEN

## Completed Phases
- [x] 000-request — 3 endpoints (referrals + violations + placement-history)
- [x] 002-tests — Wave 0 RED (86 tests; decisão mista P2/P2b por DTO)
- [x] 003-implementation — Wave 1 GREEN (6 prod + 1 rewrite + 2 wiring)

## Resultado
- 3 Intents: 2 P2 (Referral, Violation — enumeração dinâmica) + 1 P2b (PlacementHistory — try/catch com obs?.logError)
- 3 UseCases (2 retornam id, 1 void com rewrap)
- 1 Handler ProtectionHandler rewrite (legacy A05 deletado — tinha `catch (e) { jsonError(400, 'Invalid: $e') }` leaky)
- `app_router.dart` com ProtectionContract injetado + Cascade patient→family→assessment→care→protection
- 100 tests A12 + 490 prévios = **590 GREEN**

## Invariantes arquiteturais validadas
- **P2 e P2b coexistem no mesmo handler** via signature do Intent (não via fork)
- **Breadcrumb `.received` shape estrito** — `keys.toSet() == {'patientId'}` previne drift silencioso
- **UseCase rewrap** (`Result<void>` → `Result<StandardResponse<void>>`) mantém handler simétrico
- **Mensagem P2 dinâmica** enumera missing fields pelo NOME (nunca valores)
- **Mensagem P2b fixa** estrutural genérica protege shape + PII

## Aprendizados para A13–A15
1. Carrier da decisão P2/P2b é a assinatura do Intent (handler agnóstico)
2. Sub-DTOs PII-densos exigem pinning `keys.toSet()` no breadcrumb
3. Lints Camada 2 catch anti-pattern legacy imediatamente

## Débito técnico
- Handlers legacy A13–A15 (lookup, health, team) ainda quebrados por `SocialCareContract` undefined
- `FakeProtectionBff()` no bin/server.dart até adapter HTTP real (A21)
