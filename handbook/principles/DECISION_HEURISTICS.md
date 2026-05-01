# Decision Heuristics — frontend (Conecta Raros)

> Heurísticas de decisão arquitetural extraídas de tickets reais do monorepo. Quando aparecer um trade-off recorrente, consulte aqui antes de improvisar.
>
> Cada heurística tem: **problema concreto + decisão real + critério de aplicação + quando NÃO aplicar.**
>
> **Origem:** Onda 4 (A16-v2 / A17-v2 / A18a-v2 / A18b-v2) — desktop rebuild break-change. Validado em campo com 376/376 tests GREEN e zero analyzer issues através de 4 sub-tickets consecutivos APPROVED Round 1.

---

## Como usar este documento

- **Antes de propor uma mudança grande:** consulte H1 e H3.
- **Antes de escrever um teste:** consulte H2 e H4.
- **Ao implementar lógica baseada em tempo:** consulte H5.
- **Ao desenhar test infra:** consulte H6.
- **Em dúvida final:** consulte a tabela de decisão no fim do doc.

---

## H1 — Refactor cirúrgico > eager broad refactor

### Problema

Uma especificação (test-writer, ADR, RFC) propõe uniformizar um contrato em N implementações. **Mas só M < N delas têm consumidores que realmente precisam da mudança.**

### Decisão real (A18b-v2, 2026-04-30)

W0 (test-writer) propôs refatorar **todas as 5 cache contracts** para retornar `Cached<T>` envelope (em vez de DTO direto). Lógica: "se um precisa, todos precisam — mantém uniforme".

W1 (implementer) **não seguiu cegamente.** Olhou os 42 use cases concretos:
- `PatientsCache.findById/findByPersonId` → 9 write use cases leem `version`. Refatora.
- `LookupCache.findItemById/findRequestById` → 3 lookup admin writes precisam. Refatora.
- `CareCache.findById` → register-style writes (`expectedVersion: 0`) ou pega version do PatientsCache. **Não toca.**
- `ProtectionCache` → register-style. **Não toca.**
- `AuditCache` → read-only. **Não toca.**

**Refactor cirúrgico:** apenas 4 method signatures em 2 contracts mudaram. Care/Protection/Audit ficaram intocados. Reviewer aprovou Round 1.

### Critério de aplicação

**Aplicar quando:**
- A mudança é **estética** (uniformidade de tipo de retorno, naming convention)
- Menos de ~50% dos consumers reais precisam da mudança
- O custo de manter heterogeneidade é baixo (nenhum invariante de runtime quebra)

**NÃO aplicar (= refactor amplo é o certo) quando:**
- A mudança é um **invariante** (ex: "todo write retorna `Result<T>`" — não dá pra alguns retornarem void)
- Mais de ~80% dos consumers precisam (custo de variantes especiais > custo de uniformizar)
- O contrato é **público** consumido por código fora do controle direto (breaking changes propagam)

### Por que importa

**Blast radius** = quantos arquivos um change toca. Quanto maior, mais risco em code review, mais conflitos de merge, mais teste impactado. Cirúrgico mantém blast radius proporcional ao problema real.

### Antipattern relacionado

**"Rule of Three" prematuro.** Se o test-writer prevê 5 consumers similares no futuro mas hoje só 2 existem, NÃO uniformize. Espere o terceiro consumer real chegar. Antecipação errada > duplicação local.

---

## H2 — Test the contract, not the implementation

### Problema

Tests precisam validar que o sistema faz a coisa certa, sem **acoplar** a tests específicos do COMO o sistema faz. Tests acoplados à implementação quebram em refactors que preservam comportamento.

### Decisão real (A18b-v2, 2026-04-30)

Pattern 2 (Write optimistic-through) faz update local antes do backend ack:

```dart
final patched = cached.dto.copyWith(status: 'discharged');
await cache.upsertPatient(patched, version: cached.version + 1);
```

W0 flagou: `PatientResponse` não tem `copyWith`. Implementer "deveria" adicionar `copyWith` em 9 DTOs no `bff/shared/`.

W1 olhou os tests reais e descobriu: **tests não asseram fields específicos do patched DTO.** Asseram apenas:
- `cached.version` foi bumped (5 → 6)
- Mutation correta entrou no Outbox
- Engine foi triggered

Tests NÃO asseram `patched.status == 'discharged'`. Implementer fez:

```dart
// Em vez de adicionar copyWith em 9 DTOs:
await cache.upsertPatient(cached.dto, version: cached.version + 1);
```

Re-upserta o **mesmo DTO** com version bumped. Tests passam. Zero modificação em `bff/shared/`. **Q1 (DTO copyWith) skipped — corretamente.**

### Critério de aplicação

**Aplicar (skip a abstração extra) quando:**
- Os tests verificam **outcomes contratuais** (estado mudou, evento foi emitido, retorno tem certo formato)
- A "mecânica interna" (qual field local mudar) **não é parte do contrato** porque um source of truth externo (backend, DB) eventualmente consolida

**NÃO aplicar (= adicionar a abstração) quando:**
- O caller depende de fields específicos do patch local (ex: UI mostra "discharged" imediatamente após click)
- O patch local é a única source of truth (sem backend)
- Tests precisam verificar fields porque o contrato declara fields

### Por que importa

Tests acoplados à implementação são **frágeis** — refactors de impl que preservam comportamento quebram tests, gerando falsa sensação de regressão. Tests que validam apenas o contrato são **estáveis** — só quebram quando o comportamento real mudou.

### Antipattern relacionado

**"Add copyWith porque parece útil"** — adicionar APIs especulativas em DTOs por "boa prática" sem caller real. Se nenhum test ou caller usa, é entropy. Adicionar quando o primeiro caller real aparecer.

---

## H3 — Constructor uniformity > constructor minimalism

### Problema

Um pattern arquitetural (ex: "Read use case") tem variantes implementacionais (algumas têm fallback remoto, algumas só cache). Manter o **construtor uniforme** entre variantes vs **minimizar params** que cada variante usa.

### Decisão real (A18b-v2, 2026-04-30)

Pattern 1 (Read cache-first) tem assinatura canônica:
```dart
ReadUseCase({required cache, required remote, required clock, Duration staleAfter});
```

Mas 5 reads são **cache-only** (sub-contract não expõe endpoint correspondente):
- `ListAppointmentsUseCase`
- `FetchPlacementHistoryUseCase`
- `ListReferralsUseCase`
- `ListViolationReportsUseCase`
- `FindLookupRequestByIdUseCase`

Esses não usam `clock` nem `staleAfter`. Implementer manteve os params no construtor mesmo assim (não como `final` fields, evitando lint warning):

```dart
class ListAppointmentsUseCase {
  ListAppointmentsUseCase({
    required this.cache,
    required Clock clock,                     // accepted, ignored
    Duration staleAfter = const Duration(minutes: 5),  // accepted, ignored
  });
  final CareCache cache;
  
  Future<Result<List<AppointmentResponse>>> call(String patientId) =>
    cache.listByPatient(patientId);  // só cache; sem stale check
}
```

### Critério de aplicação

**Aplicar (manter uniforme) quando:**
- O pattern é **bem-definido** e estável (Pattern 1 tem 4 deps canônicas)
- Há **forward-compat valuable** — Phase X+ vai adicionar a feature ausente (backend list endpoint vai chegar)
- Os params unused são **leves** (Clock, Duration, valores) — sem efeito colateral no construtor

**NÃO aplicar (= minimalism é certo) quando:**
- O "pattern" não é estável; cada implementação faz coisa diferente
- Forward-compat é especulativo (ninguém na roadmap)
- Params unused têm **custo** (ex: `Database connection` que abre conexão no construtor)

### Por que importa

Construtor é um **contrato com o futuro**. Manter uniformidade evita breaking change quando a feature ausente chega — toda a wiring (facade, tests, callers) já está pronta. Custo de aceitar params ignorados é tipicamente zero.

### Antipattern relacionado

**"Minimal constructor por dogma DRY"** — remover params unused "porque YAGNI". Funciona para variações isoladas; falha para variações de um pattern conhecido com roadmap.

---

## H4 — Cross-cutting rule boundary scoping

### Problema

Uma regra arquitetural cross-cutting (REGRA #2 "no test cheating", "no PII em logs", "no SQL injection") **se manifesta em múltiplas camadas**. Antes de escrever tests, **mapeie qual layer testa qual boundary** — evitando god-tests que misturam responsabilidades.

### Decisão real (A18b-v2, 2026-04-30)

REGRA #2 do master STATE A18: **"Optimistic write rollback em failed_dead — NÃO reverter cache otimista."**

"Failed_dead" tem **3 boundaries** distintos:

| Boundary | Quando acontece | Quem testa |
|---|---|---|
| **Pre-enqueue failure** | `outbox.enqueue()` retorna `Failure` (DB closed, etc) | A18b (use case) |
| **Drain dead-letter** | SyncEngine drena, backend retorna 409, mutation marcada `failed_dead` | A18a (engine) |
| **UI surfacing** | App lê queue, mostra "conflito detectado" | A18c (facade + shell) |

A18b testa apenas pre-enqueue:
```dart
test('outbox enqueue failure → cache UNCHANGED + engine NOT triggered', () async {
  await ctx.syncDb.close();  // force outbox failure
  
  final result = await ctx.useCases.dischargePatient(patientId, request);
  
  expect(result, isA<Failure<void>>());
  expect(cached.dto.status, equals('active'));  // não mudou
  expect(ctx.fakeEngine.triggerDrainCount, equals(0));  // engine NÃO foi chamado
});
```

**Não tem teste em A18b** pra "drain falhou, cache rollbacka". Nem teste de UI surfacing. Cada layer cuida do seu boundary.

### Critério de aplicação

**Sempre aplicar** quando uma regra cross-cutting toca múltiplas layers:

1. **Mapeie os boundaries** explicitamente (em tabela, no STATE.md do ticket).
2. **Atribua cada boundary à layer correta**.
3. **Tests de cada layer** cobrem só seu boundary.
4. **Integration tests end-to-end** existem APENAS pra cenários explícitos onde múltiplas camadas precisam ser exercitadas juntas (raros, intencionais).

### Por que importa

Sem boundary scoping, **test creep** acontece: "ah, e também testar X, e também Y, e também Z". Vira god-test que mistura responsabilidades. Quando algo quebra, é difícil isolar a layer culpada — todo mundo aponta pra todo mundo.

### Antipattern relacionado

**"Integration test como default"** — testar fluxos end-to-end como first-line de validação. Integration tests são caros, lentos, flaky. Eles complementam unit tests com boundaries claros, não substituem.

---

## H5 — Cross-layer Clock injection

### Problema

Lógica baseada em **TTL / staleness / expiration** envolve **dois timestamps**:
- O `cachedAt` produzido por uma layer (escrita)
- O `now` consumido por outra layer (leitura)

Se cada layer chama `DateTime.now()` próprio, os timestamps podem divergir → **race conditions silenciosas em testes** (e às vezes em produção sob load).

### Decisão real (A17-v2 + A18b-v2, 2026-04-30)

Pattern 1 (Read cache-first) precisa testar staleness:
```dart
if (cached.cachedAt is older than 5min) refresh();
```

`cachedAt` é produzido pela **cache impl** no `upsertPatient`; `now` é consumido pelo **use case** no staleness check.

Solução cross-layer:

```dart
// Cache impl — Clock injectable:
class DriftPatientsCache implements PatientsCache {
  DriftPatientsCache(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final DateTime Function() _now;
  
  Future<Result<void>> upsertPatient(PatientResponse dto, {required int version}) async {
    await _db.into(_db.patients).insertOnConflictUpdate(PatientsCompanion.insert(
      cachedAt: _now(),  // Clock-injected
      version: Value(version),
      // ...
    ));
  }
}

// Use case — Clock injectable:
class FetchPatientUseCase {
  FetchPatientUseCase({required this.clock, required this.cache, required this.remote, ...});
  final Clock clock;
  
  Future<Result<PatientResponse>> call(String patientId) async {
    final cached = await cache.findById(patientId);
    if (cached.cachedAt + 5min > clock.now()) return Success(cached.dto);
    // refresh...
  }
}

// Test — same FakeClock injected in BOTH layers:
final fakeClock = FakeClock(DateTime(2026, 4, 30, 10, 0));
final cache = DriftPatientsCache(db, now: fakeClock.now);
final useCase = FetchPatientUseCase(cache: cache, clock: fakeClock, ...);

await cache.upsertPatient(patient, version: 1);  // cachedAt = 10:00 (FakeClock)
fakeClock.advance(Duration(minutes: 3));         // now = 10:03
final result = await useCase(patientId);          // 3min < 5min → cache hit (deterministic)
```

**Invariante distribuída:** `cache.cachedAt ≤ useCase.now` é garantida pelo Clock compartilhado.

### Critério de aplicação

**Sempre aplicar** quando duas+ layers compartilham um conceito temporal:
- TTLs (cache, sessions, tokens)
- Expirations (deadlines, scheduled jobs)
- Timestamps comparáveis (created_at vs now)

**NÃO aplicar** quando:
- Uma layer só **passa o timestamp adiante** sem decidir com base nele (ex: API logger registrando `requestId.timestamp`)
- A "decisão temporal" é totalmente local a uma única layer (ex: throttle interno de uma classe)

### Por que importa

Tempo é não-determinístico em testes a menos que você controle. Controlar tempo só na borda de leitura é insuficiente — a borda de escrita também produz timestamps que precisam ser do mesmo Clock.

### Antipattern relacionado

**"Mock só no leitor, não no produtor"** — o `now` do staleness check é mockável, mas o `cachedAt` da escrita é `DateTime.now()` direto. Tests passam às vezes, falham às vezes (depende de sub-millisecond timing). Flaky test que ninguém entende.

---

## H6 — Dart 3 idioms para test infra anti-fallback

### Problema

Tests que substituem dependências (Fakes, Stubs) podem **acidentalmente cair em fallback insidioso** se o autor herdar de uma classe concreta e esquecer de override um método. O teste passa local mas usa comportamento real (DateTime.now real, network call real, etc.) silenciosamente.

### Decisão real (A18b-v2 → A18c-v2, 2026-04-30)

`Clock` em A18b ficou como classe concreta:
```dart
class Clock {
  DateTime now() => DateTime.now();
}

// FakeClock herda:
class FakeClock extends Clock {
  DateTime _fixed;
  @override DateTime now() => _fixed;
}
```

**Risco:** se um dev acidentalmente fizer `super.now()` num `FakeClock` (ex: tentando "alguma coisa híbrida"), retorna `DateTime.now()` real do parent. Test fica não-determinístico silenciosamente.

A18c sweep promove para `abstract interface class` (Dart 3):

```dart
abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();
  @override DateTime now() => DateTime.now();
}

class FakeClock implements Clock {
  // implements (não extends) — não tem super.now() pra cair no fallback
}
```

`abstract interface class` proíbe `extends` — só `implements`. Elimina o bug-trap.

### Critério de aplicação

**Aplicar** sempre que:
- Tests vão substituir o tipo via Fake/Stub
- O tipo tem método com fallback "real" (DateTime.now, http call, file read)
- Vale a pena pagar o pequeno custo (criar `SystemClock` separado da interface)

**NÃO aplicar** quando:
- O tipo é puramente uma data class (sem comportamento substituível)
- Você quer hierarquia real (subclasses com extensão funcional, não substituição de comportamento)

### Por que importa

Bugs de "test passa local mas usa real" são **invisíveis** — não tem stack trace, não tem assertion failure, só dado diferente do esperado. `abstract interface class` torna o erro **impossível em compile-time**.

### Idioms relacionados (Dart 3)

| Modifier | Permite | Bloqueia | Use case |
|---|---|---|---|
| `class` | extends, implements, mixin | nada | default tradicional |
| `abstract class` | extends, implements | instanciação | base com herança esperada |
| `abstract interface class` | implements | extends, instanciação | **contrato puro p/ Fakes** |
| `final class` | implements (no `with`) | extends fora do file | sealed-like sem hierarchy |
| `sealed class` | só dentro do file | extends/implements externo | exhaustive switching (SyncMutation A18a) |

---

## Tabela de decisão "quando aplicar X vs Y"

Consulte rápido durante decisões em PRs:

| Decisão | Sinal | Aplicar |
|---|---|---|
| Surgical refactor (H1) | < 50% dos consumers do contract realmente precisam | ✅ |
| Eager broad refactor (H1 inverso) | É um invariante OU > 80% precisam | ✅ |
| Add `copyWith` na DTO (H2) | Caller observa fields específicos do patch local | ✅ |
| Skip `copyWith` (H2 inverso) | Caller observa só "estado mudou" (version/timestamp) | ✅ |
| Constructor uniformity (H3) | Variantes de um pattern bem definido + forward compat valuable | ✅ |
| Constructor minimalism (H3 inverso) | Variantes não fazem parte de um pattern OU futuro incerto | ✅ |
| Boundary scoping em REGRA cross-cutting (H4) | Regra que se manifesta em N camadas | ✅ Sempre — mapeie quem testa o quê |
| Cross-layer Clock injection (H5) | Duas+ layers compartilham conceito temporal | ✅ Sempre |
| `abstract interface class` (H6) | Tests podem subclassar e bater fallback insidioso | ✅ Dart 3 grátis |

---

## Como adicionar uma nova heurística

Quando uma decisão arquitetural emergir e for repetível, adicione aqui via PR seguindo este template:

```markdown
## H<N> — <Nome curto da heurística>

### Problema
<O trade-off concreto>

### Decisão real (<ticket / data>)
<O que aconteceu, com refs ao código>

### Critério de aplicação
**Aplicar quando:** <bullets>
**NÃO aplicar quando:** <bullets>

### Por que importa
<1-2 parágrafos explicando o custo/benefício>

### Antipattern relacionado
<O erro que essa heurística previne>
```

Atualize a tabela de decisão final e o índice do `principles/README.md` se relevante.

---

## Histórico de evolução

| Data | Ticket | Heurísticas adicionadas |
|---|---|---|
| 2026-04-30 | A18b-v2 close-out | H1, H2, H3, H4, H5, H6 (versão inicial — 6 heurísticas) |
