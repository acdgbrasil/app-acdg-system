# A20 — Contract A Doc REPORT

## Status: GREEN
Closed: 2026-05-01

## Mudanças

### `handbook/architecture/CONTRACT_A_PUBLIC_API.md`
- Header status mudou de "Proposta (draft)" para "Implementado (BFF-side) — pendente Phase 4 Flutter migration".
- Adicionada §14 "Estado final (2026-05-01)" com:
  - 14.1 — resumo dos 22 tickets fechados (Onda 1-5 + Onda 3.5 cross-cutting A23).
  - 14.2 — 6 trade-offs vivenciados (sub-contracts 9→11, cache 5 vs 7, P2/P2b estreias, Drift permanece, REGRA #2 textbook, item descartado em A19).
  - 14.3 — próximos passos Phase 4 (T01-T19, piloto Housing, ativação `acdg_lints`).
  - 14.4 — referências cruzadas.

### `handbook/architecture/CONTRACT_A_SPEC.md`
- Header status: "spec-frozen" → "spec-implementado".
- Adicionada seção final "Estado pós-implementação (2026-05-01)":
  - Sub-contracts 9 → 11 (tabela completa com razão de Health e People).
  - Confirmação dos 6 endpoints removidos em A15.
  - B5 lookups batch implementado em A14.
  - Wave 4 Desktop rebuild — tabela camada × spec original × implementado.
  - Itens deferidos a Phase 4 (cleanup `packages/social_care/`).
  - Itens absorvidos por A19 (cleanup BFF-side: api_client deletado, health_handler refatorado).

### `handbook/architecture/README.md`
- Expandido de 3 docs listados para 12 (incluindo CONTRACT_A_PUBLIC_API e CONTRACT_A_SPEC com descrição).
- Mantida convenção sem acentos (alinhada ao estilo existente do README).

## Verificação dos critérios

- [x] CONTRACT_A_PUBLIC_API.md atualizado com estado final
- [x] CONTRACT_A_SPEC.md atualizado com estado final
- [x] Ambos linkados em README.md

## Próximo

A21 — cleanup BFF-side (parte Flutter já listada como deferida a Phase 4).
