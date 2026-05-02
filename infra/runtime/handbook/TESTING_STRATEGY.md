# Testing Strategy — Validação de Igualdade

Para garantir a integridade do `core`, seguiremos uma abordagem de **TDD (Test-Driven Development)**. O objetivo é validar casos extremos (edge cases) antes mesmo de finalizar a implementação completa.

## Objetivos de Teste

1.  **Igualdade de Primitivos:** Garantir que tipos básicos (String, int, bool) funcionem via `objectsEquals`.
2.  **Igualdade de Coleções (Profunda):**
    -   Listas com a mesma ordem e conteúdo.
    -   Sets com ordem diferente mas mesmos elementos (devem ser iguais).
    -   Maps com chaves em ordens diferentes (devem ser iguais).
    -   Coleções aninhadas (`List<Map<String, List<int>>>`).
3.  **Consistência de Hash:**
    -   Objetos iguais DEVEM ter o mesmo `hashCode`.
    -   O hash deve ser determinístico entre execuções.
4.  **Integração com Equatable:**
    -   Classes que usam `extends Equatable`.
    -   Classes que usam `with Equatable` (mixin).
    -   Subclasses de `Result` (`Success`, `Failure`).
5.  **Performance & Segurança:**
    -   Evitar loops infinitos em referências circulares (se aplicável).
    -   Garantir que `stringify` funcione conforme configurado.

## Estrutura de Arquivos de Teste
- `test/utils/equatable_test.dart`: Testes exaustivos da engine.
- `test/base/result_test.dart`: Validação da refatoração do Result.
