# ADR-017: Organização de UI via Atomic Design

**Data:** 2026-03-13
**Status:** Aceito

## Contexto

Pastas de widgets estavam se tornando "sacos de arquivos" sem hierarquia clara de reuso.

## Decisão

Adotar rigorosamente o **Atomic Design**:

- `atoms/` — Componentes básicos, puros e agnósticos.
- `molecules/` — Composição de átomos com lógica visual local.
- `organisms/` — Seções complexas e independentes de página.
- `pages/` — Telas finais que conectam organismos ao ViewModel.

## Status atual (2026-05-12)

Dormente — `packages/design_system/` foi removido em D1.C delete (commit `33626f0`, 2026-05-01). Volta em Phase 6+ junto com UI Flutter.

## Superseded by

Nenhum.
