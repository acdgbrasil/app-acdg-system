# BYPASS-REPORT — Sealed-class downcast in `Result<T>` consumers

**Data:** 2026-04-29
**Trigger:** Code review do W4 A11 (RegisterAppointment retrofit) flagou
o pattern `(pathResult as Success<String>).value` como anti-pattern Dart 3.
Investigação pediu varredura sistêmica do monorepo.

## TL;DR

O anti-pattern `as Success<T>` / `as Failure<T>` (downcast manual sobre o
sealed class `Result<T>`) está **profundamente disseminado** no monorepo
(35 arquivos identificados em 4 packages). A causa raiz é uma cadeia de
defesas fracas/ausentes: lint built-in não cobre o vetor, o lint
customizado planejado (A22 `acdg_lints`) está em backlog há 5 ondas,
o handbook tem o "DO" do switch exhaustive mas não tem o "DON'T" do
cast, e o canon do W1 do A23 estabeleceu o pattern errado que foi
replicado mecanicamente.

## Mapa de propagação (35 arquivos)

### BFF Web — `bff/social_care_web/`

**Intents (W1+W2+W3 do A23):** 16 arquivos

```
lib/src/intents/admit_patient_intent.dart                       :38
lib/src/intents/discharge_patient_intent.dart                   :37
lib/src/intents/readmit_patient_intent.dart                     :34
lib/src/intents/withdraw_patient_intent.dart                    :34
lib/src/intents/add_family_member_intent.dart                   :66
lib/src/intents/assign_primary_caregiver_intent.dart            :33
lib/src/intents/update_social_identity_intent.dart              :35
lib/src/intents/remove_family_member_intent.dart                :48,49
lib/src/intents/update_health_status_intent.dart                :41
lib/src/intents/update_housing_condition_intent.dart            :47
lib/src/intents/update_socio_economic_situation_intent.dart     :37
lib/src/intents/update_educational_status_intent.dart           :37
lib/src/intents/update_work_and_income_intent.dart              :37
lib/src/intents/update_community_support_network_intent.dart    :37
lib/src/intents/update_social_health_summary_intent.dart        :37
```

**Handlers:** 1 arquivo

```
lib/src/handlers/registry_family_handler.dart                   :178
```

**Tests pinning the cast:** 2 arquivos

```
test/intents/uuid_validation_test.dart
test/intents/assign_role_intent_test.dart
```

### Flutter packages — `packages/social_care/`

**ViewModel (1):**
```
lib/src/ui/patient_registration/viewModel/patient_registration_view_model.dart  :372,394,401
```

**Mappers (1):**
```
lib/src/data/mappers/patient_register_mapper.dart                               :240
```

**UseCases (10):**
```
lib/src/logic/use_case/registry/register_patient_use_case.dart                  :35
lib/src/logic/use_case/family/add_family_member_use_case.dart                   :25,26
lib/src/logic/use_case/care/register_appointment_use_case.dart                  :24
lib/src/logic/use_case/protection/create_referral_use_case.dart                 :22
lib/src/logic/use_case/protection/report_violation_use_case.dart                :24
lib/src/logic/use_case/assessment/update_health_status_use_case.dart            :22
lib/src/logic/use_case/assessment/update_housing_condition_use_case.dart        :22
lib/src/logic/use_case/assessment/update_educational_status_use_case.dart       :22
lib/src/logic/use_case/assessment/update_socio_economic_use_case.dart           :22
lib/src/logic/use_case/assessment/update_community_support_use_case.dart        :22
lib/src/logic/use_case/assessment/update_social_health_summary_use_case.dart    :23
```

**Tests:** 2 arquivos

```
test/data/services/http_social_care_client_test.dart                            :154,196,229,378,415
test/ui/family_composition/family_composition_bugs_test.dart                    :175
```

### Packages — `packages/people_admin/`

**Tests:** 3 arquivos

```
test/src/data/services/people_admin_client_test.dart                            :56,120
test/src/logic/use_case/manage_roles_use_case_test.dart                         :40
test/src/logic/use_case/search_people_use_case_test.dart                        :49
```

## Causa raiz — por que cada defesa falhou

### 1. Lint built-in do Dart analyzer não cobre o vetor

Lints relevantes ATUALMENTE ligados em `bff/social_care_web/analysis_options.yaml`
e `analysis_options.yaml` raiz:
- `exhaustive_cases: true` — só dispara em **switch sobre enums/sealed sem cobertura
  total**. Não dispara quando o código bypass a o switch via cast manual.
- `strict-casts: true` — só dispara em **upcast implícito de dynamic**. Não dispara
  em downcast EXPLÍCITO `Result<T>` → `Success<T>` porque o cast é tipado e
  legalmente válido em Dart.
- `avoid_dynamic_calls: true` — irrelevante; o cast resulta em chamada tipada.

**Lacuna:** o analyzer trata `as Success<T>` como cast benigno (a hierarquia
`Success<T> extends Result<T>` é válida). Não há lint nativo para "evite cast em
sealed class quando há um pattern matching disponível".

### 2. Lint customizado planejado (A22 `acdg_lints`) nunca foi implementado

`bff/social_care_web/analysis_options.yaml` linha 18-22 documenta literalmente:
> "Rules custom mais rigorosas (catch_without_stack_in_adapter, etc.) ficam
> para o package `acdg_lints` — ver A22 ticket"

Ticket A22 está `phase: request` desde A10 (~5 ondas atrás) com `status: pending —
scheduled for post-A21 cleanup or early phase-4 tooling`. **A defesa que existia em
design ficou no papel.**

Adicionalmente, as rules v1+v2 listadas no `A22/000-request.md` cobrem:
- `catch_without_stack_in_adapter`
- `intent_parse_must_accept_obs`
- `parse_error_must_be_private`
- `prefer_logical_pattern_grouping`

**Nenhuma cobre `as Success<T>` / `as Failure<T>`** porque esse vetor nunca foi
catalogado quando A22 foi escrito. É um BLIND SPOT do próprio ticket.

### 3. Handbook documenta o "DO" mas não o "DON'T"

`handbook/architecture/PATTERN_MATCHING_POLICY.md`:
- §P1 (linhas 35-194) — ensina switch exhaustive em sealed types. Tem 4 armadilhas
  catalogadas, NENHUMA é o cast direto.
- §P2 (linhas 198-336) — ensina `if-case` para validação cirúrgica em estruturas
  dinâmicas. Não menciona quando NÃO usar `if-case` (ex: Result<T>).
- §P2b (linhas 338-498) — edge case try/catch. Não relacionado.

A política implícita é "switch exhaustive sobre sealed types" mas NUNCA foi escrita
a regra explícita "`as Success<T>` é proibido — use switch exhaustive".

### 4. Skill `flutter-expert` tem regras genéricas, sem checagem específica

`.claude/skills/flutter-expert/SKILL.md`:
- Regra 21: "Result<T> everywhere — errors are values, not exceptions"
- Seção "Result Pattern" — mostra `switch (result)` com `case Ok<T>()` / `case Error<T>()`

**Regra 21 não menciona "no manual cast on Result"**. Os exemplos da skill usam
switch exhaustive mas a regra fica implícita. Quando o agente flutter-code-reviewer
roda, ele tem 23 checagens explícitas — **nenhuma sobre cast em sealed types**.

### 5. Skill cobre Flutter, BFF Web não tem skill dedicada

A skill `flutter-expert` ativa em "Flutter, Dart, widget, ViewModel, ..." mas
o BFF Web (`bff/social_care_web/`) é Dart puro server-side com Shelf, não Flutter.
Mesmo se a skill fosse rigorosamente aplicada, ela não cobre o BFF Web, e foi
no BFF Web que o A23 W1 nasceu com o anti-pattern.

### 6. Sweep mecânico amplificou o débito original

`.pipeline/.../A23/STATE.md` linha 6 diz literalmente:
> "Mechanical replication pending across W4 (A11+A12+A13 — 9 endpoints)."

Linha 89:
> "Canonical templates (replicate verbatim for the remaining ~25 endpoints)"

Quando o canon nasceu errado no W1, "replicate verbatim" propagou o bug por:
- W1 (5 intents)
- W2 (5 intents + 1 handler)
- W3 (7 intents)

Total: 17 lugares no BFF Web. A heurística "siga o template existente" virou amplificador.

### 7. REGRA #2 do CLAUDE.md trata só de testes vermelhos

`frontend/CLAUDE.md` REGRA #2 ("NO TEST CHEATING") força verbalização de 4 pontos
ANTES de mexer em teste vermelho. **Não há regra equivalente para code review de
pattern matching**. O cast funciona, os testes passam, então não há gatilho para
PARAR e questionar.

## Forma correta — Pattern canônico

### Opção A — Path-only intent (Template A após correção)

Já está correto em `bff/social_care_web/lib/src/intents/get_patient_intent.dart`:

```dart
static Result<GetPatientIntent> parseFromPath(String rawPatientId) {
  final validated = validateUuidPathParam(rawPatientId, fieldName: 'patientId');
  return switch (validated) {
    Success(:final value) => Success(GetPatientIntent(patientId: value)),
    Failure(:final error) => Failure(error),
  };
}
```

### Opção C-P2 / C-P2b — Path + body (Template C corrigido)

Forma correta para `parseFromBody`:

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

  // ... resto do parsing
}
```

**Por que funciona:**
- `final String patientId;` declara variável sem inicializar.
- Switch exhaustive (sealed `Result<T>`) força definite-assignment via `case
  Success` ou early-return via `case Failure`. O compilador prova que `patientId`
  está atribuído após o switch.
- Zero cast, zero check duplicado. Se um terceiro variant for adicionado a
  `Result<T>`, o compilador para.

## Plano de correção

### Camada 1 — Documentação (handbook)

- [ ] Adicionar §P5 a `PATTERN_MATCHING_POLICY.md`: "No sealed class downcast"
  - DO: switch exhaustive
  - DON'T: `as Success<T>` / `as Failure<T>`
  - Por que: bypassa exhaustiveness, perde safety se variant for adicionado,
    duplica check em runtime
  - Exemplos de cada Template (A/B/C-P2/C-P2b) corrigidos
- [ ] Adicionar entrada em `flutter-expert/SKILL.md` Non-Negotiable Rules:
  - "24. Never `as Success<T>` / `as Failure<T>` — use switch exhaustive"

### Camada 2 — Lint customizado (A22 expansion)

Estender o ticket A22 com uma 6ª rule:

- [ ] **`no_sealed_class_downcast`** (severity: error)
  - Matcher AST: `AsExpression` cujo target type é subclasse de tipo declarado
    como `sealed`. Início conservador: hardcode os tipos `Success<*>`,
    `Failure<*>`, `Ok<*>`, `Error<*>` da `package:core_contracts`.
  - Scope: todo o monorepo
  - Message: "Downcast on sealed class is forbidden — use switch exhaustive
    pattern matching. See PATTERN_MATCHING_POLICY.md §P5."

### Camada 3 — Defesa em depth (CI grep até A22 chegar)

Como A22 ainda não foi implementado, adicionar um check de regex ao Makefile/CI:

- [ ] Script `scripts/check_no_sealed_cast.sh`:
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
- [ ] Wire em `make ci` ou pre-commit hook
- [ ] Remover quando A22 for implementado e o lint customizado virar a defesa

### Camada 4 — Update STATE.md do A23

- [ ] Reescrever Templates A/B/C/D/E em `STATE.md` para mostrar a forma correta
  (switch exhaustive, sem cast).
- [ ] Anotar no W4 entry checklist a referência à §P5 nova.

### Camada 5 — Refactor de produção (decisão de escopo)

Dois cenários:

**Cenário 1 — Escopo do A23 (BFF Web only):**
- 16 intents do W1+W2+W3 (`bff/social_care_web/lib/src/intents/*.dart`)
- 1 handler (`registry_family_handler.dart`)
- 9 intents NOVOS do W4 (escrever na forma correta desde o nascimento)
- 2 testes que pinam o cast (`uuid_validation_test`, `assign_role_intent_test`)
- **Total: 28 arquivos**
- Behavior preserved → testes existentes seguem GREEN
- Anotar débito Flutter packages como ticket A24 separado

**Cenário 2 — Sweep total (BFF + Flutter packages):**
- 28 arquivos do cenário 1
- 1 ViewModel + 1 mapper + 11 UseCases do `social_care`
- 5 testes (2 social_care + 3 people_admin)
- **Total: 46 arquivos**

Recomendação: **Cenário 1 agora** + abrir A24 explicitamente para Flutter
packages. A regra/lint/script entram para travar regressão imediatamente,
e o A24 fica com escopo cirúrgico (sem misturar com o A23).

## Lição estrutural

A causa raiz NÃO é "alguém escreveu cast onde não devia". É:

1. **Defesas em design** (handbook + skill + lint planejado) **mas a defesa em
   código** (lint customizado, script CI, checklist de reviewer) **não foi montada**.
2. **Sweep mecânico cega revisão crítica** — quando o STATE.md diz "replicate
   verbatim" e o canon do W1 está errado, a equipe (humana ou agentic) propaga.
3. **Skills são silos por stack** — `flutter-expert` não cobre BFF Web. Não há
   skill cross-cutting "Result/Sealed Class Discipline" que valha em Dart puro.
4. **Documentar "DO" sem "DON'T" deixa lacuna** — o handbook diz "use switch
   exhaustive" mas nunca diz "não faça `as Success<T>`". O segundo é o que pega
   código real.

## Próximos passos imediatos (sequência sugerida)

1. Aplicar Camada 1 (handbook §P5 + skill) — bloqueia novos casos
2. Aplicar Camada 3 (script CI grep) — bloqueia merge enquanto A22 não chega
3. Atualizar A22 ticket com a 6ª rule (`no_sealed_class_downcast`)
4. Atualizar STATE.md do A23 (templates corrigidos)
5. Refactor BFF Web (28 arquivos — Cenário 1)
6. Abrir A24 ticket para Flutter packages (18 arquivos — débito explícito)
