# ADR-005: Isar para Offline Storage — **SUPERSEDED**

**Data:** 2026-03-08
**Status:** ⚠️ **Superseded por [ADR-021](ADR-021-drift-over-isar.md)** em 2026-04-30
**Decisão atual:** usar **Drift** (não Isar). Ver [ADR-021](ADR-021-drift-over-isar.md).

## Contexto histórico (preservado)

Necessidade de offline storage robusto para o ecossistema Flutter ACDG. A escolha original recaiu sobre **Isar** baseada em:

- API NoSQL idiomática para Dart (schema por classe anotada).
- Performance superior em benchmarks de inserção/leitura.
- Suporte a queries reativas via streams.

## Decisão original (revogada)

Adotar Isar para todo armazenamento local persistente nos packages Flutter.

## Por que foi revogada

Em 2026-04-30, durante o re-baseline da Onda 4 (`bff/social_care_desktop/`), três fatos novos invalidaram a premissa:

1. **Manutenção do Isar colapsou** — autor original (Simon Leier) abandonou o package; forks (`isar_community`, `isar_plus`) instáveis com regressões em produção.
2. **Incompatibilidade com Swift Package Manager (SPM)** — Flutter migrou para SPM como padrão; Isar depende de binários Rust pré-compilados que falham sob hooks de build modernos (Issue #1750 aberta, sem resolução).
3. **Drift tem Isolates de primeira classe** — necessário para `SyncEngine` offline-first (A18-v2); Isar tem APIs de isolate marcadas como experimentais.

Ver [ADR-021](ADR-021-drift-over-isar.md) para a análise completa e a decisão substituta.

## Status

**Não usar Isar em código novo.** Se um agente sugerir Isar com base nesta ADR-005, redirecionar para [ADR-021](ADR-021-drift-over-isar.md).

## Superseded by

[ADR-021](ADR-021-drift-over-isar.md) — pivot Drift sobre Isar (2026-04-30).
