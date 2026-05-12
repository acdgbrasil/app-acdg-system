# ADR-003: MVVM + Logic Layer como Padrão Arquitetural

**Data:** 2026-03 (reconstituído a partir de `frontend/CLAUDE.md`)
**Status:** Aceito (reconstituído)
**Relacionado:** [ADR-013](ADR-013-mvvm-usecase-mandatory.md) (refinamento), [ADR-015](ADR-015-command-pattern.md), [ADR-016](ADR-016-usecase-orchestration.md)

## Contexto

Decidir o padrão arquitetural cliente alinhado às **Flutter Architecture Guidelines** oficiais. Necessidade de testabilidade total, separação clara entre lógica de UI e lógica de negócio, e fluxo de dados unidirecional.

## Decisão

Adotar **MVVM + Logic Layer** com fluxo unidirecional:

```text
Dados (downstream):
  Service → Repository → UseCase → ViewModel → View (ValueNotifier)

Ações do usuário (upstream):
  View → Command → ViewModel → UseCase → Repository → Service → BFF → API
```

Camadas:

| Camada | Responsabilidade |
|---|---|
| **View** | Exibe dados, captura eventos. Não decide nada. |
| **ViewModel** | Estado atômico (`ValueNotifier` + `ChangeNotifier`). Lógica de **UI** apenas. Sem lógica de negócio. |
| **UseCase** | Orquestra Repositories. Obrigatório em todas as features ([ADR-013](ADR-013-mvvm-usecase-mandatory.md), [ADR-016](ADR-016-usecase-orchestration.md)). Command pattern ([ADR-015](ADR-015-command-pattern.md)). |
| **Repository** | Fonte de verdade. Cache, retry, error handling. Classe abstrata para testabilidade. |
| **Service** | Wrapper puro de chamadas externas. Sem lógica. |

## Consequências

- ViewModels testáveis sem widget tree.
- UseCases reutilizáveis entre múltiplas ViewModels.
- Substituição de Service / Repository por Fake em testes é trivial.
- Fluxo unidirecional impede que View "puxe" dados ad-hoc.

## Status atual (2026-05-12)

- Phase 5 (CLI) usa arquitetura adaptada (sem ViewModel — terminal não tem widget tree). Mantém camadas Service / Repository / UseCase.
- UI Flutter (Phase 6+) usará MVVM completo.

## Superseded by

Nenhum (refinado por ADR-013 / ADR-015 / ADR-016).
