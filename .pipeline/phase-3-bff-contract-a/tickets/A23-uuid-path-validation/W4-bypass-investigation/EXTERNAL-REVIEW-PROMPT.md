# External Review Prompt — Sealed-Class Downcast Anti-Pattern Fix

> **Para o revisor:** este prompt foi gerado por outra IA (Claude Opus 4.7)
> trabalhando num monorepo Dart/Flutter. Ela quer um *adversarial review*
> da proposta — NÃO valide, ATAQUE. Procure pontos cegos, anti-patterns
> melhores escondidos, alternativas que ela não considerou, riscos não
> mitigados. A IA é solicitada a explicitamente listar suas dúvidas.

---

## Sua tarefa

Você é um arquiteto sênior de software com domínio profundo de:
- Dart 3 (sealed classes, pattern matching, definite assignment)
- Sealed types em outras linguagens (Rust enum, Swift enum, Kotlin sealed,
  Haskell ADTs, OCaml variants)
- Custom lint authoring (Dart `analyzer` package, AST visitors)
- CI/CD defense-in-depth strategies
- Monorepo governance e anti-pattern remediation em escala

Uma equipe identificou um anti-pattern disseminado num codebase Dart e
propôs um plano de fix. Sua missão é **submeter o plano a um adversarial
review**: identificar fraquezas, alternativas superiores, riscos não
mitigados, e pontos cegos. **Não valide o que está bom — gaste o tempo
no que está ruim ou pode ser melhor.**

---

## Contexto do codebase

- **Monorepo Dart/Flutter** ACDG (healthcare/social-care).
- **BFF Web:** package Dart server-side com Shelf (NÃO é Flutter).
  Faz proxy entre frontend Flutter e backend Vapor/Swift.
- **Flutter packages:** apps mobile/desktop/web.
- **Sealed class central** `Result<T>` (em `package:core_contracts`):
  ```dart
  sealed class Result<T> {}
  final class Success<T> extends Result<T> {
    const Success(this.value);
    final T value;
  }
  final class Failure<T> extends Result<T> {
    const Failure(this.error);
    final Object error;
  }
  ```
- **Helper retorna `Result<String>`** após validar UUID v4 de path
  parameter:
  ```dart
  Result<String> validateUuidPathParam(String raw, {required String fieldName}) {
    final normalized = raw.trim().toLowerCase();
    if (_uuidV4Re.hasMatch(normalized)) return Success(normalized);
    return Failure(UuidPathParamError(fieldName: fieldName));
  }
  ```

## O anti-pattern (35 arquivos afetados)

Pattern atual em produção, replicado mecanicamente em 17 BFF Web intents +
1 handler + 11 Flutter use cases + 1 ViewModel + 1 mapper + 4 testes:

```dart
static Result<XIntent> parseFromBody(
  String rawPatientId,
  Map<String, dynamic> body,
) {
  final pathResult = validateUuidPathParam(rawPatientId, fieldName: 'patientId');
  if (pathResult case Failure(:final error)) return Failure(error);
  final patientId = (pathResult as Success<String>).value;  // ← anti-pattern

  // ... resto do parsing usa `patientId`
}
```

Problemas identificados:
1. Cast `as Success<String>` é redundante (a checagem `if-case Failure` já
   discriminou), mas o compilador não promove o tipo automaticamente.
2. Em runtime, o cast faz a mesma checagem de novo.
3. Se um terceiro variant for adicionado a `Result<T>`, o cast explode em
   produção em vez do compilador parar (perde a segurança da sealed class).
4. Bypassa a doutrina "switch exhaustive sobre sealed types" do handbook.

## Forma proposta como correta

```dart
static Result<XIntent> parseFromBody(
  String rawPatientId,
  Map<String, dynamic> body,
) {
  final String patientId;
  switch (validateUuidPathParam(rawPatientId, fieldName: 'patientId')) {
    case Success(:final value):
      patientId = value;
    case Failure(:final error):
      return Failure(error);
  }

  // ... resto do parsing usa `patientId`
}
```

Justificativas:
- `final String patientId;` declara sem inicializar.
- Switch exhaustive (sealed) força definite-assignment ou early-return.
- Compilador prova que `patientId` está atribuído após o switch.
- Zero cast, zero check duplicado.

## Plano de defesa em depth (6 camadas)

### Camada 1 — Handbook
Adicionar §P5 a `PATTERN_MATCHING_POLICY.md`: "No sealed class downcast"
- DO: switch exhaustive
- DON'T: `as Success<T>` / `as Failure<T>` / `as Ok<T>` / `as Error<T>`
- Exemplos para cada Template (path-only, path-only com 2 ids, path+body)

### Camada 2 — Skill (instruções de agente AI)
Adicionar regra 24 em `.claude/skills/flutter-expert/SKILL.md`:
"Never `as Success<T>` / `as Failure<T>` casts on Result<T> — use switch
exhaustive. Compiler must prove the discrimination."

### Camada 3 — Script CI grep (defesa imediata)
```bash
#!/usr/bin/env bash
set -euo pipefail
matches=$(grep -rn "as Success<\|as Failure<\|as Ok<\|as Error<" \
    --include="*.dart" \
    bff/ packages/ apps/ \
    | grep -v "^\s*//" \
    || true)
if [ -n "$matches" ]; then
  echo "ERROR: forbidden sealed-class downcast detected:"
  echo "$matches"
  exit 1
fi
```
Wire em `make ci` ou pre-commit hook. Remove quando custom lint chegar.

### Camada 4 — Custom Lint (longo prazo)
Estender ticket pendente de `acdg_lints` package com 6ª rule:
**`no_sealed_class_downcast`** (severity: error)
- Matcher AST: `AsExpression` cujo target type é subclasse de tipo declarado
  como `sealed`. Início conservador: hardcode `Success<*>`, `Failure<*>`,
  `Ok<*>`, `Error<*>` da `package:core_contracts`.
- Scope: monorepo inteiro

### Camada 5 — STATE.md do ticket
Reescrever Templates A/B/C/D/E para mostrar a forma correta (sem cast).

### Camada 6 — Refactor de produção (escopo)
Cenário escolhido: **Apenas BFF Web (28 arquivos)** — encerra o ticket
atual limpo. Abre ticket separado A24 para os outros 18 arquivos Flutter
packages.

## O que avaliar (adversarialmente)

### Dimensão 1 — Qualidade do pattern proposto

**Atacar:**
- A forma com `final String patientId;` + switch exhaustive é mesmo
  idiomática Dart 3? Considere alternativas:
  - **Extension method** `Result<T>.unwrapOr<R>(R Function(Object) onError)` —
    estilo Rust/Result. Trade-offs?
  - **`flatMap` / `andThen` / `bind`** monadic — composability ganha algo
    real ou só adiciona ceremony?
  - **Helper top-level** `T orReturn<T>(Result<T>, ...)` — possível em
    Dart? Faz sentido?
  - **Nested closures** `result.fold(onSuccess: (v) {...}, onFailure: (e) {...})`
    — funcional puro mas penalty de control flow?
  - **Dart 3 record return** `(String?, Result<XIntent>?) preflight()` —
    overengineering ou clareza?
- O switch exhaustive imperativo realmente é o melhor? Compare com:
  ```dart
  return switch (validateUuidPathParam(...)) {
    Success(:final value) => _continueParsing(value, body),
    Failure(:final error) => Failure(error),
  };
  ```
  Onde `_continueParsing` é uma função privada com o resto. Isso é melhor
  ou pior?

**Especificamente questione:**
- Definite assignment com `final String patientId;` — cobre todos os edge
  cases (early return, throw, rethrow)?
- O pattern proposto força um early-return que pode ficar feio em fluxos
  com 2+ validações em sequência (ex: 2 path params)?
- Há armadilha latente quando o `case Failure(:final error)` precisa
  retornar com tipo diferente (`Result<XIntent>` vs `Result<String>`)?

### Dimensão 2 — Completude do plano de defesa

**Camadas que possivelmente faltam:**
- **Pre-commit hook** (Husky/lefthook) — separado de CI? Ou redundante?
- **CodeQL / Semgrep** — overkill para Dart ou faz sentido?
- **Type-driven prevention** — o `Result<T>` poderia ser desenhado de
  forma que o cast nem fosse possível? (ex: variants como private
  constructors + factory)
- **Renaming defensivo** — renomear `Result.value` para algo que
  só seja acessível via pattern match (ex: implementação que oculta o
  field até o switch)?
- **Code review checklist explícito** — não documentado como camada?
- **Documentação do "porquê" para futuros mantenedores** — o BYPASS-REPORT
  conta a história, mas e daqui 6 meses quando ninguém lembrar?
- **Métrica/dashboard de regressão** — quem detecta se o anti-pattern
  voltar daqui a 1 ano?

### Dimensão 3 — Riscos não mitigados

**Atacar especificamente:**
- O grep da Camada 3 falha em comentários multi-line. Falsos positivos?
  Falsos negativos?
- Performance do grep em monorepo crescente — viável manter long-term?
- Custom lint da Camada 4 pode ter falsos positivos em cast legítimo
  (ex: testes que fazem assertion de tipo). Como handle?
- A regra "force switch exhaustive sempre" pode ter exceções legítimas?
  (ex: API boundary com tipo unknown vindo de fora)
- Cenário onde o anti-pattern reaparece através de uma nova Result-like
  sealed class que ninguém cadastrou no lint (ex: alguém define
  `sealed class Either<L, R>` num package novo)?

### Dimensão 4 — Custo/benefício do refactor

- 28 arquivos no Cenário 1 — é o escopo certo ou está sub/super dimensionado?
- Refactor preserva behavior — mas e migração de testes que pinam o cast
  literal? Há cenário onde teste falha mesmo com behavior idêntico?
- Existe risco de o refactor introduzir BUG sutil em algum dos 28 arquivos?
  Que precaução adicionar?

### Dimensão 5 — Causa raiz e prevenção sistêmica

**Reflexões mais profundas que a equipe pode ter perdido:**
- O canon nasceu errado no W1 do ticket A23 — por quê? Falha de
  pair-review? Falha de skill? Falha de "test the canon before replicating"?
- Há heurística generalizável: "ao introduzir um novo template/canon,
  exigir tipo X de checagem antes de propagar"?
- O monorepo tem outros sealed types em risco do mesmo bypass? (Procurar
  em código do projeto qualquer outro `sealed class` que possa virar
  vetor.)
- A separação "skill flutter-expert" vs "BFF Web sem skill" é estrutural
  — como resolver? Skill cross-cutting "Sealed Discipline"?

### Dimensão 6 — Comparação com outras linguagens

**Pergunta de calibração:**
- Em Rust, o pattern equivalente (`if let Err(...)` + cast) é proibido
  pelo compiler — o cast não compila. Como é em Swift? Kotlin? Por que
  Dart 3 permite o cast? É um sinal de imaturidade do pattern matching
  ou intencional?
- Outras comunidades (Rust ecosystem, ts-pattern, fp-ts) têm convenções
  documentadas que o ACDG poderia adotar?

---

## Formato de resposta esperado

Por favor estruture sua resposta como:

```
## 1. Resumo executivo
[3-5 sentenças com seu veredicto: a proposta é boa, é boa-com-correções,
ou tem falha estrutural? E quais.]

## 2. Achados críticos
[Liste, em ordem de severidade, os problemas que você identificou com a
proposta. Para cada um:
 - O que: descrição precisa
 - Por que importa: impacto se não resolver
 - Sugestão concreta: o que fazer]

## 3. Alternativas superiores ao pattern proposto
[Se houver alternativas Dart 3 que você considera melhores que o
"final String patientId; switch (...)" — apresente código + trade-off]

## 4. Camadas de defesa que faltam
[Camadas adicionais ou substituições às propostas. Justifique cada uma.]

## 5. Riscos não mitigados
[Riscos que sobrevivem mesmo após o plano todo ser executado.
Categorize por probabilidade × impacto.]

## 6. Perguntas que a equipe não respondeu
[Liste perguntas críticas que o BYPASS-REPORT não enfrenta. A equipe
deve responder antes de seguir.]

## 7. Recomendação final
[Concreto: aprovar com ressalvas X, Y; aprovar tal qual; reprovar e
reescrever; etc.]
```

---

## Anti-bias guidelines (importante)

- **Não seja diplomático.** Se algo está mal pensado, diga claramente.
- **Não invente concordância.** Se a proposta resolve o problema bem, diga
  poucas palavras nessas seções e gaste páginas no que está ruim.
- **Não generalize platitudes** ("é importante ter testes", "considerar
  performance"). Toda crítica deve ser específica e acionável.
- **Não sugira coisas não-Dart** sem mapear como traduziriam para Dart 3
  realista. Não vale "use Rust".
- **Indicador de qualidade da sua resposta:** quantos bugs/riscos
  específicos você apontou que a equipe não tinha catalogado.

---

## Material de referência (para sua avaliação)

A equipe se baseou em:
- Dart 3 sealed classes + pattern matching specs
- "Pattern Matching Policy" interno (não compartilhado aqui — você está
  julgando a proposta sem acesso ao policy original; trate isso como
  bônus: identifique se a proposta seria coerente com qualquer policy
  razoável)
- Ticket pendente de custom lint (`acdg_lints`) com 4 rules planejadas
  diferentes (catch_without_stack, intent_parse_must_accept_obs,
  parse_error_must_be_private, prefer_logical_pattern_grouping). A equipe
  propôs adicionar uma 5ª rule para o caso atual.

---

**Pergunta final que você deve responder explicitamente:**

> Se você tivesse 4 horas para fazer ESSA equipe parar de cometer esse
> tipo de anti-pattern para sempre, e só pudesse executar 3 dessas 6
> camadas, quais escolheria e por quê?

Sua resposta a essa pergunta indica onde está a alavanca real.
