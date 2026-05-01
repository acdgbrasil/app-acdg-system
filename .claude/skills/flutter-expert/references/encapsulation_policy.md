# Política de Encapsulamento — ACDG

> **Criado:** 2026-04-17 (durante Fase 3 BFF Contract A)
> **Escopo:** todo o monorepo ACDG (Flutter, BFF Web, BFF Desktop, shared)
> **Princípio:** **Composition + Single Responsibility > Hidden State**

---

## Motivação

O uso de `_` em Dart é um reflexo comum — o programador marca privado "por garantia" mesmo quando não há invariante real a proteger. Isso gera:
- Ruído visual (`_thing`, `_otherThing` espalhados)
- Classes inchadas escondendo estado interno mutável
- Dificuldade de testar (state interno não é observável)
- Quebra implícita de SRP (uma classe "faz coisas" em vários Maps privados)

**Esta política reverte o default:** prefira **exposição explícita via tipos próprios** a esconder em `_`.

---

## Regra geral

> **Antes de escrever `_field`, pergunte: "posso extrair isso para uma classe com nome e responsabilidade próprios?"**

Se sim — extraia. Só use `_` quando a resposta honestamente é "não".

---

## Regra complementar — Value vs Reference semantics

> **Antes de escrever uma classe, pergunte: "esta classe tem semântica de VALOR ou de REFERÊNCIA?"**
> **Se VALOR (o padrão na imensa maioria dos casos): `with Equatable` é OBRIGATÓRIO.**
> **Se REFERÊNCIA: Equatable é PROIBIDO (identidade de instância é o que importa).**

### Como decidir

Pergunte-se: **"duas instâncias com o mesmo conteúdo devem ser iguais?"**

| Categoria | Semântica | Equatable? | Exemplos |
|-----------|-----------|:----------:|----------|
| **Domain model** | VALOR | ✅ obrigatório | `Patient`, `FamilyMember`, `HousingCondition` |
| **Value Object (VO)** | VALOR | ✅ obrigatório | `CPF`, `CNS`, `Address`, `TimeStamp` |
| **DTO (request/response)** | VALOR | ✅ obrigatório | `RegisterPatientRequest`, `PatientResponse` |
| **Enum-like sealed class** | VALOR | ✅ obrigatório | variações de `Result<T>`, `Syncer` |
| **Data record/schema** | VALOR | ✅ obrigatório | qualquer `class X { final a, b; }` |
| **Service** | REFERÊNCIA | ❌ proibido | `PatientService`, `Dio` |
| **Repository** | REFERÊNCIA | ❌ proibido | `HttpPatientRepository` |
| **UseCase / Command** | REFERÊNCIA | ❌ proibido | `RegisterPatientUseCase` |
| **ViewModel** | REFERÊNCIA | ❌ proibido | `PatientRegistrationViewModel` (é state + lifecycle) |
| **Store / Cache / Queue** | REFERÊNCIA | ❌ proibido | `InMemoryPatientStore` (state mutável) |
| **Fake / Stub / Mock** | REFERÊNCIA | ❌ proibido | `FakeRegistryBff` |
| **Handler / Middleware** | REFERÊNCIA | ❌ proibido | qualquer classe com lifecycle ligado a request |

### Por que isso importa

1. **Previsibilidade** — `dto1 == dto2` deve funcionar sem surpresa. Sem Equatable, Dart compara referência (quase sempre não é o que você quer em data class).
2. **Testes robustos** — `expect(actual, equals(expected))` em DTO precisa value equality. Sem isso, testes viram acrobacia.
3. **Imutabilidade coerente** — DTO imutável sem Equatable é incoerente: se os campos não mudam, por que duas instâncias idênticas seriam "diferentes"?
4. **Collection semantics** — `Set<DTO>`, `Map<DTO, X>`, `list.contains(dto)` só funcionam corretamente com value equality.

### Exemplos

#### ✅ Correto — Value type com Equatable
```dart
import 'package:core_contracts/core_contracts.dart';

@JsonSerializable()
class RegisterPatientRequest with Equatable {
  const RegisterPatientRequest({required this.personId, this.notes});
  final String personId;
  final String? notes;

  factory RegisterPatientRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterPatientRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RegisterPatientRequestToJson(this);

  @override
  List<Object?> get props => [personId, notes];
}
```

#### ❌ Errado — Value type sem Equatable (herdado Phase 1)
```dart
@JsonSerializable()
class RegisterPatientRequest {  // ← sem Equatable — comparação vira referência
  const RegisterPatientRequest({required this.personId});
  final String personId;
  // ...
}

// Consequência:
final a = RegisterPatientRequest(personId: 'x');
final b = RegisterPatientRequest(personId: 'x');
a == b; // false — mesma informação, instâncias diferentes
```

#### ✅ Correto — Reference type SEM Equatable
```dart
class HttpPatientRepository {
  HttpPatientRepository({required PatientService service}) : _service = service;
  final PatientService _service;
  // Sem Equatable — duas instâncias nunca são "iguais":
  // são pontos diferentes do sistema, com ciclo de vida próprio.
}
```

#### ✅ Correto — Store SEM Equatable
```dart
class InMemoryPatientStore {
  InMemoryPatientStore();
  final Map<String, PatientResponse> patients = {};
  // Sem Equatable — dois stores com o mesmo conteúdo NÃO são "iguais":
  // são instâncias distintas de armazenamento, possivelmente com
  // lifecycle/ownership diferentes.
}
```

### Checklist de code review

Ao revisar uma classe nova, antes de aceitar:

- [ ] **Primeiro teste**: `X(a) == X(a)` deveria retornar `true`?
- [ ] Se sim → **exige `with Equatable` + `props`** cobrindo TODOS os campos finais
- [ ] Se não → está OK sem Equatable, mas verifique: a classe realmente tem identidade própria ou é só data "esquecida"?

### Refatoração pendente identificada

**A06c (planejado):** adicionar `with Equatable` a TODOS os DTOs de `bff/shared/lib/src/contract/dto/` (Phase 1 herdou sem). ~74 arquivos, mudança aditiva.

---

## Quando `_` É obrigatório (lista taxativa)

### 1. Dependências injetadas em componentes da ABSTRAÇÃO
Quando a classe é uma fronteira arquitetural (Repository, Service, UseCase, ViewModel), as deps injetadas devem ser privadas para **impedir que chamadores externos pulem a abstração**.

```dart
class HttpPatientRepository {
  HttpPatientRepository({required PatientService service}) : _service = service;
  final PatientService _service;  // ✅ _ obrigatório

  // Externos NÃO podem fazer repo._service.rawCall()
  // Devem usar os métodos do próprio repository.
}
```

**Regras 22 e 23 do `flutter-expert` skill** formalizam isso para Flutter.

### 2. Helpers de arquivo (funções top-level ou privadas)
Funções/métodos cuja única razão de existir é organização interna.

```dart
bool _isSuccessStatus(int? s) => s == 200 || s == 201 || s == 204;  // ✅ _

Failure<T> _backendFailure<T>(Response r, String fallback) { ... }   // ✅ _
```

### 3. State com invariante real protegido por métodos
Quando o state tem regra de consistência que **só** os métodos da classe garantem.

```dart
class RateLimiter {
  RateLimiter({required this.maxPerSecond}) : _window = Queue();
  final int maxPerSecond;
  final Queue<DateTime> _window;  // ✅ _ — invariante: window é sempre ordenada temporalmente

  bool allow() { /* enfileira com respeito à janela */ }
}
```

---

## Quando `_` NÃO deve ser usado

### A. Em DTOs, data classes, records, schemas
São containers de dados. **Expor é o propósito.**

```dart
// ❌ ERRADO — DTO não tem invariante
class RegisterPatientRequest {
  RegisterPatientRequest({required String personId}) : _personId = personId;
  final String _personId;
  String get personId => _personId;  // redundante
}

// ✅ CORRETO
class RegisterPatientRequest {
  const RegisterPatientRequest({required this.personId});
  final String personId;
}
```

### B. Em coleções/estados que merecem tipo próprio
Se você está criando `Map<String, Patient> _patients = {}` dentro de uma classe, pare e pergunte: **"isso merece ser uma classe `PatientCollection`?"**.

```dart
// ❌ ERRADO — state escondido dentro do fake
class FakeRegistryBff implements RegistryContract {
  final Map<String, PatientSummaryResponse> _summaries = {};
  final Map<String, PatientResponse> _patients = {};

  @override
  Future<Result<StandardIdResponse>> registerPatient(...) async {
    _summaries[id] = ...;
    _patients[id] = ...;
    return Success(...);
  }
}

// ✅ CORRETO — state extraído como colaborador explícito
class InMemoryPatientStore {
  final Map<String, PatientSummaryResponse> summaries = {};
  final Map<String, PatientResponse> patients = {};

  void save(PatientResponse patient, PatientSummaryResponse summary) {
    patients[patient.patientId] = patient;
    summaries[patient.patientId] = summary;
  }

  List<PatientSummaryResponse> listSummaries() => summaries.values.toList();
}

class FakeRegistryBff implements RegistryContract {
  FakeRegistryBff({InMemoryPatientStore? store})
      : store = store ?? InMemoryPatientStore();
  final InMemoryPatientStore store;  // ✅ sem _ — colaborador explícito

  @override
  Future<Result<StandardIdResponse>> registerPatient(...) async {
    store.save(patient, summary);
    return Success(...);
  }
}
```

**Ganhos:**
- Teste pode inspecionar `fake.store.patients` diretamente
- `InMemoryPatientStore` é reutilizável entre outros fakes
- SRP: `FakeRegistryBff` orquestra, `InMemoryPatientStore` guarda

### C. Em variações de comportamento
Se você tem `_mode`, `_strategy`, `bool _isX` guiando branches, **use sealed class ou polimorfismo**.

```dart
// ❌ ERRADO — state interno decidindo tudo
class Syncer {
  Syncer({required Mode mode}) : _mode = mode;
  final Mode _mode;

  Future<void> sync() async {
    if (_mode == Mode.online) { /* ... */ }
    else if (_mode == Mode.offline) { /* ... */ }
    else if (_mode == Mode.paused) { /* ... */ }
  }
}

// ✅ CORRETO — sealed class + subtipos
sealed class Syncer {
  Future<void> sync();
}
class OnlineSyncer extends Syncer {
  @override
  Future<void> sync() async { /* ... */ }
}
class OfflineSyncer extends Syncer {
  @override
  Future<void> sync() async { /* ... */ }
}
class PausedSyncer extends Syncer {
  @override
  Future<void> sync() async { /* no-op */ }
}
```

**Ganhos:**
- Compilador força tratamento de todos os casos (switch exhaustivo)
- Cada subclasse testável isoladamente
- Adicionar nova variação é novo arquivo, não branch novo

### D. Getter público de campo privado sem invariante
Se você só escreve `_x` + `get x => _x`, **apenas torne `x` público `final`.**

```dart
// ❌ ERRADO
class User {
  User({required String name}) : _name = name;
  final String _name;
  String get name => _name;
}

// ✅ CORRETO
class User {
  const User({required this.name});
  final String name;
}
```

---

## Checklist de code review

Antes de aceitar um `_field` no código, verifique:

- [ ] Há invariante que seria quebrada se externos acessassem? (state que muda por métodos)
- [ ] É dependência injetada numa fronteira arquitetural? (Repo, Service, UseCase, ViewModel)
- [ ] É helper de arquivo (função ou método utilitário)?

Se **nenhuma** dessas for verdadeira, o `_` é ruído. Considere:
1. Tornar o campo público (se é só dados)
2. Extrair para uma classe colaboradora (se é state composto)
3. Quebrar em sealed class / subtipos (se é variação de comportamento)

---

## Aplicação concreta na Fase 3

### Refatorar nos próximos tickets (A07–A21)

**Fakes criados em A06** — oportunidade de aplicar:
- `FakeRegistryBff._summaries` + `_patients` → extrair `InMemoryPatientStore` pública
- `FakePeopleBff._people` + `_roles` → extrair `InMemoryPeopleStore`
- `FakeLookupBff._tables` → extrair `InMemoryLookupStore`
- `FakeTeamBff._members` + roles map → extrair `InMemoryTeamStore`

**Handlers em A07–A15** — aplicar desde o nascimento:
- Handler não guarda state (stateless) → zero `_`
- Intent é data class → zero `_`
- UseCase guarda apenas deps injetadas → `_` apenas nesses casos

**Services HTTP em A16–A18** — aplicar:
- Services são stateless com apenas Dio injetado → `_dio` (regra 1 — dependência injetada)
- Não criar Maps/Lists privados; se precisar de cache, extrair classe `*Cache`

### Novo sub-ticket A06b (sugerido)
**Refatorar os 11 fakes de A06 para extrair Stores.** Opcional mas recomendado antes de A07 começar a consumi-los nos testes.

---

## Regra complementar — Inheritance & Polymorphism

> **Prefira composition, interfaces puras e tipos sealed. Herança clássica (`extends` de classe concreta) é último recurso.**

### Ferramentas Dart 3.x (caixa de ferramentas completa)

| Ferramenta | Uso canônico | Exemplo |
|------------|--------------|---------|
| `abstract interface class` | Contrato puro (só assinaturas) | `AuthContract`, `RegistryContract` |
| `abstract mixin class` | Mixin que pode ser usado com `with` OU `extends` | `Equatable` (core_contracts) |
| `mixin` (pure) | Comportamento compartilhado sem state | (evitar state) |
| `sealed class` | Hierarquia fechada — compilador força exhaustividade em switch | `Result<T>` (Success/Failure), estados de tela |
| `abstract class` | Template method com implementação parcial | Raro — evitar quando possível |
| `final class` | Impede `extends` e `implements` fora da biblioteca | Entidades de domínio estritas, DTOs base |
| `extension type` (Dart 3.3+) | Wrapper de custo zero em runtime | `extension type PatientId(String value) {}` |
| `class X implements Y` | Duck typing — contrato sem herdar código | Fakes, implementations de strategy |
| `class X extends Y` | Herança clássica | Último recurso — evitar |

### Princípios (H1–H9)

| # | Princípio | Resumo |
|---|-----------|--------|
| **H1** | Prefira `implements` a `extends` | Fakes implementam contratos, não herdam base |
| **H2** | Composition > Inheritance (GoF) | Colaborador nomeado > herança de utilitário |
| **H3** | Mixin sem state | `Equatable` ✅; `CacheMixin` com Map ❌ |
| **H4** | `sealed class` para hierarquias fechadas | `Result`, variações de estado, Syncer |
| **H5** | `abstract interface class` para contratos | Sub-contracts — zero implementação parcial |
| **H6** | Enum **apenas para domínios imutáveis** | `enum Color` ✅; regras que crescem → **lookup tables dinâmicas** |
| **H7** | Função antes de classe quando stateless | Utilitários, helpers — top-level function |
| **H8** | `extension type` para primitivas | `extension type PatientId(String)` — wrapper zero-cost |
| **H9** | Encapsulamento de estado local em UI | `TextEditingController` para formulários pesados — não sobrecarregar ViewModel |

### DO / DON'T

#### H1 & H2 — Herança vs Composição

**❌ DON'T** — Herança para reaproveitar código utilitário (brittle base class):
```dart
abstract class BaseRepository {
  void logData(String msg) => print(msg);
}

class UserRepository extends BaseRepository {
  void save() {
    logData('Salvando...'); // Herança por conveniência
  }
}
```

**✅ DO** — Contrato puro + injeção de dependência:
```dart
abstract interface class UserRepositoryContract {
  void save();
}

class UserRepository implements UserRepositoryContract {
  UserRepository(this._logger);
  final LoggerContract _logger; // Composição

  @override
  void save() {
    _logger.log('Salvando...');
  }
}
```

#### H3 — Mixin sem state

**❌ DON'T** — Mixin com Map interno vira shared state implícito:
```dart
mixin CacheMixin {
  final Map<String, dynamic> _cache = {};
  T? getCached<T>(String key) => _cache[key] as T?;
}
```

**✅ DO** — Mixin só define comportamento baseado em members públicos:
```dart
mixin Equatable {
  List<Object?> get props;  // ← delegado à classe hospedeira
  @override bool operator ==(Object other) => /* usa props */;
  @override int get hashCode => /* usa props */;
}
```

#### H4 — Sealed class para hierarquias fechadas

**✅ DO** — Compilador força exhaustividade:
```dart
sealed class Result<T> {}
final class Success<T> extends Result<T> {
  Success(this.value);
  final T value;
}
final class Failure<T> extends Result<T> {
  Failure(this.error);
  final Object error;
}

// Uso: switch exhaustivo
final msg = switch (result) {
  Success(:final value) => 'Ok: $value',
  Failure(:final error) => 'Erro: $error',
}; // ← compilador reclama se faltar caso
```

#### H6 — Enum vs Lookup table dinâmica

**❌ DON'T** — Engessar regras de negócio que crescem em enum (força novo deploy a cada categoria):
```dart
enum ConditionCategory {
  congenital,
  genetic,
  autoimmune,
  // ... a lista não para de crescer
}
```

**✅ DO** — ID que referencia lookup dinâmico (banco/API):
```dart
extension type CategoryId(String value) {}

class Condition {
  const Condition({required this.name, required this.categoryId});
  final String name;
  final CategoryId categoryId; // ← resolve contra tabela dinâmica
}
```

**Enum é OK** quando a categoria é **verdadeiramente imutável** e nasceu no código (ex: `enum ResultStatus { pending, approved, rejected }` — trio canonical, não cresce). Regra prática: se existe a possibilidade de um **novo valor surgir sem mudar código**, vire lookup table.

#### H8 — `extension type` para primitivas

**❌ DON'T** — Classe pesada só para envelopar String/int (overhead de alocação):
```dart
class PatientId with Equatable {
  const PatientId(this.value);
  final String value;

  @override
  List<Object?> get props => [value];
}
```

**✅ DO** — `extension type` zero-cost:
```dart
extension type PatientId(String value) {}

void fetchPatient(PatientId id) { /* ... */ }

// Compilador reclama se passar String crua:
// fetchPatient('abc'); // ❌ erro de tipo
// fetchPatient(PatientId('abc')); // ✅
```

**Quando **NÃO** usar extension type:** se o tipo tem invariantes (ex: `CPF` precisa validar 11 dígitos), use classe com construtor privado + factory `fromRaw` que retorna `Result<CPF>`. `extension type` é para tipagem de oportunidade, não validação.

#### H9 — Estado local em UI

**❌ DON'T** — Disparar evento ao ViewModel a cada tecla (rebuilds, gargalo, perda de foco):
```dart
TextField(
  onChanged: (text) => viewModel.updateName(text), // ← notifyListeners por caractere
)
```

**✅ DO** — Controller local gerencia mutação transitória; ViewModel só recebe estado final:
```dart
class _MyFormState extends State<MyForm> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _nameController,
      onSubmitted: (_) => viewModel.saveName(_nameController.text), // ← 1 call
    );
  }
}
```

### Checklist de code review (Inheritance & Polymorphism)

Ao revisar uma classe/hierarquia nova:

- [ ] Há `extends` de classe concreta? Justificar — ou converter para `implements`
- [ ] Há mixin com `final _state`? Extrair colaborador
- [ ] Há `enum` para categoria que pode crescer? Converter para lookup dinâmico
- [ ] Há classe `with Equatable` apenas envelopando String/int? Usar `extension type`
- [ ] ViewModel está sendo notificado a cada keystroke? Usar controller local

### Refatoração pendente identificada

**A06c (em andamento):** value equality para DTOs. Stores e fakes ficam intactos — já seguem os princípios.
**A futuro:** auditar IDs no domínio (PatientId, PersonId, etc.) que hoje são classes — considerar migrar para `extension type` se não tiverem invariantes de formato.

---

## Princípios relacionados (já no handbook)

- **SOLID — Single Responsibility Principle** (Robert Martin)
- **Composition over Inheritance** (GoF)
- **Tell Don't Ask** — reduz necessidade de getters que viram `_field` + `get field`
- **Parnas Information Hiding** (1972) — hide **design decisions**, não toda variável

> **Information hiding é sobre esconder decisões que podem mudar — não sobre esconder tudo.**
> Se o campo é só "state que a classe mantém", extrair para colaborador é melhor que esconder.

---

## Resumo em 1 frase

> **Se precisar de `_field`, pergunte: isso pode virar uma classe própria com nome e responsabilidade?**
> Se sim — extraia. Só use `_` quando é dep injetada, helper de arquivo, ou invariante real.

---

## Referências
- `.claude/skills/flutter-expert/SKILL.md` — Non-Negotiables #22 e #23 (dependências privadas)
- `handbook/architecture/CONTRACT_A_PUBLIC_API.md`
- `handbook/architecture/CONTRACT_A_SPEC.md`
