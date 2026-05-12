# Isolates Opportunity Audit — BFF Comprehensive (2026-05-01)

> **Skill aplicada:** [flutter-expert](../../../.claude/skills/flutter-expert/SKILL.md) com foco em **C1 — `Isolate.run`** da [Concurrency & Performance Policy](../../architecture/CONCURRENCY_AND_PERFORMANCE_POLICY.md).
>
> **Escopo:** mesmas 3 dirs do comprehensive audit (`bff/social_care_desktop/`, `bff/social_care_web/`, `bff/shared/`).
>
> **Foco:** identificar onde Isolates **devem** ou **podem** trazer ganhos em performance, fluidez (UI responsiva), segurança (memory isolation) ou algoritmo. **NÃO** sugerir Isolates onde a regra de C1 desaconselha (overhead > ganho).

---

## Executive summary

| Categoria | Findings |
|---|---:|
| **TIER 1 — High impact, must-fix** | 3 |
| **TIER 2 — Medium impact, recommended** | 3 |
| **TIER 3 — Low impact / future-ready** | 3 |
| **ANTI-PATTERNS — onde NÃO usar Isolate** | 4 |

**Achado mais importante:** ADR-021 (2026-04-30) escolheu Drift sobre Isar **citando explicitamente o suporte a multi-isolate** como vantagem. **A implementação atual não usa isolates** — `NativeDatabase(File(...))` é instanciado na main isolate em `social_care_desktop.dart:697`. Toda operação Drift (cache + sync queue) bloqueia a UI thread. **Isso invalida parcialmente o rationale do ADR-021.**

**Impacto prático em produção (estimado):**
- Listagens de 100+ pacientes: ~50-200ms freeze por scroll/refresh
- Drain de Outbox com 50+ mutations pendentes: ~100-500ms freeze (UI engasga durante sync)
- Audit trail de paciente longo (>500 entries): ~100ms freeze ao abrir tela

**Recomendação prioritária:** A22b (NOVO ticket Onda 4.5) — migrar Drift para `NativeDatabase.createInBackground` em **um único PR**, ganho desproporcional ao esforço.

---

## TIER 1 — High impact (must-fix)

### T1.1 — Drift `NativeDatabase` na main isolate (CRITICAL para fluidez)

**File:** `bff/social_care_desktop/lib/src/facade/social_care_desktop.dart:697`

**Código atual:**
```dart
NativeDatabase _resolveExecutor(String filePath) {
  if (filePath == _kInMemoryMarker) return NativeDatabase.memory();
  return NativeDatabase(File(filePath));  // ← roda na MAIN ISOLATE
}
```

**Problema:**
- `NativeDatabase(File(...))` abre o handle SQLite **diretamente na main isolate**
- Toda query Drift (incluindo as 2 DBs: Cache + SyncQueue) bloqueia o event loop
- Para 9 tabelas × N queries por tela, mesmo queries "rápidas" (5-15ms) somam jank perceptível

**Solução:**
```dart
import 'package:drift/native.dart';

QueryExecutor _resolveExecutor(String filePath) {
  if (filePath == _kInMemoryMarker) return NativeDatabase.memory();
  // Spawns a background isolate that owns the SQLite handle.
  // Main isolate only sends serialized queries via SendPort.
  return NativeDatabase.createInBackground(File(filePath));
}
```

**Custo da mudança:** trivial (1-line API change × 2 sites — Cache DB + SyncQueue DB). Drift abstrai todo o protocolo de mensagens.

**Ganhos:**
- **Performance:** todo SQL roda em isolate paralelo; main isolate só serializa Map → SendPort
- **Fluidez:** UI permanece em 120fps mesmo durante drain de 100+ mutations
- **Segurança:** SQLite handle isolado de heap da UI — atacante com debugger na main isolate não consegue inspecionar transações em vôo
- **ADR-021 compliance:** finalmente honra o motivo declarado para escolher Drift sobre Isar

**Caveat:** transações cross-database (CacheDB + SyncQueue) já estão isoladas fisicamente (memory: feedback `feedback_packages_user_owned.md` separation). Não há atomic commit cross-DB hoje, então mover ambos pra isolates separados não introduz inconsistência nova.

---

### T1.2 — Listagem paginada de pacientes (parsing pesado)

**Files:**
- `bff/social_care_web/lib/src/remote/social_care_api_client.dart:135-145`
- `bff/social_care_desktop/lib/src/remote/registry_remote.dart:38-58`

**Código atual (representativo):**
```dart
return Success(
  PaginatedList(
    data: data
        .cast<Map<String, dynamic>>()
        .map(PatientSummaryResponse.fromJson)  // ← N invocações sync na main isolate
        .toList(),
    meta: PaginationMeta.fromJson(meta),
  ),
);
```

**Problema:**
- `PatientSummaryResponse.fromJson` é gerado por `json_serializable`. Por DTO simples é sub-ms; mas com `limit=100+` (importação, dashboard, search) soma 50-200ms
- Roda **antes** do `return`, ou seja, bloqueia o `await` que o caller fez
- A política C1 cita exatamente esse caso: "Listagem de pacientes (`GET /api/patients` com 100+) — Enriquecimento + mapping pesado"

**Solução:**
```dart
final body = response.data!;  // Map<String, dynamic> sendable

return Success(
  await Isolate.run(() {
    final data = body['data'] as List<dynamic>;
    final meta = body['meta'] as Map<String, dynamic>;
    return PaginatedList(
      data: data
          .cast<Map<String, dynamic>>()
          .map(PatientSummaryResponse.fromJson)
          .toList(),
      meta: PaginationMeta.fromJson(meta),
    );
  }),
);
```

**Quando ativar:** apenas se `limit > ~50` ou se a tela mede jank (use `dart:developer Timeline` em dev mode). Para `limit=20` (default A14), o overhead de spawn (~0.5-2ms) anula o ganho.

**Ganhos:**
- Fluidez ao paginar listas grandes / scroll infinito
- Melhor experiência em "Buscar por nome" (FTS5 retorna até 50 resultados)

---

### T1.3 — Audit trail listing (potencialmente >500 entries)

**File:** `bff/social_care_web/lib/src/remote/social_care_api_client.dart:655-670`

**Código atual:**
```dart
if (response.statusCode == 200) {
  final data = response.data!['data'] as List<dynamic>;
  return Success(
    _wrapResponse(
      data
          .cast<Map<String, dynamic>>()
          .map(AuditTrailEntryResponse.fromJson)  // ← N possivelmente >500
          .toList(),
    ),
  );
}
```

**Problema:**
- `AuditTrailEntryResponse` tem `payload: Map<String, dynamic>?` (não tipado) — `fromJson` para esse tipo é particularmente caro porque preserva map dinâmico
- Audit trail completo de paciente em uso há anos pode ter 1000+ entries
- Tela de auditoria geralmente mostra todas (sem paginação obrigatória) — congelamento perceptível

**Solução:** mesma técnica de T1.2 (`Isolate.run` no decode + map).

**Ganho específico:** UI fica responsiva enquanto auditor inspeciona histórico longo. Útil para compliance LGPD onde auditor pode precisar examinar prontuário inteiro.

---

## TIER 2 — Medium impact (recommended)

### T2.1 — `getLookupsBatch` fan-out aggregate parsing

**File:** `bff/social_care_desktop/lib/src/remote/lookup_remote.dart:55-79`

**Padrão atual:** já usa `Future.wait` para paralelismo HTTP — bom! Mas o **agregado** dos resultados (`Map<String, List<LookupItemResponse>>`) é montado na main isolate.

**Problema sutil:**
- Lookup tables podem ter centenas de items (ex: `municipios_brasil` com 5570)
- 13 tables × 100-1000 items = 13k+ DTOs decodificados em sequência **após** `Future.wait`
- Esse passo final é onde a main isolate engasga — todo o paralelismo HTTP foi perdido no aggregate

**Solução:**
```dart
final results = await Future.wait(tables.map((t) => _client.getLookupTable(t)));

// Aggregate em isolate — separa HTTP parallel do CPU parallel
return Isolate.run(() {
  final tables = <String, List<LookupItemResponse>>{};
  for (var i = 0; i < results.length; i++) {
    if (results[i] case Success(:final value)) {
      tables[tableNames[i]] = value.data;
    } else {
      // ... preserva failure pattern
    }
  }
  return Success(LookupsBatchResponse(tables: tables));
});
```

**Ganho:** carregamento inicial de lookups (login → "Cadastrar paciente") é a tela mais sensível a freeze; usuário percebe logo.

---

### T2.2 — Cache batch reads (listSummaries / listAuditByPatient)

**Files:**
- `bff/social_care_desktop/lib/src/cache/impls/drift_patients_cache.dart:88-120` (listSummaries / searchSummaries)
- `bff/social_care_desktop/lib/src/cache/impls/drift_audit_cache.dart` similar

**Padrão atual:**
```dart
final rows = await _dao.listSummaries(...);  // já é async (Drift)
return Success(
  rows.map((r) => Cached(
    dto: PatientSummaryResponse.fromJson(jsonDecode(r.payload) as Map<String, dynamic>),
    cachedAt: r.cachedAt,
    version: r.version,
  )).toList(),
);
```

**Problema:** `jsonDecode` + `fromJson` por row, todos na main isolate **depois** do await Drift. Se T1.1 (Drift no isolate) for aplicado, a query roda paralelo mas o decode volta pra main.

**Solução:** Esse fix se torna trivial **depois** de T1.1. Drift pode opcionalmente serializar tipos custom já no isolate. Alternativa: aplicar `Isolate.run` no `.map(...)` quando `rows.length > 50`.

**Pré-requisito:** T1.1 primeiro. Sem isolated executor, esse fix sozinho ainda deixa as queries SQL na main thread.

---

### T2.3 — SyncEngine drain batch parsing (offline → online recovery)

**File:** `bff/social_care_desktop/lib/src/sync/engine/sync_engine.dart` (drain logic)

**Cenário:** usuário ficou 4 horas offline preenchendo 50 fichas + 20 appointments. Conectividade volta → SyncEngine drena 70+ mutations em sequência.

**Padrão atual:**
- Cada mutation é deserializada via `SyncMutation.fromOutboxEntry` (sealed switch)
- Cada deserialização envolve `Dto.fromJson(payload)` na main isolate
- 70 mutations × ~1ms = 70ms somente de deserialização + N HTTP roundtrips
- Durante esse tempo a UI engasga (especialmente o sync indicator que está sendo atualizado)

**Solução:**
```dart
// Em SyncEngine._dispatch, antes de chamar o sub-contract:
final mutation = await Isolate.run(
  () => SyncMutation.fromOutboxEntry(entry),  // sealed switch + fromJson
);
final result = await _dispatchToContract(mutation);  // HTTP roundtrip
```

**Caveat — sealed class sendable:** `SyncMutation` final classes precisam ser **sendable** (sem closures, sem references a Dio/Engine). Verificar se as 27 final classes têm apenas campos simples. Se sim, é trivial. Se alguma tem ref a closure/dependency, refator menor.

**Ganho:** UI não engasga durante sync recovery — usuário pode continuar trabalhando.

---

## TIER 3 — Low impact / future-ready

### T3.1 — CPF/NIS mod 11 validation em batch import (futuro)

**Files:** `bff/shared/lib/src/domain/kernel/cpf.dart`, `nis.dart`

**Estado atual:** `_isValidCpfMod11` / `_isValidNisMod11` são sub-ms (10 dígitos × 2 weights × 1 digit). **Não vale Isolate por chamada.**

**Quando vira candidato:**
- Phase 5+ vai precisar de **importação massiva de CPFs** (planilhas Excel de cadastro de migração)
- 10k CPFs × ~0.5ms = 5s freeze. Aí sim:

```dart
Future<List<Result<Cpf, CpfError>>> validateBatch(List<String> rawValues) =>
    Isolate.run(() => rawValues.map(Cpf.create).toList());
```

**Marcar como follow-up Phase 5** quando bulk import for priorizado.

---

### T3.2 — JWT signature verification (futuro — quando A22 wirear OIDC real)

**File:** `bff/social_care_web/lib/src/auth/oidc_server_client.dart` (quando wirear de verdade — hoje é fake)

**Quando vira candidato:**
- A22 (Onda 4.5) vai implementar JWT validation real via JWKS
- ECDSA/RS256 signature verification é CPU-bound crypto (5-20ms por token)
- Em backend Dart (BFF Web servindo múltiplos clients), N tokens/sec → bottleneck

**Solução prevista:**
```dart
// Em A22:
Future<Result<JwtClaims>> verifyToken(String token) =>
    Isolate.run(() => _verifySignatureAndClaims(token, _jwks));
```

**Bonus segurança:** crypto state isolado em isolate dedicada — atacante com acesso ao server process tem janela menor para extrair JWKS keys do heap principal.

**Não-blocker para A22**, mas flag pra ser feito como parte do design original.

---

### T3.3 — PDF/relatório generation (futuro)

**Cenário esperado em Phase 5+:** geração de relatórios de prontuário em PDF (exigência de compliance LGPD para data portability + impressão para profissionais).

**Por que Isolate:**
- Renderização PDF (`pdf` package) é puramente CPU-bound
- Documento de prontuário completo = 20-50 páginas com tabelas, gráficos, fotos
- Geração pode levar 1-5 segundos — congelaria UI inteira

**Pattern recomendado quando implementar:**
```dart
Future<Uint8List> generatePatientReport(PatientResponse patient) =>
    Isolate.run(() => _renderPdf(patient));  // todo o pdf package roda isolado
```

**Marcar como NICE_TO_KNOW** quando feature for priorizada — flutter-expert skill já anticipa esse caso.

---

## ANTI-PATTERNS — onde NÃO usar Isolate

### A1 — `_toJsonClean` per-mutation enqueue
**File:** `bff/social_care_desktop/lib/src/sync/outbox/sync_mutation.dart:14`

```dart
Map<String, dynamic> _toJsonClean(Map<String, dynamic> raw) =>
    jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
```

**Por que NÃO isolar:**
- Chamada de **uma** mutation pequena: ~0.1-0.5ms
- Isolate spin-up: ~0.5-2ms
- Net: 2-5x **mais lento** com isolate
- Política C1: "não vale a pena para listas < 50 items ou parsing sub-10ms"

**Quando reconsiderar:** se cenário **batch enqueue** existir (importação massiva via UI), aí sim agrupar e fazer 1 isolate hop para todas. Hoje não há esse padrão.

---

### A2 — Cache impl single-row read/upsert (`findById`, `upsertPatient`)
**Files:** `drift_patients_cache.dart` linhas 39-70 (findById), 135-155 (upsert)

**Por que NÃO isolar:**
- Single-row decode é sub-ms
- `await _ready` + Drift query (sub-ms) + jsonDecode (sub-ms) já é dentro do orçamento de 16ms (60fps)
- Wrap em Isolate adiciona overhead sem ganho perceptível

**Tier 2 (T2.2) já cobre o caso onde isolate FAZ sentido (batch reads).**

---

### A3 — Per-handler request body parsing (web BFF)
**Files:** `bff/social_care_web/lib/src/intents/*.dart` (parseFromBody helpers)

**Por que NÃO isolar:**
- Handlers web recebem request body geralmente **pequeno** (≤10KB típicos — RegisterPatientRequest é o maior, ~3KB)
- Parse é sub-ms
- BFF web é multi-request server — isolate por request quebra o modelo de event loop do shelf
- C2 (class modifiers) é o mecanismo correto pra isolar bounded contexts no BFF web, não C1

**Exceção que confirma a regra:** se algum dia houver upload de arquivo / batch CSV no BFF web, aí sim isolate para o parse desse blob específico.

---

### A4 — Connectivity event handling
**File:** `bff/social_care_desktop/lib/src/facade/social_care_desktop.dart` (connectivity listener)

**Por que NÃO isolar:**
- Listener processa 1 evento por vez (offline ↔ online transition)
- Lógica é if-statement + setter de bool — nanossegundos
- Trigger de drain é fire-and-forget — já desacoplado da UI
- Wrap em isolate seria cargo-cult

---

## Tabela de decisão "Isolate ou não?"

Critérios para greenfield em qualquer ponto do BFF:

| Sinal | Decisão |
|---|---|
| Operação > 10ms na main isolate | **Sim, Isolate** |
| List/batch processing > 50 items | **Sim, Isolate** |
| CPU-bound crypto (JWT, PDF, hash) | **Sim, Isolate** |
| Drift database — em qualquer escala | **Sim, IsolatedExecutor** (T1.1) |
| Single async I/O wait (HTTP, file read) | **Não** — `await` já desbloqueia |
| Single small parse (<10ms) | **Não** — overhead anula ganho |
| Single-row DB read/write | **Não** — sub-ms |
| Event handler com lógica leve | **Não** — overhead inútil |
| Batch operation que pode ser agrupado | **Sim, agrupar e isolar 1x** |
| Operação que captura closure com Dio/Service | **Não** — não é sendable; refator primeiro |

---

## Action items para tickets

### Onda 4.5 (Security Hardening) — adicionar ao escopo

**A22b (NOVO — entra com A22 ou logo em sequência):**
- Migrar `NativeDatabase(File(...))` → `NativeDatabase.createInBackground(File(...))` em `social_care_desktop.dart:697`
- Aplicar para Cache DB + SyncQueue DB (2 sites)
- Validar: `flutter test bff/social_care_desktop/` continua 420/420 GREEN
- Smoke perf test: drain 100 mutations não causa frame drops (use `dart:developer Timeline`)

**Custo estimado:** 1 hora pipeline (1 ticket 3-agent leve)
**Ganho:** elimina toda a categoria "DB op freezes UI" — desproporcional ao esforço

### Onda 5 (gate final) — adicionar ao escopo

**A21d (NOVO):**
- Aplicar Isolate.run nos 3 hot paths de listing:
  - `social_care_api_client.dart:135-145` (fetchPatients)
  - `social_care_api_client.dart:655-670` (audit trail)
  - `lookup_remote.dart:55-79` (lookups batch aggregate)
- Threshold guard: `if (data.length > 50) Isolate.run(...) else inline` para evitar overhead em payloads pequenos

**Custo estimado:** 1.5 horas (3 sites + tests assert behavior preservation)

### Phase 5+ (futuro)

- T3.1 CPF/NIS batch validation (quando bulk import for priorizado)
- T3.2 JWT verification em isolate (durante implementação real do A22 OIDC)
- T3.3 PDF report generation (quando feature for priorizada)

### Phase 4 (user-driven, não propor agora)

- Não tocar `packages/` (constraint do user)
- Quando user atacar Phase 4, considerar: ViewModels com listas grandes podem aplicar Isolate.run no parse final
- Flutter-expert skill C1 já tem orientação para Flutter UI layer — aplicará naturalmente

---

## Cross-reference

- **Política base:** [`handbook/architecture/CONCURRENCY_AND_PERFORMANCE_POLICY.md`](../../architecture/CONCURRENCY_AND_PERFORMANCE_POLICY.md) — C1, C2, C3
- **ADR-021:** [Drift supersede Isar](../../architecture/DECISIONS.md) — citou isolates como motivo, mas implementação não usa (T1.1)
- **Decision Heuristics:** [`handbook/principles/DECISION_HEURISTICS.md`](../../principles/DECISION_HEURISTICS.md) — H1 (surgical refactor) aplicável a esse audit: aplicar Isolates só onde política indica, não uniformemente
- **Comprehensive audit summary:** [`SUMMARY.md`](./SUMMARY.md) — esse arquivo é addendum focado

---

## Métricas

- Files audited: 32 com `jsonDecode/jsonEncode` em produção (excluindo tests + .drift.dart)
- Hot paths identificados: 9 (3 must-fix, 3 recommended, 3 future)
- Anti-patterns flagados: 4 (onde Isolate é desnecessário)
- Net effort estimado: ~3-4 horas de pipeline para T1.1 + T1.2/3 + T2.1
- Ganho esperado em fluidez: eliminação de ~100-500ms freezes em 3 cenários de uso comum (listing, audit, sync recovery)
