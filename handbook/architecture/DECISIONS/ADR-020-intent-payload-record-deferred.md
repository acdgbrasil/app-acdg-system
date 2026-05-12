# ADR-020: `IntentPayload` Record Carrier — Consideração Adiada

**Data:** 2026-04-17
**Status:** Adiado (consideração registrada; reavaliar sob gatilho)
**Relacionado:** [ADR-019](ADR-019-parsers-p2-p2b.md), [PATTERN_MATCHING_POLICY.md §P2b § Carrier da decisão](../PATTERN_MATCHING_POLICY.md)

## Contexto

Durante a consolidação do canon pós-A12, surgiu a proposta de uniformizar a assinatura de todos os `Intent.parseFromBody` para um único tipo via Record Dart 3:

```dart
typedef IntentPayload = ({
  String id,
  Map<String, dynamic> body,
  ObservabilityContext? obs,
});

// P2 e P2b compartilham assinatura idêntica:
static Result<XxxIntent> parseFromBody(IntentPayload payload) {
  final (:id, :body, obs: _) = payload;  // P2: descarta obs via wildcard
  // ou
  final (:id, :body, :obs) = payload;    // P2b: extrai obs para logError
}
```

## Motivação apresentada

1. **Compatibilidade com P3 (tear-offs):** assinaturas uniformes permitiriam passar parsers como `Result<T> Function(IntentPayload)` first-class em maps, routers dinâmicos, frameworks de fuzz testing.
2. **`obs: _` como declaração ativa de intenção:** o wildcard explicita que o autor do Intent P2 **sabe** que observabilidade existe e **decidiu** descartá-la. Mais rico semanticamente que "parâmetro ausente".
3. **Coerência idiomática:** amarra a regra de negócio P2b com a regra sintática P1/P3 (pattern matching + tear-offs) já documentada.

## Análise de trade-offs

**Prós (confirmados):**

- Tear-off habilitado de parsers como valores de primeira classe.
- Retrofit de P2 → P2b toca apenas o Intent (assinatura imutável).
- `obs: _` carrega intenção no código.

**Contras (confirmados):**

- **Nenhum use-case concreto hoje:** os 6 handlers (A07–A12) chamam `IntentEspecifico.parseFromBody(...)` nominalmente; não há `Map<String, ParseFunc>`, router dinâmico, nem framework batch. Tear-off é benefício teórico para este monorepo nos próximos 6 meses.
- **Retrofit custoso:** 29 Intents + 6 handlers + ~35 test files tocados. Estimativa 6–8h de trabalho meticuloso com ajuste de call-sites em testes.
- **Perda de informação na assinatura:** a heterogeneidade atual (`P2 sem obs, P2b com obs opcional`) **carrega informação útil** — lendo a assinatura, o dev sabe imediatamente qual estratégia o Intent usa. Com Record, essa informação é ocultada dentro do corpo do método.
- **Overhead cognitivo:** Record destructuring + wildcard pattern é mais avançado que parâmetro opcional nomeado. Curva de adoção real para novos devs.
- **Convivência de estilos:** se adotado apenas em A13+, 75% do monorepo fica em estilo velho vs 25% em estilo novo — janela quebrada, ambiguidade em code review.

## Decisão

**Adiado.** Manter canon atual com `{ObservabilityContext? obs}` opcional (ver [PATTERN_MATCHING_POLICY.md §P2b § Carrier da decisão](../PATTERN_MATCHING_POLICY.md)).

Razões:

1. **YAGNI** — o benefício primário (tear-offs) não tem uso concreto previsto.
2. **Coerência imperfeita > perfeição fragmentada** — adotar em A13+ sem retrofit criaria convivência de estilos, pior que o status quo.
3. **Custo de oportunidade** — 6–8h de retrofit no meio de Onda 3 (A13–A15 pendentes) não se justifica por purismo idiomático.

## Gatilho de reavaliação

Reabrir esta decisão quando **qualquer** dos seguintes emergir:

- Router dinâmico mapeando URL → parser (ex: `Map<String, ParseFunc>`).
- Framework de fuzz testing exercitando parsers em batch.
- Gateway reflexivo que descobre Intents por reflection/code-gen.
- Necessidade de passar parsers como deps injetáveis em testes de handler.
- Quinto Intent que precisa de P2b (hoje 8 Intents P2b entre A10 e A12; se crescer, custo unitário de retrofit cai).

## Se retrofit for aprovado no futuro

Ordem recomendada:

1. Criar `typedef IntentPayload` em `kernel/contracts/`.
2. Migrar Intents A07 (5) — suite canônica 87 tests valida.
3. Progredir A08 → A12 em sequência (cada wave valida com 100+ tests).
4. Atualizar 6 handlers + testes de call-site.
5. ADR-020 atualizado para status "Aceito".

## Referência

- Proposta completa: conversa-sessão 2026-04-17 (pós-A12 close-out).
- Análise de YAGNI: [PATTERN_MATCHING_POLICY.md §P2b § Carrier da decisão](../PATTERN_MATCHING_POLICY.md) + callout embedded.

## Superseded by

Nenhum.
