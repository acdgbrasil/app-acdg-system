# ADR-014: Result&lt;T&gt; End-to-End — Erros como Valores

**Data:** 2026-03 (reconstituído a partir de `frontend/CLAUDE.md` / `handbook/principles/`)
**Status:** Aceito (reconstituído)

## Contexto

`throw` / `try/catch` em código de domínio / aplicação cria três problemas:

1. **Exceptions são invisíveis no tipo** — função `getPatient(id)` pode dar throw em N exceções diferentes; o caller não sabe.
2. **Stack unwinding caro** — em runtime, é mais lento que early-return.
3. **Anti-padrão `catch (_)`** — engole tudo silenciosamente, debug em prod fica impossível.

## Decisão

**Result&lt;T&gt; end-to-end** em domínio e aplicação.

- `throw` **proibido** em domínio e aplicação.
- `throw` **permitido apenas em adapters** (Service, parsers, mappers) — convertido para `Result` antes de cruzar a fronteira.
- `catch (e, st)` obrigatório em adapter — nunca `catch (_)`. Stack vai para log estruturado.

### Forma canônica

```dart
sealed class Result<T> {
  const Result();
  factory Result.success(T value) = Success<T>;
  factory Result.failure(String code, [String? message]) = Failure<T>;
}

final class Success<T> extends Result<T> { final T value; ... }
final class Failure<T> extends Result<T> { final String code; ... }
```

### Combinadores aprovados (A23 V2 templates)

| Situação | Operador |
|---|---|
| Transformação 1:1 sem erro | `.map((v) => f(v))` |
| Validações dependentes | `.flatMap((a) => g(a))` |
| 2–3 validações independentes | `(r1, r2).combineWith((a, b) => ...)` |
| Side-effect só no Failure | `switch` imperativo com early-return |

### Proibido em `lib/`

- `as Success<T>` (downcast da sealed class).
- `catch (_)`.
- `valueOrNull!`.
- Inventar `guard()` / `unwrap()` que abafam erro.

### Permitido em `test/`

- `as Success<T>` como fail-fast assertion (com mensagem clara).

## Consequências

- Tipo da função carrega todos os erros possíveis — caller é obrigado a tratar.
- Sem stack unwinding — performance previsível.
- Erros são valores compostos com `map` / `flatMap` / `combineWith`.
- Custo: boilerplate inicial maior; agentes precisam treinar para não usar `try/catch` em domínio.

## Status atual (2026-05-12)

- Aplicado em `kernel/contracts/`, `apps/social_care_bff/`, `apps/cli/`.
- Validado por code review automático ([flutter-expert](../../../../skills_base/flutter-expert/SKILL.md)) — `throw` em domínio é rejeitado.
- Detalhes em [PATTERN_MATCHING_POLICY.md](../PATTERN_MATCHING_POLICY.md) e [ENCAPSULATION_POLICY.md](../ENCAPSULATION_POLICY.md).

## Relacionado

- [ADR-019](ADR-019-parsers-p2-p2b.md) — P2 `if-case` como default em parsers de adapter; P2b `try/catch` como edge case.

## Superseded by

Nenhum.
