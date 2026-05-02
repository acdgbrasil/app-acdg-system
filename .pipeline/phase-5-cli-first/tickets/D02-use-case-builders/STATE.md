# Ticket State: D02-use-case-builders

phase: done
status: closed 2026-05-02

## Outcome
- 4-wave pipeline executada sem rejection (W0 → W0.5 → W1 → W2 → W3)
- 21 new tests RED → 471 GREEN +1 skip Desktop (450 baseline preserved + 21 new)
- 2143 GREEN +1 skip total BFF (era 2122 — delta +21)
- dart analyze zero issues, format clean
- `social_care_desktop.dart` reduzido de 637L → 364L (-273L, -42.9%)
- 7 sub-facades reduzidas (-129L coletivos)
- 7 builders criados (610L total)

## Padrão arquitetural
- Composição + SRP por bounded context (não GoF formal — princípio Composition Root)

## Behavior preservation
- W2 mechanical audit (Python script) confirmou 42/42 use cases byte-identical com legacy

## Spec divergence APPROVED
- Abstract `XxxContract` em `build()` signatures (em vez de concrete `XxxRemote` do spec) — fundamentado

## Next
D03 — DesktopAssembler (Builder GoF) + AutoDrainObserver (Observer GoF)
