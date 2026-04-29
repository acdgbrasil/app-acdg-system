# Concurrency & Performance Policy — ACDG

> **Criado:** 2026-04-17
> **Escopo:** Flutter (`apps/`, `packages/`) + BFF Dart (`bff/`)
> **Princípio:** **Mantenha a main thread livre. Use o tipo-sistema como firewall. FFI quando Dart não for rápido o suficiente.**
> **Complementa:** `ENCAPSULATION_POLICY.md` + `PATTERN_MATCHING_POLICY.md`

---

## Motivação

Flutter desktop/web renderiza em **120 fps**. A main thread do Dart é cooperativa — `async`/`await` continuam na mesma thread. Parsing de JSON massivo, validações em lote, cálculos pesados **congelam** a UI.

Dart 3.x trouxe 3 ferramentas que a maioria dos devs não adota:

1. **`Isolate.run`** — concorrência real em uma linha (zero SendPort boilerplate)
2. **Class modifiers** (`base`, `final`, `interface`, `sealed`) — firewall entre bounded contexts
3. **FFI + Native Assets** — Rust/Zig compilados junto com o app, chamados com zero custo

Além da performance, Isolates dão **paridade mental com Swift Actors** no backend ACDG — ambos são modelos de concorrência isolada com message passing. Quem entende `actor RegisterPatientUseCase` no Vapor entende `Isolate.run` no Flutter.

---

## Princípios (C1–C3)

| # | Princípio | Resumo |
|---|-----------|--------|
| **C1** | `Isolate.run` para parsing/compute pesado | Desbloqueia main thread; sintaxe de 1 linha |
| **C2** | Class modifiers como firewall | `base`/`final`/`interface`/`sealed` restringem herança cruzada |
| **C3** | FFI + Native Assets para hot paths | Rust/Zig/C quando Dart não basta |

---

## C1 — `Isolate.run` para parsing e compute pesados

### A ideia
Dart ≥ 2.19 introduziu `Isolate.run(() => ...)`. Roda a função em **outra thread** isolada, retorna o valor via `Future`. Zero `SendPort`/`ReceivePort` boilerplate.

### ❌ DON'T — parsing na main thread
```dart
Future<List<Patient>> fetchPatients() async {
  final response = await api.get('/patients');
  final jsonList = jsonDecode(response.body) as List;

  // Este loop roda na MAIN THREAD — se a lista tem 500 pacientes com aggregates completos,
  // a UI congela por centenas de ms. Animações engasgam, scroll trava.
  return jsonList.map(Patient.fromJson).toList();
}
```

### ✅ DO — delegar para Isolate
```dart
Future<List<Patient>> fetchPatients() async {
  final response = await api.get('/patients');
  final body = response.body;

  // Pula para thread paralela. UI continua em 120fps.
  return Isolate.run(() {
    final jsonList = jsonDecode(body) as List;
    return jsonList
        .cast<Map<String, dynamic>>()
        .map(Patient.fromJson)
        .toList();
  });
}
```

### Regras de ouro

1. **Objetos passados para `Isolate.run` precisam ser "sendable"** — primitivos, `Map`, `List`, classes sem closures capturadas. **DTOs com `@JsonSerializable` funcionam**; classes com `Dio` instance capturada **não**.
2. **Custo de spin-up ~ms** — não vale a pena para listas < 50 items ou parsing sub-10ms. Use para **listas grandes**, **parsing de aggregates complexos** e **validações em lote**.
3. **Não compartilhe state** — se precisa de cache, use modelo de mensagens ou calcule tudo no Isolate e retorne pronto.

### Onde aplicar no ACDG

| Caso | Motivo |
|------|--------|
| Listagem de pacientes (`GET /api/patients` com 100+) | Enriquecimento + mapping pesado |
| `GET /api/patients/{id}` com aggregate completo | Patient + FamilyMembers + todas 7 fichas + analytics |
| Batch lookups (`GET /api/lookups?tables=...`) | Decode múltiplas tabelas grandes |
| Validação de CPF/CNS em importação massiva | mod 11 × milhares de entries |

### Paridade com Swift Actors (backend)

```
Backend Swift (Vapor)       ←→       Frontend Dart (Flutter)
────────────────────────             ────────────────────────

actor RegisterPatientUseCase         Isolate.run(() { ... })
│                                    │
└─ isolated state                    └─ isolated memory
└─ message passing                   └─ sendable args
└─ async suspend                     └─ await Future
```

Mesmo **modelo mental**: memória isolada, comunicação por mensagens. Migrar conhecimento entre frontend e backend vira natural.

---

## C2 — Class modifiers como firewall

### Os modificadores

| Modificador | Permite `extends` fora da library? | Permite `implements` fora da library? | Uso canônico |
|-------------|:----------------------------------:|:-------------------------------------:|--------------|
| `class` (default) | ✅ | ✅ | Uso geral (poucos casos em arquitetura rigorosa) |
| `final class` | ❌ | ❌ | Brand types, Value Objects estritos |
| `base class` | ✅ | ❌ | Classe-mãe cujo comportamento DEVE ser herdado |
| `interface class` | ❌ | ✅ | Contrato puro — só implementa |
| `abstract interface class` | ❌ | ✅ (mas não extends) | Contrato puro sem instanciação |
| `sealed class` | ✅ (somente na library) | ✅ (somente na library) | Hierarquia fechada com exhaustive switch |

### ❌ DON'T — `class` padrão em tudo
```dart
// Qualquer módulo pode criar um "MockTransaction" falso via implements.
// Qualquer módulo pode estender e quebrar invariantes.
class FinancialTransaction {
  void execute() { /* lógica crítica */ }
}
```

### ✅ DO — `base` quando herança é aceitável mas implements não é
```dart
// Impede `implements FinancialTransaction` — garante que toda subclasse
// herda a implementação REAL de execute(), não uma falsa.
base class FinancialTransaction {
  void execute() { /* lógica crítica */ }
}

// Em outro arquivo:
base class RefundTransaction extends FinancialTransaction {
  @override
  void execute() {
    // Pode customizar, mas HERDA o comportamento real.
  }
}

// Errado:
// class FakeTransaction implements FinancialTransaction {  // ❌ ERRO DE COMPILAÇÃO
//   void execute() {}
// }
```

### ✅ DO — `final` quando não pode ser herdada nem imitada
```dart
// Imutável e à prova de manipulação.
final class RgDocument with Equatable {
  const RgDocument({required this.number, required this.state});
  final String number;
  final String state;

  @override
  List<Object?> get props => [number, state];
}
// Fora do arquivo:
// class X extends RgDocument { ... }  // ❌ ERRO
// class Y implements RgDocument { ... }  // ❌ ERRO
```

### ✅ DO — `interface class` para contrato sem instanciação
```dart
// Ninguém pode fazer `new MyContract()` nem `extends MyContract`.
// SÓ pode `implements MyContract`.
interface class MyContract {
  void action();
}
```

(Nota: `abstract interface class` é quase idêntico; o `abstract` torna explícito que não é instanciável. Preferir `abstract interface class` para contratos puros — já é padrão atual dos sub-contracts ACDG.)

### Regra de ouro para Bounded Contexts

Em cada bounded context (Registry, Assessment, Protection, etc.), aplicar:

| Camada | Modifier recomendado |
|--------|---------------------|
| Value Objects (Patient, FamilyMember, etc.) | `final class` (ou `extension type` se primitive) |
| Classe-base com lifecycle (`Command`, `BaseViewModel`) | `base class` |
| Contratos (sub-contracts) | `abstract interface class` |
| Variações fechadas (Result, AsyncState) | `sealed class` |
| DTOs com `@JsonSerializable` | `final class with Equatable` (se não podem ser extendidos) |

### Impacto no ACDG

**Auditoria sugerida após A06d:**
- `bff/shared/lib/src/domain/kernel/address.dart` (composite VO) → candidato a `final class`
- `bff/shared/lib/src/domain/kernel/rg_document.dart` → candidato a `final class`
- `packages/core/lib/src/base/command.dart` → candidato a `base class` (hoje é `abstract class`)
- `packages/core/lib/src/base/base_view_model.dart` → candidato a `base class`
- `bff/shared/.../contracts/*_contract.dart` → já são `abstract interface class` ✅

---

## C3 — FFI + Native Assets

### A ideia
**Foreign Function Interface** permite chamar código nativo (C, Rust, Zig, Swift) direto do Dart. **Native Assets** (em polimento no Dart 3.3+) compila as bibliotecas nativas **junto com o app** — zero bridge, zero custo de setup.

### Quando considerar
- **Criptografia intensa** — assinatura de payloads LGPD, integridade de federação
- **Algoritmos numéricos** — estatísticas, matrizes, análise de indicadores em lote
- **Sincronização hiper-rápida** — diff entre estados locais e remotos no offline-first
- **Parsing binário** — protobuf em hot path, deserialização de formato customizado

### Quando NÃO usar
- **Parsing de JSON comum** — `Isolate.run` resolve (C1 é mais simples)
- **Lógica de negócio** — domain deve ficar em Dart (testabilidade, legibilidade)
- **Qualquer coisa que rode < 10ms** — overhead de call traversing FFI é ~microssegundos; não amortiza

### Exemplo conceitual
```dart
import 'dart:ffi';
import 'package:ffi/ffi.dart';

// Função Rust compilada junto com o app via Native Assets.
@Native<Bool Function(Pointer<Utf8>)>()
external bool validateFederationSignature(Pointer<Utf8> payload);

bool isPayloadValid(String payload) {
  final ptr = payload.toNativeUtf8();
  try {
    return validateFederationSignature(ptr); // roda Rust direto, sem GC
  } finally {
    calloc.free(ptr);
  }
}
```

### Horizon — não adotar agora

**Este princípio fica documentado como opção futura.** A plataforma ACDG hoje não tem hot paths que exijam FFI. Quando surgir (ex: validação de assinatura cryptográfica em cada sync), revisitar.

**Candidatos eventuais no roadmap:**
- Validação de assinatura federativa (se ACDG evoluir para multi-org com signed payloads)
- Diff hash em SyncEngine para listas gigantes
- Criptografia de campo sensível (CPF, CNS) para armazenamento local

---

## Checklist de code review

- [ ] **C1** — `jsonDecode` + `.map(X.fromJson)` em response > 50 items? Mover para `Isolate.run`
- [ ] **C1** — Validação em lote (CPF de centenas de família)? Isolate
- [ ] **C2** — VO imutável sem modifier? Considerar `final class`
- [ ] **C2** — Classe-base com lifecycle importante? Usar `base class` para prevenir fake via `implements`
- [ ] **C2** — Contrato sem implementação? Usar `abstract interface class` (já é padrão ACDG)
- [ ] **C3** — Hot path com GC pressure? Avaliar FFI (mas só se >1s CPU sustained)

---

## Aplicação concreta no ACDG

### Flutter (A07+ Fase 4 Migration)

**Repositórios HTTP pesados** (A08 Registry: fetchPatients, fetchPatient aggregate):
```dart
class HttpPatientRepository implements PatientRepository {
  HttpPatientRepository({required Dio dio}) : _dio = dio;
  final Dio _dio;

  @override
  Future<Result<List<PatientSummary>>> listPatients({...}) async {
    final response = await _dio.get('/api/patients', ...);
    final body = response.data;

    if (body is! String) return Failure(InvalidResponseError());

    // Parsing + mapping em Isolate — UI fluida.
    final patients = await Isolate.run(() {
      final json = jsonDecode(body) as List;
      return json
          .cast<Map<String, dynamic>>()
          .map(PatientSummaryMapper.fromJson)
          .toList();
    });

    return Success(patients);
  }
}
```

### BFF Dart (Onda 3)

**Handler composto** (A14 lookups batch):
```dart
Future<Response> _lookupsBatch(Request req) async {
  final tables = req.url.queryParameters['tables']?.split(',') ?? [];

  // N requests paralelas aos backends — JÁ usa isolation natural via await
  final results = await Future.wait(tables.map((t) => backend.getLookupTable(t)));

  // Serialização do response composto em Isolate se tiver muitas tables × muitos items
  final jsonBody = await Isolate.run(() =>
    jsonEncode({'tables': { for (var i = 0; i < tables.length; i++) tables[i]: results[i] }})
  );

  return Response.ok(jsonBody, headers: jsonHeaders);
}
```

### Modifiers já em uso

- ✅ **`abstract interface class`** — todos sub-contracts (`AuthContract`, `RegistryContract`, ...)
- ✅ **`extension type`** — brand types migrados em A06d
- 🟡 **`final class`** — aplicável em `Address`, `RgDocument`, DTOs com `@JsonSerializable` (auditoria sugerida)
- 🟡 **`base class`** — aplicável em `Command<T>`, `BaseViewModel`, `BaseUseCase` (auditoria sugerida)

---

## Princípios relacionados

- **Swift Actors** (backend Vapor) — mesmo modelo mental de Isolates
- **H8 (`extension type`)** de `ENCAPSULATION_POLICY.md` — zero-cost primitives (complementa C2)
- **P4 (`Never`)** de `PATTERN_MATCHING_POLICY.md` — domainError em Isolates (observabilidade)

---

## Resumo em 1 frase por princípio

- **C1:** `Isolate.run(() { heavyWork(); })` — main thread livre, paridade com actors.
- **C2:** `base`, `final`, `interface`, `sealed` como firewall arquitetural entre módulos.
- **C3:** FFI/Native Assets apenas quando Dart não é rápido o suficiente — horizon, não default.

---

## Referências
- Dart Language Tour — Isolates (oficial)
- Dart 3 Class Modifiers — Announcement (dart.dev/language/class-modifiers)
- Native Assets — dart.dev (feature em estabilização)
- `handbook/architecture/ENCAPSULATION_POLICY.md`
- `handbook/architecture/PATTERN_MATCHING_POLICY.md`
