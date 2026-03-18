# Best Practices — Core Standards

Diretrizes extraídas da evolução do projeto para garantir código limpo e previsível.

## 1. Igualdade e Comparação
- **Usar `Equatable`:** Toda classe de dados ou estado deve estender ou usar o mixin `Equatable`.
- **Props Explícitas:** Sempre incluir todos os campos mutáveis ou significativos no getter `props`.

## 2. Tipos Result e Pattern Matching
- **Nunca retornar null para erros:** Usar `Failure(ErrorObject)`.
- **Exaustividade:** Ao consumir um `Result`, usar `switch` expressions para garantir que `Success` e `Failure` sejam tratados.

## 3. Mixin Classes (Dart 3+)
- **Flexibilidade:** Preferir `abstract mixin class` para utilitários de base. Isso permite que o desenvolvedor escolha entre `extends` (herança única) ou `with` (múltiplos mixins).

## 4. Boilerplate vs. Clareza
- **Remover overrides manuais:** Se uma classe usa `Equatable`, não deve haver override manual de `==` ou `hashCode`.
- **ToString Útil:** O `Equatable` já provê um `toString()` baseado em props. Use `stringify: true` para facilitar o debug.
