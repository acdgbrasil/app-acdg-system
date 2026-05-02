# Plano de Implementação — Refatoração Core

Este plano descreve a ordem de execução para as mudanças no package `core`.

## Fase 1: Infraestrutura de Igualdade
1.  **Criar `lib/src/utils/equatable/`**:
    -   `equatable_utils.dart`: Portar as funções de Jenkins Hash e `objectsEquals`.
    -   `equatable_config.dart`: Adicionar a classe de configuração global de `stringify`.
    -   `equatable.dart`: Implementar a `abstract mixin class Equatable`.
    -   `equatable_mixin.dart`: Criar o alias depreciado.

## Fase 2: Refatoração de Base
1.  **Atualizar `Result` (`lib/src/base/result.dart`)**:
    -   Remover overrides manuais de `==` e `hashCode` nas classes `Success` e `Failure`.
    -   Fazer `Success` e `Failure` usarem `Equatable`.
2.  **Ajustar `pubspec.yaml`**:
    -   Adicionar dependências de `meta` e `collection`.

## Fase 3: Validação
1.  **Testes Unitários**:
    -   Criar `test/utils/equatable_test.dart` para validar casos complexos (Nested lists, Maps, Nulls).
    -   Atualizar `test/base/result_test.dart` para garantir que a igualdade continua funcionando via Equatable.

## Fase 4: Exportação
1.  **Atualizar `lib/core.dart`**:
    -   Exportar `Equatable` e utilidades relevantes para uso em outros packages.
