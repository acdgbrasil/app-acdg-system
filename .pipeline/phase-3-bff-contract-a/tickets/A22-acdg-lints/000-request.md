# A22 — Package `acdg_lints` (custom_lint rules)

## Onda: 5 (pós-A21) | Profile: tooling | Depende de: A19 (analyze verde final)

## Motivação
A política `PATTERN_MATCHING_POLICY.md §P2b` e o ADR-019 definem regras que **não** podem ser auto-enforçadas pelo `dart analyze` built-in:
- `catch (_)` em adapter layer (Intent.parseFromBody, Handler, Mapper) é reprovação automática — hoje só code review humano pega.
- `parseFromBody` em Intent sem `{ObservabilityContext? obs}` opcional.
- `_XxxParseError` exposto publicamente (tipo de erro de parser deve ser privado).
- Agrupamento DRY em switch (múltiplos cases com mesmo resultado que deveriam virar `||`).

Custom lints via package `custom_lint` (Celest) resolvem isso escrevendo rules em Dart puro que rodam no analyzer e **falham o CI**.

## Escopo

### Criar package `packages/acdg_lints/` (ou tooling separado)
```
packages/acdg_lints/
  lib/
    src/
      rules/
        catch_without_stack.dart
        intent_parse_must_accept_obs.dart
        parse_error_must_be_private.dart
        prefer_logical_pattern_grouping.dart
      acdg_lints.dart
  pubspec.yaml
  analysis_options.yaml
```

### Rules mínimas (v1)

1. **`catch_without_stack_in_adapter`** (severity: error)
   - Matcher: `catch (_)` ou `catch (e)` sem `, st` parameter
   - Scope: arquivos dentro de `lib/src/intents/`, `lib/src/handlers/`, `lib/src/mappers/`
   - Message: "catch must capture stack trace (catch (e, st)) + call obs?.logError. See ADR-019."

2. **`intent_parse_must_accept_obs`** (severity: warning)
   - Matcher: static method `parseFromBody`/`parseFromQuery`/`parseFromParams` em classe cujo nome termina com `Intent` e que NÃO tem parâmetro `{ObservabilityContext? obs}` no final
   - Scope: arquivos `**/intents/**_intent.dart`
   - Message: "Intent parser must accept optional `{ObservabilityContext? obs}` for debug telemetry in adapter-layer parse failures."

3. **`parse_error_must_be_private`** (severity: warning)
   - Matcher: classe cujo nome termina com `ParseError` e NÃO começa com `_`
   - Message: "Parser error types are implementation detail — name them `_XxxParseError`."

### Rules avançadas (v2 — se virar padrão comum)

4. **`prefer_logical_pattern_grouping`** (severity: info)
   - Matcher: switch expression com 2+ arms sequenciais com idêntica RHS
   - Message: "Cases with identical result should be grouped with `||` (P1 canon)."

5. **`_xxx_parse_error_toString_must_be_fixed`** (severity: warning)
   - Matcher: classe `_XxxParseError` cujo `toString()` retorna template string (`'...$x...'`) ou concatena variável
   - Message: "Parse error toString() must return a fixed structural string — PII-leak prevention."

## Setup dependency

```yaml
# dev_dependencies em cada package consumidor:
dev_dependencies:
  custom_lint: ^0.6.0
  acdg_lints:
    path: ../acdg_lints
```

```yaml
# analysis_options.yaml
analyzer:
  plugins:
    - custom_lint

custom_lint:
  rules:
    - catch_without_stack_in_adapter: error
    - intent_parse_must_accept_obs: warning
    - parse_error_must_be_private: warning
```

## Critérios

- [ ] Package `acdg_lints` criado e publicado internamente (path dependency)
- [ ] v1 com 3 rules funcionando
- [ ] Rules rodam via `dart run custom_lint` no CI
- [ ] Policy `PATTERN_MATCHING_POLICY.md §P2b` linkada às rules
- [ ] Teste unitário de cada rule (package `custom_lint` provê test harness)
- [ ] Rollout gradual: começa como warning, após 2 semanas vira error

## Referências
- `custom_lint` package: https://pub.dev/packages/custom_lint
- Dart Analyzer API: https://pub.dev/packages/analyzer
- Exemplos: `riverpod_lint`, `freezed_lint`, `mocktail_lint`

## Status
pending — scheduled for phase-3-bff-contract-a post-A21 cleanup OR early phase-4 tooling investment

## Esforço estimado
- Setup + v1 (3 rules): 1-2 dias
- Testes: 0.5 dia
- Rollout + documentação: 0.5 dia
- **Total: ~3 dias**
