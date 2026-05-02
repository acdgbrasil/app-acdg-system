# Core Architecture — Fundamentos do Ecossistema

O package `core` é a camada base do monorepo ACDG. Sua responsabilidade é fornecer abstrações agnósticas a domínio que garantam consistência em todos os demais packages (`auth`, `network`, etc).

## Princípios de Design

1.  **Zero Dependências Externas (Heavyweight):** O `core` deve evitar depender de pacotes de terceiros complexos. Optamos por implementar nossa própria lógica de `Equatable` para manter o binário leve e sob total controle.
2.  **Dart 3 Native:** Todo o código deve utilizar os recursos modernos do Dart (Sealed classes, Mixin classes, Pattern matching).
3.  **Imutabilidade por Padrão:** Todas as classes base devem incentivar ou forçar a imutabilidade (`@immutable`).
4.  **Falha Explícita:** Uso obrigatório do tipo `Result` para operações assíncronas ou propensas a erro, eliminando o uso de `throw` para controle de fluxo.

## Estrutura de Camadas

-   `src/base/`: Contratos fundamentais (`BaseUseCase`, `BaseViewModel`, `Result`).
-   `src/platform/`: Resolução de ambiente (Web vs Desktop vs Mobile).
-   `src/utils/`: Utilitários de baixo nível (Equality, Collections, Parsing).
