# ADR-019: Parsers em Fronteira Adapter — P2 `if-case` como Default, P2b `try/catch` como Edge Case

**Data:** 2026-04-17
**Status:** Aceito
**Relacionado:** [PATTERN_MATCHING_POLICY.md §P2 / §P2b](../PATTERN_MATCHING_POLICY.md), skill [flutter-expert](../../../../skills_base/flutter-expert/SKILL.md) §194 (`throw` só em adapter), [ADR-014](ADR-014-result-pattern.md)

## Contexto

O monorepo adotou `if-case` (P2) como forma canônica de parsing em fronteiras adapter. Em A07–A09 (BFF Web handlers de Auth + Registry Patient + Registry Family), P2 funcionou bem porque os DTOs tinham 3–7 campos obrigatórios.

Em A10 (Assessment 7 fichas), cada DTO passou a ter 10–15 campos obrigatórios (`UpdateHousingConditionRequest` = 15). Aplicar P2 em todos os 7 intents exigiria ~80 checagens manuais duplicando o schema já gerado por `json_serializable`. Risco alto de drift quando DTOs evoluírem e boilerplate impossível de manter sync com o código gerado.

A primeira implementação usou `try { fromJson(body) } catch (_) { Failure(...) }` — resolveu o drift mas introduziu dois anti-patterns:

1. `catch (_)` descarta a cause — debug impossível em prod.
2. Nenhum logging da exceção capturada.

Reprovado em review ad-hoc. Hardening aplicado convertendo para `catch (e, st)` + `obs?.logError('<ficha>.parse_failed', cause: e, stack: st)`.

## Decisão

**1. P2 `if-case` continua default** para todos os parsers em adapter layer com &lt;10 campos obrigatórios e sem PII-sensível.

**2. P2b (`try/catch` sobre `fromJson` gerado) é explicitamente aprovado** quando **todas as 3 condições do gatilho** convergem (ver [PATTERN_MATCHING_POLICY.md §P2b](../PATTERN_MATCHING_POLICY.md)):

- Fronteira adapter (Intent / Handler / Mapper).
- DTO tem `fromJson` gerado (`json_serializable` / `freezed` / `drift`).
- ≥10 campos obrigatórios **OU** mensagem deve ser PII-safe estrutural.

**3. Forma canônica P2b é obrigatória** (code review faz hard-reject em desvio):

- `catch (e, st)` — nunca `catch (_)` nem `catch (e)` sem stack.
- `obs?.logError` com cause + stack (para AcdgLogger + Sentry).
- `_XxxParseError` privada `final class with Equatable implements Exception`, `toString()` retornando string fixa.
- `ObservabilityContext? obs` opcional no parser (compat com testes).

**4. Checklist e fluxo de decisão** ficam em [PATTERN_MATCHING_POLICY.md §P2b](../PATTERN_MATCHING_POLICY.md) — referência obrigatória para agentes `test-writer` e implementer **antes** de escolher entre P2 e P2b. Adicionado ao checklist de code review.

## Consequências

- Parsers de DTOs "gordos" (Assessment, formulários complexos) escalam sem drift contra o schema gerado.
- Cause + stack sempre disponível para debug em prod (via AcdgLogger + Sentry).
- Mensagem de erro uniforme PII-safe — impede shape-leak para atacantes probing a API.
- Custo: ~15 linhas a mais por Intent vs `catch (_)`. Aceito.
- Agentes precisam consultar o fluxo de decisão §P2b antes de escrever qualquer parser — matéria de code review automático.

## Referência de implementação

- **Canon default (P2):** `bff/social_care_web/lib/src/intents/register_patient_intent.dart` (A08, 3 campos obrigatórios). Path atual: `apps/social_care_bff/web/lib/src/intents/register_patient_intent.dart` (ADR-022).
- **Edge case aprovado (P2b):** `bff/social_care_web/lib/src/intents/update_housing_condition_intent.dart` + 6 intents irmãos (A10, 10–15 campos cada). Path atual: `apps/social_care_bff/web/lib/src/intents/update_housing_condition_intent.dart`.

## Superseded by

Nenhum.
