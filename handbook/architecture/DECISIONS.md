# ADRs — Architecture Decision Records

> Registro formal de todas as decisoes arquiteturais do frontend.
> Cada decisao e imutavel apos aceita. Novas decisoes podem substituir anteriores referenciando o ADR original.

---

## ADR-001 ate ADR-014
*(Consulte o histórico para detalhes dos ADRs anteriores)*

---

## ADR-015: Uso Mandatório do Padrão Command para Ações de UI

**Data:** 2026-03-13
**Status:** Aceito

### Contexto
O gerenciamento manual de estados de "carregamento" (busy) e "erro" nos ViewModels gerava muito boilerplate e inconsistência visual entre telas.

### Decisão
Implementar e usar obrigatoriamente a classe `Command` (do package `core`) para qualquer operação assíncrona iniciada pela UI.

### Consequências
- ViewModels ficam mais limpos (menos flags booleanas).
- UI reage de forma consistente via `ListenableBuilder` aos estados do comando.
- Redução drástica de bugs de concorrência (Commands bloqueiam re-execução automática enquanto rodam).

---

## ADR-016: UseCases como Camada de Orquestração Mandatória

**Data:** 2026-03-13
**Status:** Aceito

### Contexto
ViewModels estavam começando a acumular lógica de orquestração de dados e dependência direta de múltiplos Repositories.

### Decisão
Toda ação de negócio deve ser encapsulada em um `UseCase` que estende `BaseUseCase`. O ViewModel deve depender de `UseCases` e nunca de `Repositories`.

### Consequências
- Separação clara entre Lógica de UI (ViewModel) e Lógica de Negócio (UseCase).
- UseCases tornam-se testáveis em isolamento total de widgets.
- Facilidade de reutilização de orquestração entre diferentes ViewModels.

---

## ADR-017: Organização de UI via Atomic Design

**Data:** 2026-03-13
**Status:** Aceito

### Contexto
Pastas de widgets estavam se tornando "sacos de arquivos" sem hierarquia clara de reuso.

### Decisão
Adotar rigorosamente o **Atomic Design**:
- `atoms/`: Componentes básicos, puros e agnósticos.
- `molecules/`: Composição de átomos com lógica visual local.
- `organisms/`: Seções complexas e independentes de página.
- `pages/`: Telas finais que conectam organismos ao ViewModel.

---

## ADR-018: Separação Root / Main e Injeção por Camadas

**Data:** 2026-03-13
**Status:** Aceito

### Contexto
O arquivo `main.dart` estava poluído com inicialização de infraestrutura, dificultando testes de integração e modularização.

### Decisão
1. `main.dart` apenas chama o `Root()`.
2. `root.dart` orquestra a injeção via `Provider` seguindo a ordem: `Data -> Logic -> UI`.
3. Repositories e UseCases são expostos na árvore de widgets para consumo via `context.read()`.

### Consequências
- Bootstrap do app limpo e profissional.
- Facilidade para trocar toda a camada de dados por `Fakes` nos testes.

---

## ADR-019: Parsers em Fronteira Adapter — P2 `if-case` como Default, P2b `try/catch` como Edge Case

**Data:** 2026-04-17
**Status:** Aceito
**Relacionado:** `PATTERN_MATCHING_POLICY.md §P2` / `§P2b`, skill `flutter-expert` §194 (`throw` só em adapter)

### Contexto
O monorepo adotou `if-case` (P2) como forma canônica de parsing em fronteiras adapter. Em A07–A09 (BFF Web handlers de Auth + Registry Patient + Registry Family), P2 funcionou bem porque os DTOs tinham 3–7 campos obrigatórios.

Em A10 (Assessment 7 fichas), cada DTO passou a ter 10–15 campos obrigatórios (`UpdateHousingConditionRequest` = 15). Aplicar P2 em todos os 7 intents exigiria ~80 checagens manuais duplicando o schema já gerado por `json_serializable`. Risco alto de drift quando DTOs evoluírem e boilerplate impossível de manter sync com o código gerado.

A primeira implementação usou `try { fromJson(body) } catch (_) { Failure(...) }` — resolveu o drift mas introduziu dois anti-patterns:
1. `catch (_)` descarta a cause — debug impossível em prod
2. Nenhum logging da exceção capturada

Reprovado em review ad-hoc. Hardening aplicado convertendo para `catch (e, st)` + `obs?.logError('<ficha>.parse_failed', cause: e, stack: st)`.

### Decisão

**1. P2 `if-case` continua default** para todos os parsers em adapter layer com <10 campos obrigatórios e sem PII-sensível.

**2. P2b (`try/catch` sobre `fromJson` gerado) é explicitamente aprovado** quando **todas as 3 condições do gatilho** convergem (ver `PATTERN_MATCHING_POLICY.md §P2b`):
   - Fronteira adapter (Intent / Handler / Mapper)
   - DTO tem `fromJson` gerado (`json_serializable` / `freezed` / `drift`)
   - ≥10 campos obrigatórios **OU** mensagem deve ser PII-safe estrutural

**3. Forma canônica P2b é obrigatória** (code review faz hard-reject em desvio):
   - `catch (e, st)` — nunca `catch (_)` nem `catch (e)` sem stack
   - `obs?.logError` com cause + stack (para AcdgLogger + Sentry)
   - `_XxxParseError` privada `final class with Equatable implements Exception`, `toString()` retornando string fixa
   - `ObservabilityContext? obs` opcional no parser (compat com testes)

**4. Checklist e fluxo de decisão** ficam em `PATTERN_MATCHING_POLICY.md §P2b` — referência obrigatória para agentes `test-writer` e implementer **antes** de escolher entre P2 e P2b. Adicionado ao checklist de code review.

### Consequências
- Parsers de DTOs "gordos" (Assessment, formulários complexos) escalam sem drift contra o schema gerado.
- Cause + stack sempre disponível para debug em prod (via AcdgLogger + Sentry).
- Mensagem de erro uniforme PII-safe — impede shape-leak para atacantes probing a API.
- Custo: ~15 linhas a mais por Intent vs `catch (_)`. Aceito.
- Agentes precisam consultar o fluxo de decisão §P2b antes de escrever qualquer parser — matéria de code review automático.

### Referência de implementação
- **Canon default (P2):** `bff/social_care_web/lib/src/intents/register_patient_intent.dart` (A08, 3 campos obrigatórios).
- **Edge case aprovado (P2b):** `bff/social_care_web/lib/src/intents/update_housing_condition_intent.dart` + 6 intents irmãos (A10, 10–15 campos cada).

### Superseded by
Nenhum.

---

## ADR-020: `IntentPayload` Record Carrier — Consideração Adiada

**Data:** 2026-04-17
**Status:** Adiado (consideração registrada; reavaliar sob gatilho)
**Relacionado:** ADR-019, `PATTERN_MATCHING_POLICY.md §P2b § Carrier da decisão`

### Contexto

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

### Motivação apresentada

1. **Compatibilidade com P3 (tear-offs)**: assinaturas uniformes permitiriam passar parsers como `Result<T> Function(IntentPayload)` first-class em maps, routers dinâmicos, frameworks de fuzz testing.
2. **`obs: _` como declaração ativa de intenção**: o wildcard explicita que o autor do Intent P2 **sabe** que observabilidade existe e **decidiu** descartá-la. Mais rico semanticamente que "parâmetro ausente".
3. **Coerência idiomática**: amarra a regra de negócio P2b com a regra sintática P1/P3 (pattern matching + tear-offs) já documentada.

### Análise de trade-offs

**Prós (confirmados):**
- Tear-off habilitado de parsers como valores de primeira classe
- Retrofit de P2 → P2b toca apenas o Intent (assinatura imutável)
- `obs: _` carrega intenção no código

**Contras (confirmados):**
- **Nenhum use-case concreto hoje**: os 6 handlers (A07–A12) chamam `IntentEspecifico.parseFromBody(...)` nominalmente; não há `Map<String, ParseFunc>`, router dinâmico, nem framework batch. Tear-off é benefício teórico para este monorepo nos próximos 6 meses.
- **Retrofit custoso**: 29 Intents + 6 handlers + ~35 test files tocados. Estimativa 6–8h de trabalho meticuloso com ajuste de call-sites em testes.
- **Perda de informação na assinatura**: a heterogeneidade atual (`P2 sem obs, P2b com obs opcional`) **carrega informação útil** — lendo a assinatura, o dev sabe imediatamente qual estratégia o Intent usa. Com Record, essa informação é ocultada dentro do corpo do método.
- **Overhead cognitivo**: Record destructuring + wildcard pattern é mais avançado que parâmetro opcional nomeado. Curva de adoção real para novos devs.
- **Convivência de estilos**: se adotado apenas em A13+, 75% do monorepo fica em estilo velho vs 25% em estilo novo — janela quebrada, ambiguidade em code review.

### Decisão

**Adiado.** Manter canon atual com `{ObservabilityContext? obs}` opcional (ver `PATTERN_MATCHING_POLICY.md §P2b § Carrier da decisão`).

Razões:
1. **YAGNI** — o benefício primário (tear-offs) não tem uso concreto previsto.
2. **Coerência imperfeita > perfeição fragmentada** — adotar em A13+ sem retrofit criaria convivência de estilos, pior que o status quo.
3. **Custo de oportunidade** — 6–8h de retrofit no meio de Onda 3 (A13–A15 pendentes) não se justifica por purismo idiomático.

### Gatilho de reavaliação

Reabrir esta decisão quando **qualquer** dos seguintes emergir:
- Router dinâmico mapeando URL → parser (ex: `Map<String, ParseFunc>`)
- Framework de fuzz testing exercitando parsers em batch
- Gateway reflexivo que descobre Intents por reflection/code-gen
- Necessidade de passar parsers como deps injetáveis em testes de handler
- Quinto Intent que precisa de P2b (hoje 8 Intents P2b entre A10 e A12; se crescer, custo unitário de retrofit cai)

### Se retrofit for aprovado no futuro

Ordem recomendada:
1. Criar `typedef IntentPayload` em `packages/core_contracts/`
2. Migrar Intents A07 (5) — suite canônica 87 tests valida
3. Progredir A08 → A12 em sequência (cada wave valida com 100+ tests)
4. Atualizar 6 handlers + testes de call-site
5. ADR-020 atualizado para status "Aceito"

### Referência
- Proposta completa: conversa-sessão 2026-04-17 (pós-A12 close-out)
- Análise de YAGNI: `PATTERN_MATCHING_POLICY.md §P2b § Carrier da decisão` + callout embedded

### Superseded by
Nenhum.
