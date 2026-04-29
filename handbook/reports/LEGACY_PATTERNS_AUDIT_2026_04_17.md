# Auditoria de Padrões Legados — ACDG

> **Data:** 2026-04-17 (pós-A06c, durante A06d Wave 1)
> **Escopo:** todo o monorepo (bff/ + packages/ + apps/)
> **Propósito:** mapear padrões pré-Dart-3 ainda presentes e propor modernizações sistemáticas
> **Base:** `handbook/architecture/ENCAPSULATION_POLICY.md` + `PATTERN_MATCHING_POLICY.md`

---

## Sumário executivo

| Débito | Ocorrências | Severidade | Política aplicável |
|--------|:-----------:|:----------:|---------------------|
| **Casts `as Map<String, dynamic>` inseguros** | 197 | 🔴 alta | P2 (`if case`) |
| **`if/else if` encadeado** | 75 | 🟡 média | P1 (State Matrix) |
| **`late` usage** | 102 | 🟡 média | auditar caso a caso |
| **`throw` solto fora de adapters** | 10 | 🟡 média | P4 (`Never`) |
| **`throw StateError('Unreachable')` em switches** | 2 | 🔴 alta | P4 (`Never`) |
| **Enums fixos candidatos a sealed/lookup** | 40 (total) — auditar | 🟢 baixa | H6 |
| **Abstract class com impl parcial (Template Method)** | 14 | 🟢 baixa | H1/H2 case-by-case |
| **VOs kernel ainda como classe (pós-A06d)** | 3 | 🟡 média | H8 |
| **Tear-offs perdidos** | ~30 estimados | 🟢 baixa | P3 |
| **Pages com if-chain de roteamento visual** | 2 arquivos grandes | 🔴 alta | P1 |

---

## 1. Casts `as Map<String, dynamic>` — 197 ocorrências

### Natureza
```dart
final map = jsonDecode(cached.fullRecordJson) as Map<String, dynamic>;  // ← cast perigoso
```

Se o JSON não for object, quebra em runtime. Padrão pré-Dart-3.

### Candidatos a `if case` (P2)

| Arquivo | Padrão atual | Refactor proposto |
|---------|--------------|-------------------|
| `bff/social_care_desktop/lib/src/storage/local_social_care_repository.dart:48,272,308` | `jsonDecode(x) as Map<String, dynamic>` + uso direto | `if (jsonDecode(x) case Map<String, dynamic> m) { … }` |
| `bff/social_care_web/lib/src/handlers/*.dart` | Vários lugares onde body é "parseado" por chaves | `if (body case {'field': Type v, …}) { … }` — **grande ganho aqui** |
| `packages/social_care/lib/src/logic/mappers/*.dart` | Muitos `json['foo'] as X` com checagens manuais | Destructuring com `if case {}` + fallthrough para erro tipado |

### Recomendação
Tratar em **sub-ticket dedicado** após Onda 3 terminar (handlers Web). Não urgente, mas elimina classe inteira de runtime errors.

---

## 2. `if/else if` encadeado — 75 ocorrências

### Pontos quentes identificados

**`packages/social_care/lib/src/ui/home/models/patient_detail_translator.dart:253-263` — age buckets:**
```dart
if (a <= 5) { bucket = 'Infantil'; }
else if (a <= 14) { bucket = 'Criança'; }
else if (a <= 17) { bucket = 'Adolescente'; }
else if (a <= 29) { bucket = 'Jovem'; }
// ...
```

**Refactor proposto (P1 + guard clauses):**
```dart
String ageBucket(int a) => switch (a) {
  <= 5 => 'Infantil',
  <= 14 => 'Criança',
  <= 17 => 'Adolescente',
  <= 29 => 'Jovem',
  <= 59 => 'Adulto',
  <= 64 => 'Maduro',
  <= 69 => 'Pré-idoso',
  _ => 'Idoso',
};
```
Mais legível, compacto e idiomático.

**`packages/social_care/lib/src/ui/home/view/page/home_page.dart:140-150` — roteamento por `ficha.name.contains(...)`:**
```dart
if (ficha.name.contains('pessoais')) { /* ... */ }
else if (ficha.name.contains('ingresso')) { /* ... */ }
else if (ficha.name.contains('habitacionais')) { /* ... */ }
// ... mais ~8 branches
```

**Problema duplo:**
1. `contains` em string (frágil — mudança de label quebra)
2. `if-chain` em vez de switch

**Refactor proposto:**
```dart
// Resolver uma vez para enum/ID estável
enum FichaType { pessoais, ingresso, habitacionais, saude, convivencia, /* ... */ }

FichaType? classifyFicha(String name) => /* map único name→type */;

// Uso:
final widget = switch (classifyFicha(ficha.name)) {
  FichaType.pessoais => const PessoaisFicha(),
  FichaType.ingresso => const IngressoFicha(),
  FichaType.habitacionais => const HabitacionaisFicha(),
  // ...
  null => const UnknownFichaError(),
};
```
Ganha exhaustividade + decoupling do label.

---

## 3. `late` usage — 102 ocorrências

### Risco
`late` adia inicialização. Se acessado antes de setar → `LateInitializationError` em runtime. Muitas vezes é sintoma de:
- Construtor complicado tentando fazer muita coisa
- Ordem de inicialização dependente
- Workaround para evitar nullable

### Casos legítimos (aceitos)
- `late final` com inicializador lazy (cálculo caro uma vez)
- Command inicializado no construtor de ViewModel (pattern ACDG)

### Casos suspeitos
- `late X _thing;` sem `final` — sinalizar e auditar
- `late` em campos não-inicializados em `initState` — pode quebrar se a tela re-ativar

### Recomendação
Auditoria seletiva — procurar `late` sem `final` e avaliar caso a caso. Não é ticket — é guideline para reviews.

---

## 4. `throw` solto + `StateError('Unreachable')` — P4 candidate

### 10 throws soltos em lib/ (fora de adapters HTTP)

| Arquivo | Contexto | Recomendação |
|---------|----------|--------------|
| `bff/social_care_web/lib/src/config/server_config.dart:33,41` | Missing env var (startup failure) | **Manter** — é config fail-fast legítimo |
| `packages/core/lib/src/utils/env.dart:71` | idem | **Manter** |
| `packages/core/lib/src/utils/hml_auth_helper.dart:73` | HTTP auth failure | Converter para Result<T> |
| `packages/core/lib/src/offline/drift_database_service.dart:20` | DB open failure | Auditar — provavelmente Result<T> |
| `packages/social_care/lib/src/ui/patient_registration/viewModel/patient_registration_view_model.dart:310` | `Failure() => throw StateError('Unreachable')` em switch | **P4** — `Never` function |
| `packages/social_care/lib/src/data/services/http/_http_shared.dart:129,134` | Idem (occurredAt/recordedAt parse) | **P4** — `Never` function |

### `throw StateError('Unreachable')` — 2 casos críticos

Padrão atual:
```dart
final occurredAt = switch (occurredAtResult) {
  Success(:final value) => value,
  Failure(:final error) => throw Exception('Invalid occurredAt: $error'),
};
```

**Refactor P4:**
```dart
Never invalidResult(String field, Object error) {
  Sentry.captureMessage('Invalid $field: $error');
  throw DomainException('Invalid $field: $error');
}

final occurredAt = switch (occurredAtResult) {
  Success(:final value) => value,
  Failure(:final error) => invalidResult('occurredAt', error),
};
```

Ganho: observabilidade central + type promotion limpa.

---

## 5. Enums — 40 ocorrências (auditar)

### Não revisados individualmente neste audit
Provavelmente há candidatos:
- `enum ResultStatus`, `enum SyncStatus`, etc. — **manter** (imutáveis por natureza)
- `enum DiagnosisCategory`, `enum ConditionType` — **candidatos a lookup dinâmico** (H6)

### Recomendação
Audit seletivo quando começar A07 (handlers Web). Cada enum que aparece no domain de negócio → avaliar se é fixa ou dinâmica.

---

## 6. Abstract class com impl parcial (Template Method)

14 identificadas. A maioria **legítima** (interface + default impl):

| Classe | Justificativa |
|--------|---------------|
| `BaseUseCase<Input, Output>`, `NoInputUseCase<Output>` | Template method razoável — execute() com contrato + implementações | ✅ OK |
| `BaseViewModel extends ChangeNotifier` | Pattern ACDG com lifecycle comum | ✅ OK |
| `Command<T>` | Abstração do Command pattern | ✅ OK |
| `AuthRepository extends Listenable` | Contrato reativo | ⚠️ Avaliar — por que `extends Listenable`? |
| `SyncScheduler`, `SentryClientAdapter` | Interface para swap de estratégia | ✅ OK |
| `LocalCacheContract implements SocialCareContract` | Herança + implements — **quebra após A05** — ticket futuro |

### Pergunta-chave para cada uma
Se removesse `extends X` e usasse `implements`, o código continuaria rodando? Se sim → converter.

---

## 7. VOs ainda como classe pós-A06d (3 arquivos)

Identificados em `bff/shared/lib/src/domain/kernel/`:

| VO | Natureza | Recomendação |
|----|----------|--------------|
| `address.dart` | Composto (street, city, state, zip, …) | **Manter classe** — H8 aplica só a wrappers de 1 campo primitivo |
| `rg_document.dart` | Composto (número, órgão, UF, …) | **Manter classe** |
| `time_stamp.dart` | **Avaliar** — se tem operações (addDuration, format) → classe; se é só DateTime wrapper → extension type |

### Ação
Sub-ticket A06e opcional, só para `time_stamp.dart` se for wrapper puro.

---

## 8. Tear-offs perdidos (P3)

Varredura rápida não encontrou casos óbvios (`.map((x) => X.fromJson(x))`), mas isso é surpreendente dado o tamanho do projeto. **Possíveis explicações:**
1. Casos usam lambdas com transformação (ex: `.map((j) => j['nested'])`) — tear-off não aplica
2. Phase 1 já estava usando tear-offs

### Recomendação
Ao migrar mappers em A07+, adotar tear-offs onde possível:
```dart
// Antes
responses.map((r) => PatientMapper.fromResponse(r)).toList()

// Depois
responses.map(PatientMapper.fromResponse).toList()
```

---

## 9. Pages com if-chain de roteamento — CRÍTICO

**2 hotspots identificados:**

### `packages/social_care/lib/src/ui/home/view/page/home_page.dart`
~10 branches de `ficha.name.contains(...)` decidindo qual widget mostrar. **Refactor obrigatório** em T04-T15 da Fase 4 (Flutter migration).

### `packages/social_care/lib/src/ui/home/models/patient_detail_translator.dart`
Vai ser deletado em A15 (foi movido para `data/mappers/` em T02 da Fase 4 planejada).

**Recomendação:** incluir como requisito explícito no plano das fichas da Fase 4. Quando migrar cada ficha, a Page principal também é reescrita com switch expression.

---

## 10. Padrões modernos que NÃO estão no projeto (oportunidades futuras)

### `Record` para retornos múltiplos
Em vez de criar classe trivial para retorno:
```dart
// ❌ Classe só para retornar 2 valores
class UserIdAndName {
  const UserIdAndName(this.id, this.name);
  final String id;
  final String name;
}

// ✅ Record
({String id, String name}) getUserIdAndName() => (id: 'x', name: 'y');
```

**Onde aplicar:** funções internas em UseCases/mappers que retornam múltiplos valores temporários. **NÃO usar** em public API de contratos (aí classe nomeada é melhor).

### Spread + conditional em collection literals
```dart
// ❌ Imperativo
final items = <Widget>[];
items.add(const Header());
if (hasBanner) items.add(const Banner());
items.addAll(rows);

// ✅ Collection literal
final items = <Widget>[
  const Header(),
  if (hasBanner) const Banner(),
  ...rows,
];
```
**Onde aplicar:** montagem de children em builders. Já comum no Flutter.

### Generators (`sync*` / `async*`)
```dart
// ❌ Acumular em lista
Future<List<Patient>> allPatients() async {
  final result = <Patient>[];
  var cursor;
  do {
    final page = await fetchPage(cursor);
    result.addAll(page.items);
    cursor = page.nextCursor;
  } while (cursor != null);
  return result;
}

// ✅ Stream/generator
Stream<Patient> allPatients() async* {
  var cursor;
  do {
    final page = await fetchPage(cursor);
    yield* Stream.fromIterable(page.items);
    cursor = page.nextCursor;
  } while (cursor != null);
}
```
**Onde aplicar:** listagens com paginação. Ganho: consumer pode começar a processar antes de terminar tudo.

### `Freezed` — NÃO recomendo adotar agora
Projeto já usa `@JsonSerializable` + `with Equatable` manual. Freezed geraria ambos + copyWith, mas:
- **Adiciona dependência pesada** (build_runner mais lento)
- **Pattern matching** em Freezed unions é melhor que sealed class raw — mas Dart 3 sealed class + switch já resolve 90% do caso de uso
- **Migração retroativa** dos 70+ DTOs com Freezed seria grande

**Veredito:** **não adotar**. Ficar com padrão atual até surgir necessidade real.

---

## Priorização de ações recomendadas

### P0 — Corrigir já
1. **2 `throw StateError('Unreachable')`** em `_http_shared.dart` e `patient_registration_view_model.dart` — converter para função `Never` (P4)
2. **Padronizar decisão em Pages com if-chain** nos ticks da Fase 4 (home_page principalmente)

### P1 — Durante a Fase 3 (BFF Web — A07-A15)
3. **Handlers Web** nascem usando `if case` para body parsing (elimina dezenas de futuros casts)
4. **Tear-offs em mappers** novos (adotar pattern desde o início)
5. **State Matrix nos testes de handler** (P1 para combinações de status + payload)

### P2 — Durante a Fase 4 (Flutter migration)
6. **Switch expressions nas Views** (substituir `ListenableBuilder` com if/else aninhado)
7. **Refatorar `home_page.dart`** (chain de `contains` → enum + switch)
8. **Auditar `late`** em ViewModels (manter só onde há justificativa)

### P3 — Tickets dedicados opcionais (fim da Fase 3)
9. **Audit 40 enums** → migrar categorias que crescem para lookup dinâmico (H6)
10. **`time_stamp.dart` review** → extension type se for wrapper puro
11. **Cast Map<String, dynamic>** em `local_social_care_repository.dart` — sub-ticket de P2

---

## O que NÃO é débito (evitar falsos positivos)

- **`late final` com inicializador em construtor** — legítimo
- **Abstract class usada como interface com 0 implementação** (ex: `PatientRepository`) — já é interface, só faltou `abstract interface class` (nice-to-have)
- **`throw` em startup config fail-fast** (`env.dart`, `server_config.dart`) — legítimo
- **Enum para status canônico (pending/approved/rejected)** — legítimo, não precisa virar dinâmico

---

## Como usar este documento

Este é um **snapshot para consulta**, não um ticket. Serve para:

1. **Review de PRs** — se ver um dos padrões listados, linkar o section aplicável
2. **Planejamento de Fase 4** — os hotspots já estão mapeados
3. **Onboarding** — novo dev lê o doc para saber "o que evitamos e por quê"

Quando aparecer débito novo não catalogado, adicionar ao documento atualizado.

---

## Referências

- `handbook/architecture/ENCAPSULATION_POLICY.md` — H1-H9 (herança, composition, extension type)
- `handbook/architecture/PATTERN_MATCHING_POLICY.md` — P1-P4 (pattern matching Dart 3+)
- `handbook/reports/COMPLIANCE_REPORT_2026_04_16.md` — auditoria anterior (arquitetural)
