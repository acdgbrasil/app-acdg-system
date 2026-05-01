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

## Princípios (P1–P4)

| # | Princípio | Resumo |
|---|-----------|--------|
| **P1** | State Matrix com Records + Switch Expressions | Compilador força exhaustividade em combinações de estado |
| **P2** | `if-case` para validação cirúrgica | Destructuring + type check + guard em uma linha |
| **P2b** | **Edge case:** `try/catch` sobre `fromJson` gerado | **Apenas** em adapter + DTO gerado com ≥10 campos. Checklist obrigatório. ADR-019 |
| **P3** | Tear-offs em map/chain | Passar `PatientId.new`, `PatientDto.fromJson` direto, sem lambda |
| **P4** | `Never` para funções de falha | Compilador promove tipos após error() chamada |

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
