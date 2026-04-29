# Pattern Matching & Flow Control — ACDG

> **Criado:** 2026-04-17
> **Escopo:** todo o monorepo ACDG (Flutter Web, Flutter Desktop, BFF Web, BFF Desktop, shared, packages)
> **Princípio:** **Usar Dart 3 como Dart 3 — não como "Dart 2 com tipos".**
> **Complementa:** `ENCAPSULATION_POLICY.md`

---

## Motivação

Dart 3 importou conceitos de linguagens com forte segurança de memória e tipagem (Rust, Swift). O resultado são 4 padrões avançados **pouco usados** porque a maioria dos devs continua escrevendo código com mentalidade Dart 2:

1. **State Matrix** — chega de `if` aninhado para combinar booleanos
2. **`if-case`** — validar estrutura + desestruturar em 1 passo
3. **Tear-offs** — passar construtor/método como função de primeira classe
4. **Tipo `Never`** — garantir que um caminho nunca retorna

Este documento consolida os 4 padrões como **diretriz oficial** do monorepo.

---

## Princípios (P1–P5)

| # | Princípio | Resumo |
|---|-----------|--------|
| **P1** | State Matrix com Records + Switch Expressions | Compilador força exhaustividade em combinações de estado |
| **P2** | `if-case` para validação cirúrgica | Destructuring + type check + guard em uma linha |
| **P2b** | **Edge case:** `try/catch` sobre `fromJson` gerado | **Apenas** em adapter + DTO gerado com ≥10 campos. Checklist obrigatório. ADR-019 |
| **P3** | Tear-offs em map/chain | Passar `PatientId.new`, `PatientDto.fromJson` direto, sem lambda |
| **P4** | `Never` para funções de falha | Compilador promove tipos após error() chamada |
| **P5** | **Sem downcast em sealed class.** Use `switch` / `map` / `flatMap` / `combineWith`. | Cast `as Success<T>` bypassa exaustividade — proibido em produção, **permitido em testes**. Defendido pela rule `acdg_lints/no_sealed_class_downcast`. |

---

## P1 — State Matrix com Records + Switch

### A ideia
Empacote múltiplos estados em um **Record** e use **switch expression** com pattern matching. O compilador valida exhaustividade em tipos finitos (enums, sealed classes, booleans).

### ❌ DON'T — `if/else` aninhado
```dart
Widget buildState(bool isLoading, bool hasError, String? data) {
  if (isLoading) {
    return LoadingWidget();
  } else if (hasError) {
    return ErrorWidget();
  } else if (data == null || data.isEmpty) {
    return EmptyWidget();
  } else {
    return DataWidget(data);
  }
}
```
**Problemas:** cada estado é checado isolado, compilador não cobre combinações, muda-se um caso sem saber o impacto nos outros.

### ✅ DO — Record + switch expression
```dart
Widget buildState(bool isLoading, bool hasError, String? data) {
  return switch ((isLoading, hasError, data)) {
    (true, _, _)                          => const LoadingWidget(),
    (false, true, _)                      => const ErrorWidget(),
    (false, false, String d) when d.isEmpty => const EmptyWidget(),
    (false, false, String d)              => DataWidget(d),
    _                                     => const FallbackWidget(),
  };
}
```

### Padrões lógicos (`||`, `&&`) — agrupamento DRY

Quando múltiplos casos levam ao **mesmo resultado**, agrupe com `||` em vez de duplicar linhas. Preserva exhaustividade e elimina drift silencioso quando um dos ramos muda.

**❌ DON'T — duplicação de rota:**
```dart
return switch (syncStatus) {
  SyncStatus.offline => const WarningView(),
  SyncStatus.timeout => const WarningView(),
  SyncStatus.failed  => const WarningView(),
  SyncStatus.success => const SuccessView(),
};
```
**Problema:** três linhas repetidas são três oportunidades de drift. Alguém muda `offline` e esquece de `timeout` e `failed`.

**✅ DO — `||` para agrupar estados equivalentes:**
```dart
return switch (syncStatus) {
  SyncStatus.offline || SyncStatus.timeout || SyncStatus.failed =>
    const WarningView(),
  SyncStatus.success => const SuccessView(),
};
```

**Em State Matrix (Record):**
```dart
return switch ((syncStatus, hasNetwork)) {
  (_, false)                                       => const OfflineBanner(),
  (SyncStatus.failed || SyncStatus.timeout, true)  => const ErrorView(),
  (SyncStatus.success, true)                       => const SuccessView(),
  (SyncStatus.syncing, true)                       => const Loader(),
  (SyncStatus.paused, true)                        => const PausedView(),
};
```

### Quando **NÃO** agrupar com `||`

- Se os casos **parecem** iguais hoje mas podem divergir amanhã (ex: `offline` vs `timeout` podem exigir telemetria diferente). Duplicar é um sinal explícito de intenção.
- Se agrupar reduz legibilidade (>4 estados juntos soam arbitrários — considere extrair a distinção para um enum de mais alto nível).

### Armadilha 1 — `_ =>` preguiçoso cega o compilador

**❌ DON'T:**
```dart
Widget buildSyncState(SyncStatus status, bool hasNetwork) {
  return switch ((status, hasNetwork)) {
    (SyncStatus.syncing, true) => const Loader(),
    (SyncStatus.success, true) => const SuccessIcon(),
    _ => const ErrorIcon(),  // ← se adicionar SyncStatus.paused, compilador não avisa
  };
}
```

**✅ DO** — descartar `_` na **posição** correta, nunca na regra inteira:
```dart
Widget buildSyncState(SyncStatus status, bool hasNetwork) {
  return switch ((status, hasNetwork)) {
    (_, false)                   => const OfflineWarning(), // sem rede, status irrelevante
    (SyncStatus.syncing, true)   => const Loader(),
    (SyncStatus.success, true)   => const SuccessIcon(),
    (SyncStatus.failed, true)    => const ErrorIcon(),
    (SyncStatus.paused, true)    => const PausedIcon(),     // ← compilador força essa linha
  };
}
```

### Armadilha 2 — Guard clause (`when`) com lógica complexa

**❌ DON'T** — lógica de negócio dentro do `when`:
```dart
return switch ((user, prontuario)) {
  (User u, Prontuario p) when checkFederationClearance(u.id, p.nodeId) && p.hasAlerts
    => const AlertView(),
  // ...
};
```
**Por quê:** `when` deixa de ser roteamento — vira execução oculta. Difícil de ler, difícil de testar.

**✅ DO** — computar booleanos ANTES, switch só roteia:
```dart
final hasClearance = checkFederationClearance(user.id, prontuario.nodeId);
final shouldShowAlert = hasClearance && prontuario.hasAlerts;

return switch ((user, prontuario, shouldShowAlert)) {
  (_, _, true)                       => const AlertView(),
  (User u, Prontuario p, false)      => StandardView(u, p),
};
```

### Armadilha 3 — Sobrecarga dimensional

**❌ DON'T** — 4+ variáveis soltas = explosão combinatória:
```dart
return switch ((isLoading, hasError, isEmpty, isPremium, hasNetwork)) {
  // 32 combinações possíveis — impossível manter
};
```
**Por quê:** isso é sinal de que o state está **mal modelado** no ViewModel/Store.

**✅ DO** — consolidar em `sealed class` (Result, AsyncState, etc.):
```dart
return switch ((patientResult, hasNetwork)) {
  (_, false)                       => const OfflineBanner(),
  (Loading(), true)                => const Loader(),
  (Failure(err: final e), true)    => ErrorView(e),
  (Success(data: final p), true)   => PatientDetail(p),
};
```

### Armadilha 4 — Ocultação de intenção no destructuring

**❌ DON'T** — `var list` alocado e não usado:
```dart
return switch ((status, items)) {
  (false, var list)  => const EmptyView(),  // list alocada à toa
  (true, var list)   => ListView(list),
};
```

**✅ DO** — `_` descarta explicitamente; tipo forte quando usa:
```dart
return switch ((status, items)) {
  (false, _)                        => const EmptyView(),   // intenção clara
  (true, List<PatientDto> list)     => PatientListView(list),
};
```

---

## P2 — `if-case` para validação cirúrgica

### A ideia
Pattern matching fora do switch. Permite **extrair + validar + desestruturar** estrutura dinâmica (JSON, Map, dynamic) em uma linha.

### ❌ DON'T — checagens manuais encadeadas
```dart
final json = response.data;
if (json is Map<String, dynamic> &&
    json.containsKey('user') &&
    json['user'] is Map<String, dynamic> &&
    json['user']['id'] is int) {
  final id = json['user']['id'] as int;
  // usar id
}
```
**Problemas:** verborrágico, cast `as int` inseguro se chegar aqui por acidente, quebra se a estrutura muda.

### ✅ DO — `if case` com pattern literal
```dart
final json = response.data;

if (json case {'user': {'id': int id, 'status': 'active'}}) {
  print('Usuário ativo com ID: $id');
}
```

O bloco **só executa** se o json casar exatamente com a "assinatura". O `id` já vem tipado `int`.

### Aplicação concreta no projeto

**Parsing seguro de BFF responses:**
```dart
Result<Patient> parsePatient(Object? json) {
  if (json case {
    'patientId': String id,
    'personalData': Map<String, dynamic> personal,
    'civilDocuments': Map<String, dynamic> civil,
  }) {
    return Success(Patient.fromDecomposed(id, personal, civil));
  }
  return Failure(ParseError('Invalid patient shape'));
}
```

**Validação de webhook:**
```dart
void handleWebhook(Map<String, dynamic> payload) {
  if (payload case {'event': 'patient_created', 'data': {'id': String id}}) {
    dispatchCreated(id);
  } else if (payload case {'event': 'patient_updated', 'data': {'id': String id, 'version': int v}}) {
    dispatchUpdated(id, v);
  }
}
```

### Object destructuring — instâncias com shorthand `:var`

O poder do `if-case` **não é só JSON/Map**. Ele também desestrutura **instâncias de classes** (Entidades, DTOs, Events, variants de `sealed class`) de forma posicional ou nominal.

**❌ DON'T — type check + acesso verboso:**
```dart
if (event is PatientUpdatedEvent && event.status == 'active') {
  final id = event.patientId;
  dispatch(id);
}
```

**✅ DO — pattern com `:final <prop>` shorthand** (usado quando o nome do campo = nome da variável):
```dart
if (event case PatientUpdatedEvent(status: 'active', :final patientId)) {
  dispatch(patientId);
}
```
Leitura: *"se `event` é um `PatientUpdatedEvent` com `status == 'active'`, extraia `patientId` como variável `final`."*

**Em switch sobre `sealed class` (command/event):**
```dart
return switch (command) {
  RegisterPatient(:final cpf, :final personalData) =>
    registerUseCase.run(cpf, personalData),
  UpdateHealthStatus(:final patientId, :final request) =>
    updateHealthUseCase.run(patientId, request),
  DischargePatient(patientId: final id, reason: _) =>
    dischargeUseCase.run(id),
};
```

**Ganho concreto no projeto ACDG:** os `switch (result) { Success(:final value) => ..., Failure(:final error) => ... }` espalhados por UseCases e Handlers JÁ usam esse shorthand implicitamente (vindo de `core_contracts`). Aplicar a mesma forma a `Event`, `Command` e Entidades do domain dá **simetria entre camadas** e reduz o ruído imperativo dos getters.

### List patterns com Rest Element `...`

Para sequências dinâmicas (rotas, tokens, paths), `...` captura o restante da lista sem precisar de índices manuais.

**❌ DON'T — checagem manual de índice + length:**
```dart
final segments = uri.pathSegments;
if (segments.isNotEmpty && segments[0] == 'patients' && segments.length >= 2) {
  final id = segments[1];
  loadPatient(id);
}
```

**✅ DO — list pattern com rest:**
```dart
if (uri.pathSegments case ['patients', String id, ...]) {
  loadPatient(id);
}
```

**Capturando a cauda com `...final rest`:**
```dart
if (tokens case [String header, ...final rest]) {
  // rest: List<String> com os itens restantes
  process(header, rest);
}
```

**Roteamento em switch (case clássico no BFF):**
```dart
return switch (uri.pathSegments) {
  [] || ['home']                                    => HomeView(),
  ['patients']                                      => PatientListView(),
  ['patients', String id]                           => PatientDetailView(id),
  ['patients', String id, 'assessment', String ficha]
                                                     => AssessmentView(id, ficha),
  _                                                 => NotFoundView(),
};
```

Bem-aplicável no BFF Web (parsing de `uri.pathSegments` em webhooks e redirect handling) e em qualquer rotina que hoje esteja escrevendo `list.length >= N` + indexação manual.

### Quando **NÃO** usar P2
- Se a estrutura é **estática e tipada** com **poucos campos** (DTO com `fromJson` gerado e <10 campos obrigatórios) — use `Model.fromJson(...)` direto dentro de `if-case`, ou checks manuais leves.
- Se precisa de **mensagem de erro granular** ("campo X faltando") — prefira validação explícita com `Result<Error>` tipado.

**Exceção aprovada — P2b:** quando o DTO é "gordo" (≥10 campos obrigatórios) e `fromJson` gerado já valida tipo + shape, saia do `if-case` para `try/catch` estrito. Ver próxima seção.

---

## P2b — Edge Case: `try/catch` sobre parsers code-gen

> **Status:** edge case aprovado em ADR-019 (2026-04-17). **Não é** o default. Se o gatilho das 3 condições não converge, use P2.

### A ideia

A regra geral do monorepo é P2 (`if-case`). Mas num subconjunto específico — parsers de body HTTP de DTOs "gordos" na fronteira adapter — a combinatória torna P2 impraticável sem drift contra o schema gerado. Este edge case é **explicitamente aprovado** e vive **apenas na fronteira adapter** (Intent.parseFromBody, Handler, Mapper).

### Gatilho (as 3 condições DEVEM ocorrer simultaneamente)

1. **Fronteira adapter** — `Intent.parseFromBody`, handler, mapper. Se está em domain ou application, **proibido** (skill `flutter-expert` §194: `throw` permitido apenas em adapter, convertido para Result na fronteira).
2. **DTO com `fromJson` gerado** — `json_serializable`, `freezed`, `drift`. O código gerado já valida tipos e lança em malformação; é o source of truth executável do schema.
3. **≥10 campos obrigatórios** **OU** **mensagem de erro precisa ser PII-safe estrutural** (DTO carrega nomes, CPF, CNS, observações livres em sub-DTOs).

**Se qualquer das 3 condições falha → volta para P2 `if-case`.** Não há "P2b lite".

### Por que fugir de P2 neste caso

- **Drift.** P2 × 15 campos = duplicação manual do schema. Quando DTO muda (`fromJson` regenera), P2 precisa ser atualizado à mão. Em 7 fichas × 15 campos = ~100 checagens impossíveis de manter sync com o código gerado. Emergência real: A10 (Assessment 7 fichas).
- **Shape-leak.** Enumerar "campo X missing" em erro de parse permite atacante mapear o shape da API via probing. Mensagem genérica `"Invalid body: missing or malformed required fields"` mata isso.
- **PII.** `CheckedFromJsonException.toString()` pode incluir o valor recebido (ex: nome de cuidador em `DeficiencyDraftDto.responsibleCaregiverName`). Substituir por mensagem fixa elimina o vazamento.

### Forma canônica — OBRIGATÓRIA

```dart
import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../observability/observability_context.dart';

final class UpdateHousingConditionIntent with Equatable {
  const UpdateHousingConditionIntent({
    required this.patientId,
    required this.request,
  });

  final String patientId;
  final UpdateHousingConditionRequest request;

  @override
  List<Object?> get props => [patientId, request];

  static Result<UpdateHousingConditionIntent> parseFromBody(
    String patientId,
    Map<String, dynamic> body, {
    ObservabilityContext? obs,   // opcional — testes não precisam injetar
  }) {
    try {
      final request = UpdateHousingConditionRequest.fromJson(body);
      return Success(
        UpdateHousingConditionIntent(patientId: patientId, request: request),
      );
    } catch (e, st) {
      obs?.logError(
        'assessment.housing.parse_failed',
        cause: e,
        stack: st,
      );
      return Failure(
        const _UpdateHousingConditionParseError(
          'Invalid update-housing body: '
          'missing or malformed required fields',
        ),
      );
    }
  }
}

final class _UpdateHousingConditionParseError
    with Equatable
    implements Exception {
  const _UpdateHousingConditionParseError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
  @override
  String toString() => message;  // NUNCA expõe cause
}
```

### ✅ DO — checklist obrigatório (hard-review)

- [ ] Parser vive em **adapter layer** (Intent / Handler / Mapper)
- [ ] DTO tem `fromJson` gerado (json_serializable / freezed / drift)
- [ ] `catch (e, st)` — captura cause **e** stack
- [ ] `obs?.logError('<namespace>.parse_failed', cause: e, stack: st)` — operação consegue debugar em prod via AcdgLogger + Sentry
- [ ] Retorna `Failure(_XxxParseError(...))` — **nunca** `Failure(e)` cru
- [ ] `_XxxParseError` é `final class with Equatable implements Exception`
- [ ] `_XxxParseError.toString()` retorna **string fixa estrutural** — nunca enumera campos, nunca ecoa valores do input
- [ ] Parâmetro `{ObservabilityContext? obs}` **opcional** no parser
- [ ] Handler chama com `obs: obs` — teste unitário pode omitir
- [ ] Teste explícito assegurando que `error.toString()` **não** contém markers injetados no body (`SECRET_MARKER_XXX`, `11144477735`, nome real, etc)

### ❌ DON'T — rejeição automática em code review

- `catch (_)` — descarta cause, impossível debugar em prod. **Reprovação automática.**
- `catch (e) { log(e.toString()); }` — stack trace descartado, debug incompleto
- `throw` ou `try/catch` fora de adapter — domain/application é zero-throw
- Mensagem enumerando campos missing (`"field X is required"`) — shape-leak
- Mensagem ecoando input (`"Invalid value $cpf"`) — PII-leak
- P2b com DTO <10 campos **sem** PII-sensível — use P2 if-case (mais pequeno e legível)
- Expor `_XxxParseError` como tipo público — é detalhe de implementação do parser
- Incluir `cause` no `toString()` do erro público — vaza via logging downstream
- `obs!.logError(...)` — `obs` é opcional, `!` quebra os testes que não injetam

### Carrier da decisão — Intent signature, não handler

A escolha P2 vs P2b **vive na assinatura do Intent**. O handler não precisa saber qual estratégia o Intent usa — ele só chama `parseFromBody` e, se o parâmetro opcional `{ObservabilityContext? obs}` existir, passa `obs: obs`.

**P2 (Intent sem `obs`):**
```dart
// Intent
static Result<XxxIntent> parseFromBody(
  String patientId, Map<String, dynamic> body,
);

// Handler
final parsed = XxxIntent.parseFromBody(id, body);
```

**P2b (Intent com `obs` opcional):**
```dart
// Intent
static Result<XxxIntent> parseFromBody(
  String patientId, Map<String, dynamic> body, {
  ObservabilityContext? obs,
});

// Handler
final parsed = XxxIntent.parseFromBody(id, body, obs: obs);
```

**Consequências práticas:**
- Um handler pode misturar endpoints P2 e P2b sem branching arquitetural. Uma linha condicional (`obs: obs` presente ou não), não um fork. Validado em A12 (Protection — 2 P2 + 1 P2b no mesmo `ProtectionHandler`).
- Promover um Intent de P2 → P2b (ou vice-versa) toca **um arquivo**; o handler permanece inalterado exceto pela adição/remoção do argumento `obs:`.
- **Code review de conformidade P2/P2b deve focar no Intent**, não no handler. O handler só precisa passar o teste de "chama `parseFromBody` corretamente".
- A heterogeneidade na assinatura é **intencional**: lendo a assinatura, você sabe imediatamente se o Intent é P2 (sem `obs`) ou P2b (com `obs`). Informação explícita no tipo > informação oculta no corpo.

> **Consideração adiada (ADR-020):** um Record carrier universal (`typedef IntentPayload = ({String id, Map<String, dynamic> body, ObservabilityContext? obs})`) foi considerado para uniformizar assinaturas e habilitar tear-offs de parsers genéricos. Adiado por YAGNI — nenhum uso real de tear-off de parser emergiu ainda, e retrofit retroativo custaria ~6-8h. Reavaliar quando surgir router dinâmico ou framework de fuzz/batch validation de Intents.

### Fluxo de decisão (árvore executiva — agentes SEGUEM isto)

```
Você está escrevendo um parser de structure externa (HTTP body, query, event payload)?
│
├─ NÃO → não é parser. Este doc não se aplica.
│
└─ SIM → você está em adapter layer (Intent / Handler / Mapper)?
   │
   ├─ NÃO (domain / application) → PROIBIDO parsear payload bruto aqui.
   │                                Mova para adapter. STOP.
   │
   └─ SIM → o DTO tem `fromJson` gerado (json_serializable / freezed)?
      │
      ├─ NÃO → use P2 if-case (validação manual). STOP.
      │
      └─ SIM → o DTO tem ≥10 campos obrigatórios
      │         OU carrega free-text PII-sensível (nome, CPF, CNS, observação)?
         │
         ├─ NÃO → use P2 if-case (mais pequeno, mais legível). STOP.
         │
         └─ SIM → ✅ APROVADO usar P2b. Aplique forma canônica + checklist DO.
                  Code review verifica linha por linha.
```

### Referência canônica no monorepo

- **Canon default (P2 if-case):** `bff/social_care_web/lib/src/intents/register_patient_intent.dart` (A08) — 3 campos obrigatórios, mensagem estrutural enumerativa aceita.
- **Edge case aprovado (P2b):** `bff/social_care_web/lib/src/intents/update_housing_condition_intent.dart` + 6 intents irmãos (A10) — 10–15 campos, 7 DTOs, PII em sub-DTO Health.

### Histórico

Edge case emergiu em A10 (Assessment 7 fichas). Primeira implementação usou `catch (_)` — reprovado em review por descartar cause. Padrão endurecido para `catch (e, st)` + `obs?.logError` preservando ambas as metas (zero drift vs schema gerado + observabilidade em prod). Registrado em **ADR-019** (`DECISIONS.md`).

---

## P3 — Constructor & Method Tear-offs

### A ideia
Em Dart 3, construtores e métodos são **first-class functions**. Passe a referência direto em `.map`, `.where`, etc. sem envolver em closure.

### ❌ DON'T — closure desnecessária
```dart
final dtos = jsonList.map((json) => PatientDto.fromJson(json)).toList();
final userIds = users.map((user) => user.getId()).toList();
final ids = rawIds.map((raw) => PatientId.create(raw)).toList();
```

### ✅ DO — tear-off (sem parênteses)
```dart
final dtos = jsonList.map(PatientDto.fromJson).toList();
final userIds = users.map((u) => u.getId()).toList(); // tear-off de INSTANCE method precisa acesso ao objeto
final ids = rawIds.map(PatientId.create).toList();
```

### Casos comuns

**Construtor default:**
```dart
final instances = ids.map(PatientId.new).toList();
```

**Construtor named:**
```dart
final patients = jsons.map(Patient.fromJson).toList();
```

**Static method:**
```dart
final results = raws.map(LookupId.create).toList(); // Iterable<Result<LookupId>>
```

**Instance method bound:**
```dart
final nameFn = user.getName;
print(nameFn()); // ok — fechou sobre user
```

### Quando **NÃO** usar
- Se precisa **transformar o argumento** antes de passar: `jsons.map((j) => PatientDto.fromJson(j['patient']))` — tear-off não resolve nested
- Se o método precisa de **contexto** (ex: passar `this`) — closure explícita é mais clara

---

## P4 — Tipo `Never` para funções inatingíveis

### A ideia
`Never` é o **bottom type** do Dart. Uma função que retorna `Never` **nunca retorna** — sempre lança ou termina o programa. Compilador usa isso para **type promotion** depois da chamada.

### ❌ DON'T — throw genérico espalhado
```dart
String processName(String? name) {
  if (name == null) throw Exception('Nome nulo'); // ← genérico, sem domínio
  return name.trim();
}
```
Compilador **promove** `name` depois do throw, mas o erro é inconsistente e difícil de observar em produção.

### ✅ DO — função `Never` centralizada
```dart
/// Esta função NUNCA retorna. Compilador trata linhas abaixo como unreachable.
Never domainError(String reason, {String? module}) {
  Sentry.captureMessage(reason, hint: {'module': module}); // observabilidade
  throw DomainException(reason, module: module);
}

String processName(String? name) {
  final validName = name ?? domainError('Nome não pode ser nulo', module: 'registry');
  return validName.trim(); // ← `validName` garantido não-nulo
}
```

### Ganhos

1. **Type promotion automática** — depois de `name ?? domainError(...)`, Dart sabe que `validName` é `String` não-nula
2. **Observabilidade centralizada** — 1 lugar para Sentry/logging de erros de domínio
3. **Contrato explícito** — tipo `Never` é documentação executável ("não volta daqui")

### Uso em switch exaustivo defensivo

```dart
Widget build(Status s) {
  return switch (s) {
    Status.loading => const Loader(),
    Status.success => const Data(),
    Status.error   => const ErrorView(),
  };
  // Se Status ganhar novo valor, compilador reclama aqui.
  // Mas se quisermos force-brick em tempo de execução:
}

T unreachable<T>(Object s) => throw StateError('Unreachable: $s');
// Usage em casos onde não podemos mudar sealed class por ora:
// _ => unreachable<Widget>(s),
```

**Assinatura preferida:** `Never` se função PODE ser chamada como side-effect; `T unreachable<T>(...)` se usada em expressão com retorno.

---

## P5 — Sem downcast em sealed class (Result discipline)

> **Status:** regra de produção, defendida automaticamente pelo lint `acdg_lints/no_sealed_class_downcast`.
> **Origem:** A23 W4 (2026-04-29) — Otimização arquitetural focada em *Static Typing* rigoroso e *legibilidade Swift-like*, abolindo a necessidade do operador `as`.

### O Desafio: A Limitação da Promoção Subtrativa no Dart 3

O Dart 3 importou o *Pattern Matching* seguro, porém **ainda não suporta promoção subtrativa** como no Swift ou Kotlin. Em Swift, um `guard case let` permite fazer o "early return" e vazar a variável limpa para o resto da função. No Dart, isso é impossível sem um cast:

```dart
final pathResult = validateUuidPathParam(raw, fieldName: 'patientId');

// 1. Fazemos early-return em caso de falha (estilo guard)
if (pathResult case Failure(:final error)) return Failure(error);

// 2. ❌ ERRO DE COMPILAÇÃO AQUI!
// O Dart ainda vê pathResult como "Result<String>". Ele não entende
// que só sobrou o "Success". O Destructuring falha.
final Success(value: patientId) = pathResult; 
```

**A falsa solução:** A equipe contornava isso escrevendo `final patientId = (pathResult as Success<String>).value;`. Isso **bypassa a segurança do compilador**, duplicando o teste de tipo e criando *runtime exceptions* caso a `sealed class` ganhe novos estados.

---

### 🚨 Regra de Ouro (Layer de Produção)

> ❌ **DON'T — Usar downcast em Sealed Classes para forçar tipagem**
> NUNCA tente corrigir a limitação do compilador apelando para o operador `as`. O Lint vai bloquear.
> ```dart
> // ANTIPATTERN LETAL (Bypassa a verificação exaustiva da sealed class)
> final patientId = (pathResult as Success<String>).value;
> ```

> ❌ **DON'T — Usar Destructuring de Tuplas para "calar o erro" de tipo vazado**
> Não crie artifícios como `final Success(...) = pathResult as Success;`. Continua sendo um cast escondido.

---

### 🧠 Modelo Mental — como PENSAR antes de codificar

Não escolha entre as 4 opções por estética. **Faça as 3 perguntas de
calibração** abaixo na ordem — elas resolvem 95% dos casos e tornam a
escolha auditável em code review.

> **Mantra:** *"Sealed só vale se o compilador é o oráculo. Cast manual
> transfere o oráculo de volta para você — em runtime."* Sempre que
> tiver dúvida sobre qual abordagem usar, volte para esse mantra: a
> resposta certa é a que mantém o compilador como oráculo.

#### Pergunta 1 — *"Quantas validações `Result` independentes preciso combinar?"*

| Resposta | Caminho |
|---|---|
| **0** (não tenho `Result`, só tipos puros) | §P5 não se aplica. Use validação direta + early-return. |
| **1** | Vai para Pergunta 2. |
| **2 ou 3 com DEPENDÊNCIA sequencial** (B precisa do valor de A) | Cadeia de `flatMap`s (Opção 2). |
| **2 ou 3 INDEPENDENTES** (todas validáveis em paralelo) | `combineWith` (Opção 1) — 2-ary ou 3-ary. |
| **4+** | **PARE.** Veja "Casos compostos" abaixo antes de codificar. |

#### Pergunta 2 — *"O caminho de `Failure` precisa fazer side-effect ou retornar tipo diferente?"*

| Resposta | Caminho |
|---|---|
| **Sim** (logar, abrir/fechar transação, retornar `Response`/`Widget`/etc) | `switch` exhaustive imperativo (Opção 3). |
| **Não** (apenas propagar/transformar o `Failure`) | Vai para Pergunta 3. |

**Por quê:** combinators (`map`/`flatMap`/`combineWith`) expressam o
caminho de Failure como propagação implícita. Tentar comprimir um
side-effect ali obriga `mapFailure` + `flatMap` em sequência — fica
menos legível e cria 2 lambdas para o mesmo `Failure`. Switch
imperativo é o canon para esse caso.

#### Pergunta 3 — *"O Success-path retorna `Result<R>` ou `R` puro?"*

| Resposta | Caminho |
|---|---|
| **`R` puro** (Intent, DTO, escalar — sem chance de novo erro) | `.map(...)` (Opção 4). |
| **`Result<R>`** (a transformação pode falhar) | `.flatMap(...)` (Opção 2). |

**Heurística memorizada:** *"Closure retorna `R` → `map`. Closure
retorna `Result<R>` → `flatMap`."* Se você confundir, o tipo final
fica `Result<Result<R>>` aninhado e o analyzer aponta — sempre
escute o analyzer aqui (ver Armadilha 6 abaixo).

#### Sinais de "PARE e pense" (não codifique direto)

- 🚨 **Você precisou de mais que 30 segundos** para escolher entre
  `map` e `flatMap`. → desenhe os tipos no papel/comentário antes.
- 🚨 **Sua função tem 4+ `Result` independentes**. → revisite o
  desenho do Intent, talvez algumas dessas validações cabem num
  Value Object próprio.
- 🚨 **Você está prestes a escrever `// ignore: no_sealed_class_downcast`**.
  → você está bypassando a regra. Ou §P5 cobre seu caso e você não
  viu, ou §P5 precisa ser editada (PR ao handbook ANTES do PR ao
  código).
- 🚨 **Você está prestes a inventar `guard()`/`andThen()`/`unwrap()`**.
  → eles JÁ existem como `flatMap` em `core_contracts`. Inventar
  duplica e fragmenta semântica (Armadilha 3).
- 🚨 **Sua cadeia tem 4+ `flatMap` aninhados**. → provavelmente
  cabe `combineWith` ou um helper de domínio. Veja "Casos compostos".
- 🚨 **Você quer logar dentro do closure de `combineWith`**. → o
  closure só roda no Success path; o log fica condicional silencioso
  (Armadilha 5).

---

### ✅ DO — Escolha uma das 4 abordagens elegantes aprovadas

O monorepo ACDG aprova estritamente as 4 opções a seguir. Todas são 100% estáticas, isentas de *Exceptions*, e cobrem exaustivamente as sealed classes.

#### Opção 1: `(Result, Result).combineWith` — Validações Paralelas Independentes (Estilo Swift 🏆)

Esta é a abordagem preferida pelo Tech Lead para validar múltiplos parâmetros (ex: path params e body keys). Usamos a "Tupla" combinada para simular um comportamento limpo e linear sem *Pyramid of Doom*.

> ✅ **DO: Agrupar todas as validações sem dependência através da Tupla `combineWith`**
> O método isola os `Failure` e só invoca a closure se todos os campos forem sucesso. Ele faz *short-circuit* do primeiro erro garantindo type safety.
> ```dart
> static Result<RegisterAppointmentIntent> parseFromBody(String rawPatientId, Map body) {
>   // 1. Resolvemos os inputs independentes 
>   final pathResult = validateUuidPathParam(rawPatientId, fieldName: 'patientId');
>   final profResult = validateProfId(body);
>   
>   // 2. Extraímos tudo de forma 100% segura e tipada, sem casts.
>   return (pathResult, profResult).combineWith((patientId, profId) {
>     return Success(RegisterAppointmentIntent(patientId: patientId, professionalId: profId));
>   });
> }
> ```

> ❌ **DON'T: Separar validações independentes em dezenas de `if-case` ou `flatMap`**
> Não suje a lógica de negócios aninhando fluxos para propriedades que não dependem uma da outra. A Tupla foi desenhada para limpar essa sujeira visual.

#### Opção 2: `Result.flatMap` — Validações Dependentes em Cadeia

Use exclusivamente quando o Passo 2 exige obrigatoriamente um valor derivado do Passo 1 para ser processado. 

> ✅ **DO: Usar `flatMap` para simular Monadic Binding de dependência estrita.**
> ```dart
> static Result<GetPatientIntent> parse(String rawPatientId) {
>   return validateUuidPathParam(rawPatientId, fieldName: 'id').flatMap((validId) {
>     // A validação de permissão DEPENDE do ID processado acima
>     return validateClearance(validId).flatMap((clearance) {
>        return Success(GetPatientIntent(patientId: validId, clearance: clearance));
>     });
>   });
> }
> ```

> ❌ **DON'T: Fazer `flatMap` retornando coisas que não sejam do tipo `Result`**
> O closure interno do `flatMap` DEVE retornar `Failure(...)` ou `Success(...)`. Nunca retorne null ou dispare exceptions ali dentro. Se for transformação simples, use `map`.

#### Opção 3: `switch` Exhaustive Imperativo (Para fluxos de controle não triviais)

Se você precisa rodar *side-effects*, usar *loops* ou processamentos difíceis antes de encadear o retorno, o *Definite Assignment* nativo do Dart resolve o problema do "vazamento de escopo", mas custa caro em linhas de código.

> ✅ **DO: Usar *Definite Assignment* garantindo que a variável seja preenchida.**
> ```dart
> final String patientId;
> switch (validateUuidPathParam(rawId, fieldName: 'patientId')) {
>   case Success(:final value):
>     patientId = value;
>   case Failure(:final error):
>     return Failure(error); // Compilador entende que a falha termina aqui
> }
> // Daqui pra baixo o patientId está disponível livremente sem cast.
> ```

> ❌ **DON'T: Usar o `switch` imperativo se houver mais de uma validação**
> Repetir a estrutura acima 3 vezes na mesma função consome 20 linhas apenas para instanciar 3 *Strings*. Aborte essa ideia e volte para a **Opção 1 (`combineWith`)**.

#### Opção 4: `Result.map` — Transformação síncrona simples (1:1)

> ✅ **DO: Usar `map` quando a saída não puder gerar erro.**
> ```dart
> static Result<GetPatientIntent> parseFromPath(String rawPatientId) =>
>     validateUuidPathParam(rawPatientId, fieldName: 'patientId')
>         .map((id) => GetPatientIntent(patientId: id)); // Sem risco de Failure interno
> ```

---

### 🟢 EXCEÇÃO DA REGRA (Camada de Testes)

O único ambiente no qual realizar o downcast explícito em uma classe selada é a melhor arquitetura existente é no diretório de testes (`test/`, `integration_test/`).

> ✅ **DO: Invocar o comportamento de *Fail-Fast* usando Casts em `expect`**
> Forçar o `as Success<T>` em um arquivo de teste garante que, caso a implementação mude para retornar `Failure`, o teste vai explodir um *TypeError* absurdamente descritivo em vez de passar silenciosamente.
> ```dart
> test('parses valid body', () {
>   final result = parseFromBody(id, body);
>   
>   // TOTALMENTE LEGÍTIMO E OBRIGATÓRIO (Em arquivos de teste)
>   final value = (result as Success<RegisterAppointmentIntent>).value; 
>   expect(value.patientId, kPatientUuid);
> });
> ```

> ❌ **DON'T: Usar Padrões Defensivos para esconder Exceptions nos testes**
> Não crie `if case Success(:final value)` dentro de blocos de teste apenas para satisfazer a estética funcional. Se o erro falhar por `if`, a assertion do teste será ignorada e o *pipeline* continuará falsamente verde.

---

### 🚨 Guia Prático de Decisão Rápida

```text
Você está escrevendo em `lib/` ou `test/`?
├─ TEST/ → 🟢 USE O OPERADOR `as` SEM MEDO. É o padrão oficial de fail-fast.
└─ LIB/  → CONTINUE:

A validação vai exigir Side-Effects complexos ou early-returns no meio do fluxo?
├─ SIM → Use a Opção 3: `switch` exhaustive imperativo (Definite Assignment).
└─ NÃO → CONTINUE:

A transformação é uma conversão 1:1 sem chance de gerar um novo erro?
├─ SIM → Use a Opção 4: `.map(...)`.
└─ NÃO → CONTINUE:

A validação do Passo B PRECISA dos dados decodificados do Passo A?
├─ SIM → Use a Opção 2: `.flatMap(...)`.
└─ NÃO → (Parâmetros soltos do Body / Path) → 🏆 Use a Opção 1: `.combineWith(...)`.
```

---

### 🧩 Casos compostos / esquisitos — heurísticas

A árvore acima cobre 95% dos casos. Os 5% restantes precisam destas
heurísticas. **Em todos eles, o instinto errado é "criar helper
inline"** — sempre pause, leia o caso aqui, e só então decida.

#### Caso A — 4+ validações independentes

`combineWith` está implementado para 2 e 3 elementos por **escolha
deliberada**: 4-ary é sinal forte de Intent inflado. Antes de criar
4-ary:

1. **Pergunte:** essas 4 validações realmente nascem juntas? Ou
   alguma é uma sub-validação que cabe num Value Object próprio (ex:
   `(patientId, memberId)` é um VO `FamilyTie`, não 2 args soltos)?
2. **Pergunte:** é realmente independência, ou alguma deveria ser
   `flatMap` (cascata)? Validar `cpf` E `dataNascimento` é
   independente; validar `endereco` E `cep_pertence_ao_endereco`
   não é.
3. **Se ainda assim sobrar 4 verdadeiramente independentes:** prefira
   encadear dois `combineWith` 2-ary:
   ```dart
   return (r1, r2).combineWith((a, b) =>
     (r3, r4).combineWith((c, d) => Intent(a, b, c, d)),
   );
   ```
   Não criar 4-ary ad-hoc.
4. **Só** crie `combineWith` 4-ary se o pattern aparecer em ≥3 call
   sites do monorepo. Code review valida.

#### Caso B — Validação assíncrona (`Future<Result<T>>`)

`map` / `flatMap` em `core_contracts` operam sobre `Result<T>`
síncrono. Para `Future<Result<T>>` não existe (ainda) combinator:

```dart
// ❌ Não compila — Future<Result<T>> não tem .flatMap herdado
final result = await fetchUser(id).flatMap((u) => fetchProfile(u.id));

// ✅ Padrão atual: await + switch exhaustive imperativo
final userResult = await fetchUser(id);
switch (userResult) {
  case Success(:final value):
    final profileResult = await fetchProfile(value.id);
    // ... continue com profileResult
  case Failure(:final error):
    return Failure(error);
}
```

**Regra:** se esse pattern aparecer em **3+ lugares** no codebase,
abra ticket para estender combinators com `AsyncResult<T>` (alias
para `Future<Result<T>>`) com `flatMap` async. Até lá, switch é a
forma correta. Não invente helper inline em nenhum package.

#### Caso C — Mistura de `Result` com inputs não-`Result`

Comum: validação UUID precisa do `body: Map<String, dynamic>` que
NÃO é `Result`. Use `flatMap` capturando o input não-`Result` no
closure:

```dart
static Result<XIntent> parseFromBody(String rawId, Map<String, dynamic> body) =>
    validateUuidPathParam(rawId, fieldName: 'id')
        .flatMap((id) => _parseBody(id, body)); // body capturado no closure
```

**Não tente** forçar `body` a virar `Result<Map>` se o framework
já garante que a chave decodificada é `Map`. `Result<T>` é para
validação que pode falhar — não para tudo.

#### Caso D — Sealed types ALÉM de `Result`

`Option<T>`, `Either<L,R>`, `NetworkState`, `LoadingState`, `AsyncState`,
qualquer `sealed class` cai sob §P5. Cast em variants delas é
igualmente proibido. O lint `no_sealed_class_downcast` é **GENÉRICO**
— vale para qualquer sealed parent, não só `Result`.

**Antes de criar um novo sealed type:** escreva os combinators
apropriados em `core_contracts/` (ou um package equivalente)
**ANTES de qualquer call site começar a copiar cast manual**. O canon
do A23 W4 nasceu da falha oposta: `Result<T>` existia há tempos com
`map`/`flatMap`, mas ninguém usava — e a equipe foi para `as Success`.
Tipos prontos sem combinators socializados provocam pragmatismo sujo.

#### Caso E — Encadeamento muito longo (5+ `flatMap`)

Se sua função vira:
```dart
return validateA(...).flatMap((a) =>
  validateB(...).flatMap((b) =>
    validateC(...).flatMap((c) =>
      validateD(...).flatMap((d) =>
        validateE(...).flatMap((e) => Success(Intent(a, b, c, d, e)))))));
```

Você tem um sintoma — não uma feature. **Pare e questione:**

1. Algumas dessas validações são realmente **independentes**? Mova
   para `combineWith`.
2. Sua função está fazendo mais que parsing. Quebre em sub-funções
   com nomes do domínio (`_validateRegistration`, `_validateContact`,
   etc.).
3. O Intent está fazendo o trabalho de uso de caso. Mova para
   UseCase.

Se nenhuma das três se aplica, code review precisa **explicitamente
aprovar** a cadeia longa antes do merge.

---

### ⚠️ Armadilhas catalogadas — anti-patterns que retornaram em PRs

Cada armadilha abaixo aconteceu pelo menos 1× no monorepo. Memorize
o **sintoma** — quando você ver na sua tela, pare imediatamente.

#### Armadilha 1 — Tentar destructuring direto após `if-case Failure`

```dart
if (r case Failure(:final error)) return Failure(error);
final Success(value: id) = r;  // ❌ não compila
```

**Sintoma:** o compilador reclama `The matched value type 'Result<T>'
isn't exhaustively matched by 'Success<T>'`. **Tentação imediata é
cast.** **Solução real:** switch (Opção 3), `map`/`flatMap` (Opções 2/4)
— ver Modelo Mental. **Causa raiz:** falta de promoção subtrativa
no Dart 3.

#### Armadilha 2 — `valueOrNull!` para fugir do cast

```dart
final id = result.valueOrNull!; // ❌ "técnico-cast", igual de ruim
```

**Por quê:** `!` lança `TypeError` em runtime sem stack trace útil,
não preserva `error`/`stackTrace`, e bypassa exhaustividade do mesmo
jeito que `as`. **O lint NÃO pega isso** (não é `AsExpression`).
**Code review reprova manualmente.**

**Exceção:** em teste, `valueOrNull` é OK quando combinado com
`expect(...)` que falha em null. Mas `as Success<T>` é mais explícito
ainda — prefira.

#### Armadilha 3 — Inventar `guard` / `andThen` / `unwrap` ad-hoc

```dart
// ❌ duplica flatMap que JÁ existe e perde stackTrace
extension ResultGuardExt<T> on Result<T> {
  Result<R> guard<R>(Result<R> Function(T) f) => switch (this) {
    Success(:final value) => f(value),
    Failure(:final error) => Failure(error), // ⚠️ stackTrace perdido!
  };
}
```

**Por quê:** `Result.flatMap` em `core_contracts` já faz isso E
preserva `stackTrace`. Duplicar gera fragmentação semântica
(`x.guard(...)` vs `y.flatMap(...)` em arquivos vizinhos) e perda
silenciosa de metadados de debug.

**Regra:** combinators novos só entram em `core_contracts/`, com
nome inspirado no canon monádico (`map`, `flatMap`, `mapFailure`,
`combineWith`), com **testes que provam preservação de `stackTrace`**,
e com PR específico ao handbook explicando o gap. **Não invente
inline em nenhum outro package.**

#### Armadilha 4 — Não preservar `stackTrace` em combinator novo

`Failure<T>` carrega `final StackTrace? stackTrace`. Qualquer
combinator que materializa um novo `Failure` precisa propagar:

```dart
// ❌ perde stackTrace — debug em Sentry vira inútil
return Failure(error);

// ✅ preserva
return Failure(error, stackTrace: stackTrace);
```

`combineWith` e `flatMap` já fazem isso — herde-os, não recrie.

#### Armadilha 5 — Side-effect dentro do `transform` de `combineWith`

```dart
// ❌ side-effect torna a propagação não-determinística
return (p, m).combineWith((patientId, memberId) {
  log.info('parsed both ids'); // ← se p falhar, isso não roda. surpresa.
  return Intent(patientId: patientId, memberId: memberId);
});
```

**Por quê:** `transform` SÓ roda se TODOS forem `Success` — logar
dentro dele faz "log" depender silenciosamente do path de sucesso.
Logging deve viver no caller (após o `return`) ou no caminho de
Failure via `mapFailure`.

#### Armadilha 6 — Confundir `map` vs `flatMap`

```dart
// ❌ aninha — tipo final é Result<Result<X>>, não Result<X>
final r = uuidResult.map((id) => parsePayload(id));
//                  ^^^         ^^^^^^^^^^^^^
//                  use flatMap, parsePayload retorna Result<X>

// ✅ achata — tipo final é Result<X>
final r = uuidResult.flatMap((id) => parsePayload(id));
```

**Heurística memorizada:** se a closure retorna `R`, é `map`. Se
retorna `Result<R>`, é `flatMap`. Se você está em dúvida, **rode
`dart analyze`** — ele aponta o tipo final aninhado e geralmente
sugere a forma certa. Sempre escute o analyzer aqui.

#### Armadilha 7 — Switch defensivo em testes

```dart
// ❌ EM TESTE — esconde regressão
test('parses valid body', () {
  final result = parseFromBody(id, body);
  if (result case Success(:final value)) {
    expect(value.patientId, kPatientUuid);
  }
  // Se mudar para Failure, este teste passa SEM rodar nenhum expect.
});
```

Em testes, queremos **fail-fast com TypeError claro**. O cast
`as Success<T>` faz isso. O switch defensivo NÃO. Veja a Exceção
de Testes acima.

#### Armadilha 8 — Suprimir o lint com `// ignore:`

```dart
// ignore: no_sealed_class_downcast  ← ❌ NUNCA em produção
final id = (r as Success<String>).value;
```

**Política:** suprimir o lint local é suprimir a §P5 inteira. Se você
tem caso legítimo, **abra PR ao handbook estendendo §P5** — não
suprima. Code review automático reprova `// ignore:
no_sealed_class_downcast` em qualquer arquivo de produção.

#### Armadilha 9 — Misturar `mapFailure` para "logar" e seguir

```dart
// ❌ tenta usar combinator para side-effect — fica menos legível
return validateUuid(raw, fieldName: 'id')
    .mapFailure((e) {
      log.error('uuid invalid', error: e);
      return e; // tem que retornar — extra confusion
    })
    .flatMap((id) => parseBody(id, body));
```

**Por quê:** `mapFailure` é para **transformar** o erro (ex: domain
error → app error), não para logar. Logar é side-effect — se você
precisa, use switch imperativo (Opção 3). Mistura aqui dá leitura
contraintuitiva.

---

### 🚫 Quando §P5 NÃO se aplica

- Você não tem `Result<T>` no escopo (validação é com tipos puros
  ou exceções gerenciadas em adapter layer com `try/catch` § P2b).
- Você está em arquivo `*_test.dart`, `test/**`, `tests/**`,
  `test_driver/**`, `integration_test/**` — cast é fail-fast
  legítimo (ver Exceção de Testes).
- Você está em código gerado (`.g.dart`, `.freezed.dart`) —
  analyzer já exclui via `analysis_options.yaml`.
- O `as` é um **upcast** óbvio (de `Object?` para um tipo exato),
  não um downcast em sealed. Lint não dispara — só foca em
  `AsExpression` cujo target é subclass de sealed parent.
- Você está validando estrutura **dinâmica não-tipada** (Map,
  JSON cru, dynamic) — use `if-case` (P2). §P5 só vale onde já
  existe `Result<T>` materializado.

---

### 🌐 Comparação cross-language (paridade mental)

Útil para mental model: como esse problema é resolvido em outras
linguagens. Note que Dart 3 é um outlier — em Rust o anti-pattern
**não compila**, em Swift é trivialmente auditável visualmente
(`as!`), em Dart 3 precisamos de lint AST porque `as` é
sintaticamente neutro.

| Linguagem | Forma equivalente à Opção 3 (switch) | Forma equivalente à Opção 2 (flatMap) | Equivalente "as Success" anti-pattern |
|---|---|---|---|
| **Swift** | `guard case .success(let v) = r else { return .failure(e) }` | `r.flatMap { v in ... }` | force-cast `r as! Success` |
| **Rust** | `let v = match r { Ok(v) => v, Err(e) => return Err(e) };` | `r.and_then(\|v\| ...)` | NÃO compila (sum types) |
| **Kotlin** | `val v = when(r) { is Ok -> r.value; is Err -> return r }` | `r.flatMap { v -> ... }` | cast `(r as Ok).value` |
| **Haskell** | `case r of Right v -> ...; Left e -> ...` | `r >>= \v -> ...` | impossível sintaticamente |
| **Scala** | `r match { case Right(v) => ...; case Left(e) => ... }` | `r.flatMap(v => ...)` | `r.asInstanceOf[Right].value` |
| **TypeScript** | `if (r.tag === 'Failure') return r; const v = r.value;` (com narrowing) | `chain(r, v => ...)` (fp-ts) | `(r as Success).value` |
| **Dart 3 (este projeto)** | `switch (r) { case Success(:final v): ... case Failure(:final e): ... }` | `r.flatMap((v) => ...)` | `(r as Success<T>).value` ❌ |

**Insight:** em Rust, `let Ok(v) = r else { return Err(e) }` está
sendo discutido para incorporar promoção subtrativa total. Dart 3
ainda não — daí o lint AST do `acdg_lints` é nossa defesa equivalente
ao "compilador faz isso por você" que outras linguagens já têm.

---

### Defesa em depth contra regressões

1. **Lint `acdg_lints/no_sealed_class_downcast`** — AST-based, dispara em
   QUALQUER `as Subclass` onde Subclass herda de uma `sealed class`.
   Generaliza além de `Result<T>` — cobre `Option`, `Either`, etc. quando
   forem adicionados.
2. **Script `scripts/check_no_sealed_cast.sh`** — fallback grep cirúrgico
   (com excludes de comentário) wireado no CI. Existe enquanto o lint não
   estabiliza com pub workspace caching. Documentado em
   `packages/acdg_lints/README.md` "Known issues".
3. **Code review** — checklist desta policy.

---

## Checklist de code review

Ao revisar código novo, verificar:

- [ ] **P1** — `if/else` encadeado com booleanos múltiplos? Converter para switch com Record
- [ ] **P1** — `_ =>` catch-all em switch? Eliminar a menos que os tipos sejam **infinitos**
- [ ] **P1** — `when` com chamada de função complexa? Extrair booleano antes
- [ ] **P1** — Record com 4+ dimensões? Sinal de state mal modelado — consolidar em sealed
- [ ] **P1** — Múltiplas linhas do switch com mesmo resultado? Agrupar com `||`
- [ ] **P2** — Cast de `Map<String, dynamic>` + check manual? Converter para `if case {...}`
- [ ] **P2** — `x is Tipo && x.campo == valor`? Converter para `if case Tipo(campo: valor, :final outroCampo)`
- [ ] **P2** — Acesso por índice (`list[0]`, `list[1]`) após checar length? Converter para list pattern `[a, b, ...]`
- [ ] **P2b** — `try/catch` sobre `fromJson`? Validar gatilho (adapter + DTO gerado + ≥10 campos ou PII) + checklist: `catch (e, st)` + `obs?.logError('<ns>.parse_failed', cause, stack)` + `_XxxParseError.toString()` fixa. **Reprovar automaticamente `catch (_)`**
- [ ] **P3** — Closure simples em `.map`/`.where`? Converter para tear-off
- [ ] **P4** — `throw` espalhado por regras de domínio? Centralizar em função `Never` com observabilidade
- [ ] **P5** — `as Success<T>` / `as Failure<T>` em arquivo de produção? Reprovar automaticamente. Recomendar switch / `.map` / `.flatMap` / `combineWith` (Modelo Mental 3-perguntas + árvore de decisão na seção §P5).
- [ ] **P5** — `as Subclass` em qualquer outro sealed type (Option, Either, NetworkState…) em produção? Mesmo veredicto. Lint é genérico.
- [ ] **P5** — Switch defensivo em `*_test.dart` mascarando expectation? (Armadilha 7) Substituir por `as Success<T>` / `as Failure<T>` para fail-fast.
- [ ] **P5** — `valueOrNull!` / `result.value` direto após `if-case Failure`? (Armadilha 2) "Técnico-cast", reprovar.
- [ ] **P5** — Extension custom (`guard`, `andThen`, `unwrap`) em qualquer package que não seja `core_contracts`? (Armadilha 3) Substituir por `flatMap`/`map`/`combineWith` ou levar PR ao `core_contracts` se há gap real.
- [ ] **P5** — `Failure(error)` sem propagar `stackTrace` em combinator novo? (Armadilha 4) Reprovar.
- [ ] **P5** — Side-effect (log, dispatch, IO) dentro do closure de `combineWith`/`map`/`flatMap`? (Armadilha 5) Mover para fora ou usar switch imperativo.
- [ ] **P5** — Confusão `map` (deveria ser `flatMap`) ou vice-versa? (Armadilha 6) `dart analyze` aponta tipo aninhado.
- [ ] **P5** — `// ignore: no_sealed_class_downcast` em produção? (Armadilha 8) Sempre reprovar — exigir PR ao handbook §P5 antes.
- [ ] **P5** — Cadeia de 4+ `flatMap` aninhados, ou 4+ `Result` independentes? (Casos compostos A, E) Pause: provavelmente Intent inflado ou validações que cabem em VO.
- [ ] **P5** — `await` de `Future<Result<T>>` seguido de combinator? (Caso composto B) `flatMap` não funciona em Future — use switch imperativo.

---

## Aplicação concreta no projeto ACDG

### Flutter (`packages/social_care/`)
**ViewModels + Views** — Command pattern expõe `running`/`completed`/`error` como booleanos. Combinado com dados da tela, é **caso clássico de State Matrix P1**:

```dart
// Em vez de ListenableBuilder aninhado com if/else:
return switch ((vm.load.running, vm.load.error, vm.patient)) {
  (true, _, _)                         => const Loader(),
  (false, true, _)                     => ErrorView(onRetry: vm.load.execute),
  (false, false, null)                 => const EmptyView(),
  (false, false, Patient p)            => PatientDetail(p),
};
```

### BFF (`bff/social_care_web/`)
**Handlers** recebem `Object?` do JSON body — caso clássico de **P2 (`if-case`)**:

```dart
Future<Response> _register(Request req) async {
  final body = await req.readAsJson();
  if (body case {'personId': String personId, 'prRelationshipId': String rel}) {
    // processar
  }
  return Response.badRequest(body: 'Invalid shape');
}
```

### Fase 3 — A06d (em andamento)
Factory `.create` dos brand types pode usar `P4 Never` para type promotion:

```dart
extension type PatientId._(String value) {
  static Result<PatientId> create(String? raw) { ... }

  /// Convenience — lança via Never se inválido.
  /// Usar APENAS em código interno de testes/fixtures.
  static PatientId orThrow(String raw) =>
    switch (create(raw)) {
      Success(:final value) => value,
      Failure(:final error) => domainError('Invalid PatientId: $raw', module: 'kernel'),
    };
}
```

### Tear-offs em mappers
Após A06c/A06d, mappers que convertem List<ApiDto> → List<Domain> ficam:

```dart
// Antes
final patients = responses.map((r) => PatientMapper.fromResponse(r)).toList();

// Depois
final patients = responses.map(PatientMapper.fromResponse).toList();
```

---

## Princípios relacionados

- **`ENCAPSULATION_POLICY.md` §Inheritance & Polymorphism H4** — sealed class para hierarquias fechadas (combina com P1 exaustivo)
- **`ENCAPSULATION_POLICY.md` §Value vs Reference** — DTOs com Equatable funcionam perfeitamente em P1 destructuring
- **Result<T> pattern** (core_contracts) — sealed `Success`/`Failure` é o caso de uso primário de P1

---

## Referências

- Dart Language Tour — Patterns & Records (oficial)
- Swift Evolution SE-0169 — Pattern Matching (inspiração)
- Rust Book — Match Control Flow (inspiração)
- `handbook/architecture/ENCAPSULATION_POLICY.md` — doc irmão
- `.claude/skills/flutter-expert/references/pattern_matching_policy.md` — cópia sincronizada

---

## Resumo em 1 frase por princípio

- **P1:** Use **Record + switch** para decisões multivariadas — compilador verifica exhaustividade. **Agrupe casos equivalentes com `||`** (`SyncStatus.offline || SyncStatus.timeout => WarningView()`).
- **P2:** Use **`if case`** e switch-pattern para parsing JSON/dynamic **e destructuring de instâncias** (sealed classes, Events, DTOs) — `:final <prop>` shorthand + list patterns `[a, b, ...]` eliminam boilerplate imperativo.
- **P2b:** **Edge case aprovado:** use **`try/catch` sobre `fromJson` gerado** em adapter quando DTO tem ≥10 campos ou PII-sensível — sempre com `catch (e, st)` + `obs?.logError` + `_XxxParseError` privada. **Carrier da decisão é a signature do Intent** — handler só escolhe se passa `obs:`. Code review reprova `catch (_)`. (ADR-019, ADR-020)
- **P3:** Use **tear-offs** em `.map`/`.where` — sem closure ruído.
- **P4:** Use **`Never`** em funções de falha — type promotion + observabilidade central.
- **P5:** **Sem `as Success<T>` / `as Failure<T>` em produção.** Faça as 3 perguntas de calibração (quantos Results? side-effect no Failure? Success retorna `R` ou `Result<R>`?) e escolha entre `switch` exhaustive, `.map`, `.flatMap`, ou `combineWith`. **9 armadilhas catalogadas** — memorize ao menos 1 (Armadilha 6: `map` retorna `R`, `flatMap` retorna `Result<R>`). Em testes (`*_test.dart`), o cast é a forma canônica de fail-fast. Defendido pelo lint `acdg_lints/no_sealed_class_downcast`.
