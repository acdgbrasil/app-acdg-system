# Ticket State: D01-pump-engine-helpers-factory

phase: done
status: closed 2026-05-02

## Outcome
- 5-wave pipeline executada sem rejection (W0 → W0.5 → W0.5-bis → W1 → W2 → W3)
- 24 new tests RED → 450 GREEN +1 skip no Desktop (426 baseline preserved + 24 new)
- 2122 GREEN +1 skip total BFF (era 2098 — delta +24)
- dart analyze zero issues, format clean
- `social_care_desktop.dart` reduzido de 718L → 637L (-81L)

## Padrões GoF
- Factory Method (DriftExecutorFactory)

## REGRA #2 exceptions
- 4 tests com fixture inválida fixados via `_ProbeDb` shim + substring catch (W0.5-bis)
- Comments explicativos em cada test

## Next
D02 — UseCases Builders por Bounded Context
