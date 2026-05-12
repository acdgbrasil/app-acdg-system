# ADR-016: UseCases como Camada de Orquestração Mandatória

**Data:** 2026-03-13
**Status:** Aceito

## Contexto

ViewModels estavam começando a acumular lógica de orquestração de dados e dependência direta de múltiplos Repositories.

## Decisão

Toda ação de negócio deve ser encapsulada em um `UseCase` que estende `BaseUseCase`. O ViewModel deve depender de `UseCases` e nunca de `Repositories`.

## Consequências

- Separação clara entre Lógica de UI (ViewModel) e Lógica de Negócio (UseCase).
- UseCases tornam-se testáveis em isolamento total de widgets.
- Facilidade de reutilização de orquestração entre diferentes ViewModels.

## Superseded by

Nenhum.
