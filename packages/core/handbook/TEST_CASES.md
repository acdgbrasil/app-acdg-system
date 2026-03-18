# Test Cases — Equatable & Utils

Lista de cenários que serão implementados nos arquivos de teste.

## 1. Engine de Comparação (`objectsEquals`)
| Caso | Entrada A | Entrada B | Resultado Esperado |
| :--- | :--- | :--- | :--- |
| Identidade | `obj1` | `obj1` | `true` |
| Tipos Diferentes | `'1'` | `1` | `false` |
| Listas Iguais | `[1, 2]` | `[1, 2]` | `true` |
| Sets (Ordem Dif) | `{1, 2}` | `{2, 1}` | `true` |
| Maps (Ordem Dif) | `{'a': 1, 'b': 2}` | `{'b': 2, 'a': 1}` | `true` |
| Nulos | `null` | `null` | `true` |

## 2. Hash Code (`mapPropsToHashCode`)
- `hash([1, 2])` deve ser igual a `hash([1, 2])`.
- `hash({'a': 1})` deve ser igual a `hash({'a': 1})` independente da ordem das chaves.
- `hash(Success(42))` deve ser consistente.

## 3. Equatable (Inheritance vs Mixin)
- **Classe A extends Equatable:** Comparar duas instâncias com mesmas props.
- **Classe B with Equatable:** Garantir que o mixin sobrescreva `==` e `hashCode` corretamente.
- **Nested Equatable:** `props: [OtherEquatable()]` deve comparar por valor.
