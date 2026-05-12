# ADR-018: Separação Root / Main e Injeção por Camadas

**Data:** 2026-03-13
**Status:** Aceito
**Relacionado:** [ADR-009](ADR-009-provider-di.md)

## Contexto

O arquivo `main.dart` estava poluído com inicialização de infraestrutura, dificultando testes de integração e modularização.

## Decisão

1. `main.dart` apenas chama o `Root()`.
2. `root.dart` orquestra a injeção via `Provider` seguindo a ordem: `Data → Logic → UI`.
3. Repositories e UseCases são expostos na árvore de widgets para consumo via `context.read()`.

## Consequências

- Bootstrap do app limpo e profissional.
- Facilidade para trocar toda a camada de dados por `Fakes` nos testes.

## Status atual (2026-05-12)

Aplicado em desktop / BFF. Para Flutter UI (Phase 6+) será readotado.

## Superseded by

Nenhum.
