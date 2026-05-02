# Ticket State: D03-assembler-observer

phase: done
status: closed 2026-05-02 — **Onda 1.5 fechada (D01+D02+D03)**

## Outcome
- 4-wave pipeline executada sem rejection (W0 → W0.5 → W1 → W2 → W3)
- 29 new tests RED → 500 GREEN +1 skip Desktop (471 baseline preserved + 29 new)
- 2172 GREEN +1 skip total BFF (era 2143 — delta +29)
- dart analyze zero issues, format clean
- `social_care_desktop.dart` reduzido 364L → 184L (-180L, -49.5%)
- `late SocialCareDesktop desktop` self-reference ELIMINADO

## Padrões GoF aplicados
- Builder (DesktopAssembler com 7 setters fluent + 8-fase build)
- Observer (AutoDrainObserver — engine privado, edge offline→online, dispose idempotente)

## REGRA #2 4-point analysis (W1 path-resolution gate)
- Bug de impl detectado por tests (path_provider chamado quando inMemory factory)
- Fix: gate `defaultDesktopFilePath()` atrás de `!isInMemory`
- Zero tests modificados

## Onda 1.5 retrospectiva (D01+D02+D03)
- Facade: 718L → 184L (-74.4%, -534L total)
- Tests: +74 (24+21+29)
- Padrões GoF formalizados: Factory Method, Builder, Observer

## Next
**C01 — CLI Scaffold** (Onda 2 da Phase 5)
