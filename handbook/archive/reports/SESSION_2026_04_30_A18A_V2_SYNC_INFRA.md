# Sessão 2026-04-30 — A18a-v2: Desktop Sync Infrastructure (Outbox + Engine)

> **Sub-ticket:** A18a-v2 (Onda 4 / Fase 3 BFF Contract A — split A18-v2 em 3 sub-tickets)
> **Pipeline:** 3-agent BFF (test-writer → flutter-bff-implementer → flutter-code-reviewer)
> **Commit:** `86d28a8` — `feat(bff/desktop): A18a-v2 — sync infrastructure (Outbox + 27 mutations + Engine)`
> **Resultado:** APPROVED Round 1, zero MUST_FIX, 52/52 sync tests GREEN, full BFF Desktop suite 286/286 GREEN, dart analyze 0 issues.
> **Próximo:** A18b-v2 (use cases — ~42 orchestrators)

## O que foi feito

### 1. Re-baseline — A18-v2 splitado em 3 sub-tickets sequenciais

A18 original era "sync only" mas o re-baseline da Onda 4 expandiu para incluir use_cases + facade. Após análise de escopo, **splitado em 3 sub-tickets** para preservar atomicidade e revisão granular:

| Sub-ticket | Layer | LoC | Files | Tests | Status |
|---|---|---:|---:|---:|---|
| **A18a-v2** | Sync infra (Database + Queue + Engine) | 1824 | 8 + 2 codegen | 52 | **CLOSED 2026-04-30** |
| A18b-v2 | Use cases (~42 orchestrators) | ~2000 | ~42 | ~120 | queued |
| A18c-v2 | Facade + apps/acdg_system/ rewire | ~600 | ~8 + 7 shell rewires | ~30 | queued |

Cada sub-ticket roda 3-agent pipeline self-contained com revisão intercalada.

### 2. Cross-cutting decisions locked (2026-04-30)

Todas as 8 decisões arquiteturais aprovadas pelo usuário ANTES do dispatch (alinhamento prévio Architect-grade):

| # | Decisão | Escolha | Rationale |
|---|---|---|---|
| **D1** | Optimistic locking | (a) forward-compat header | Custo zero, prepara backend futuro sem coordenação |
| **D2** | Conflict resolution | (B) manual reconciliation | Healthcare data — fail-safe; auto-merge é evolução |
| **D3** | DB file paths | path_provider defaults + override param | Convenção; flexível pra testes |
| **D4** | SyncEngine lifecycle | (α) app-controlled | Match natural OIDC flow |
| **D5** | Drain concurrency | (γ) trigger-based | Sem Timer.periodic ociosa; isolate como evolução |
| **D6** | Shell rewire validation | flutter analyze + tests existentes | Pragmatic; integration tests via Phase 6+ |
| **REGRA #2** | 4 ambiguities antecipadas | aceitar todas as propostas | Stale=5min, no rollback, FIFO, índice CPF como follow-up |

### 3. Estrutura final do `lib/src/sync/`

```
bff/social_care_desktop/lib/src/sync/
├── _shared/
│   ├── sync_database.dart            — @DriftDatabase MIGRATION-PROTECTED + header docstring
│   ├── sync_database.drift.dart      — codegen
│   ├── failures.dart                  — SyncFailure (mirror de CacheFailure)
│   └── tables/
│       ├── outbox_table.dart          — 11 cols + composite index (status, createdAt)
│       └── outbox_table.drift.dart    — codegen
├── outbox/
│   ├── sync_mutation.dart             — sealed + 27 final classes (989 LoC)
│   └── outbox_repository.dart         — abstract + DriftOutboxRepository (302 LoC)
└── engine/
    ├── sync_engine.dart               — drain logic + 27-arm sealed switch (293 LoC)
    ├── retry_policy.dart              — exp backoff capped (44 LoC)
    └── conflict_resolver.dart         — error → SyncDecision (69 LoC)
```

**Total:** 8 impl files (1824 LoC) + 2 codegen artifacts.

### 4. Separação física de bancos de dados (CRÍTICO)

**Invariante arquitetural pinada:**

| Database | Arquivo | Propriedade | Conteúdo |
|---|---|---|---|
| `CacheDatabase` (A17) | `app_cache.sqlite` | Droppable | Read Models (DTO projections) — re-buscáveis do backend |
| `SyncDatabase` (A18a) | `app_sync_queue.sqlite` | **MIGRATION-PROTECTED** | Outbox de mutations offline pendentes — perda = **Data Loss** |

**Header docstring obrigatório** em `sync_database.dart:1-9`:

```dart
/// Sync Database — MIGRATION-PROTECTED. Holds the Outbox of pending
/// mutations that have NOT yet been acknowledged by the backend.
///
/// CRITICAL: This database lives in a physically SEPARATE .sqlite file
/// from CacheDatabase (`app_sync_queue.sqlite` vs `app_cache.sqlite`).
/// A drop+recreate of the cache is safe (re-fetched from backend);
/// a drop of THIS database = Data Loss of offline mutations.
///
/// Schema changes here MUST be versioned via MigrationStrategy.
/// Increment `schemaVersion` and add migration steps; NEVER drop tables.
library;
```

**Verificação:** `grep -rn` confirma zero cross-imports `cache/` ↔ `sync/`. Apenas docstrings cruzadas (warnings recíprocos pra clareza).

### 5. Outbox table — schema + composite index

```dart
@TableIndex(name: 'outbox_status_created_idx', columns: {#status, #createdAt})
class Outbox extends Table {
  TextColumn get id => text()();                     // PK, UUID v4 (idempotência)
  TextColumn get aggregateType => text()();          // 'patient' | 'appointment' | ...
  TextColumn get aggregateId => text()();
  TextColumn get mutationType => text()();           // discriminator (27 valores)
  TextColumn get payload => text()();                // JSON-blob (Map<String, dynamic>)
  IntColumn get expectedVersion => integer()();      // optimistic locking (D1 forward-compat)
  DateTimeColumn get createdAt => dateTime()();      // FIFO ordering
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();   // dead-letter inspection
  TextColumn get status => text()();                 // pending|in_flight|failed_retriable|failed_dead|completed
  @override Set<Column> get primaryKey => {id};
}
```

**Composite index `(status, createdAt)`** com `status` primeiro permite SQLite servir a query `WHERE status='pending' ORDER BY createdAt ASC LIMIT N` em **O(log N)** sem sort step. Drain otimizado.

### 6. SyncMutation — sealed class de 27 mutations

Hierarchy: 1 base `sealed class SyncMutation` + **27 final classes** mapeando 1:1 com write methods dos sub-contracts:

| Bounded Context | Mutações | Quantidade |
|---|---|---:|
| Registry | RegisterPatient, AddFamilyMember, RemoveFamilyMember, AssignPrimaryCaregiver, UpdateSocialIdentity, DischargePatient, ReadmitPatient, AdmitPatient, WithdrawPatient | 9 |
| Assessment | UpdateHealthStatus, UpdateHousingCondition, UpdateEducationalStatus, UpdateSocioEconomicSituation, UpdateWorkAndIncome, UpdateCommunitySupportNetwork, UpdateSocialHealthSummary | 7 |
| Care | RegisterAppointment, UpdateIntakeInfo | 2 |
| Protection | UpdatePlacementHistory, ReportViolation, CreateReferral | 3 |
| Lookup | CreateLookupItem, UpdateLookupItem, ToggleLookupItem, CreateLookupRequest, ApproveLookupRequest, RejectLookupRequest | 6 |
| **Total** | | **27** |

**Audit, Health: zero mutations** (read-only contexts).

**Compiler-enforced exhaustiveness** via switch sobre o sealed:

```dart
factory SyncMutation.fromOutboxEntry(OutboxEntry entry) => switch (entry.mutationType) {
  'register_patient' => RegisterPatientMutation.fromPayload(entry),
  'discharge_patient' => DischargePatientMutation.fromPayload(entry),
  // ... 25 mais — exhaustive
  _ => throw StateError('Unknown mutationType: ${entry.mutationType}'),
};
```

**Discriminadores em lowercase snake_case** (resolução da open question 2 do W0).

**3 mutations path-only** (sem `request` field, payload `{}`):
- `AdmitPatientMutation` — `admitPatient(String patientId)` no body
- `ApproveLookupRequestMutation` — `approveLookupRequest(String requestId)` no body
- `RejectLookupRequestMutation` — `rejectLookupRequest(String requestId)` no body

**1 mutation com `memberId: String`** (não DTO): `RemoveFamilyMemberMutation` — `removeFamilyMember(patientId, memberId)` two-path-segment.

**3 mutations com `tableName: String` + `request: <Dto>`**: lookup admin (`Create/Update/ToggleLookupItem`).

### 7. SyncEngine — state machine + sealed-switch dispatch

```
[pending] ─pickup─→ [in_flight] ─success─→ [completed]
                          │ ├─409/OPTIMISTIC_LOCK_CONFLICT─→ [failed_dead]   ← D2 (B): manual reconciliation
                          │ ├─5xx/network─────────────────→ [failed_retriable] ──RetryPolicy──→ [pending]
                          │ └─4xx other───────────────────→ [failed_dead]
```

**Dispatch via sealed-class switch** (compiler enforça os 27 cases):

```dart
Future<Result<void>> _dispatch(SyncMutation m) async => switch (m) {
  RegisterPatientMutation() => _voidOnId(await _registry.registerPatient(m.request)),
  AdmitPatientMutation() => _registry.admitPatient(m.aggregateId),
  RemoveFamilyMemberMutation() => _registry.removeFamilyMember(m.aggregateId, m.memberId),
  // ... 24 mais — adicionar 28ª mutation requer atualizar switch (compile-time error)
};
```

**Helpers `_voidOnId` e `_voidOnStandard`** descartam `StandardIdResponse` / `StandardResponse<void>` para que cada arm retorne `Result<void>`. Preservam `error` + `stackTrace` em falhas.

### 8. Single-flight drain

```dart
Future<Result<DrainSummary>>? _inFlight;

Future<Result<DrainSummary>> triggerDrain() {
  if (_inFlight != null) return _inFlight!;       // concurrent triggers share the Future
  if (!_started) return Future.value(Success(DrainSummary(processed: 0, ...)));
  if (_closed) return Future.value(Failure(SyncFailure('SyncEngine closed')));
  
  return _inFlight = _drainImpl().whenComplete(() => _inFlight = null);
}
```

**Pre-`start()` drain** retorna `Success(DrainSummary(processed: 0))` e **não toca a queue** — segurança contra calls antes do app estar pronto.

**Post-`close()` drain** retorna `Failure(SyncFailure)` — bloqueia operações em engine fechado.

**FIFO ordering** garantido por `OutboxRepository.listByStatus(pending, ...)` que retorna entries ordenadas por `createdAt ASC`.

### 9. RetryPolicy — exp backoff capped

```dart
Duration nextDelay(int attemptCount) {
  final exponent = math.min(attemptCount, 30);   // defensive overflow protection
  final seconds = math.pow(2, exponent).toInt();
  final ms = seconds * 1000;
  return Duration(milliseconds: math.min(ms, maxDelay.inMilliseconds));
}

bool shouldRetry(int attemptCount) => attemptCount < maxAttempts;  // default max 10
```

**Curva:** 1s, 2s, 4s, 8s, 16s, 32s, 64s, 128s, 256s, 512s, 1024s, 30min (capped).

### 10. ConflictResolver — error → SyncDecision

```dart
SyncDecision decide(Object error) {
  if (error is BackendErrorResponse) {
    final http = error.error.http;
    if (http == 409) return DeadDecision('OPTIMISTIC_LOCK_CONFLICT: ...');  // D2 (B)
    if (http >= 500) return RetriableDecision('Server error $http: ...');
    if (http >= 400) return DeadDecision('Client error $http: ...');
  }
  if (error is DioException) return RetriableDecision('Network: ...');
  return RetriableDecision('Unknown: $error');                                // conservative
}
```

**`SyncDecision` é sealed** com 3 finais: `CompletedDecision`, `RetriableDecision`, `DeadDecision`.

### 11. REGRA #2 — `_toJsonClean` normalizer (resolvido sem alterar testes)

**Problema:** `OutboxEntry.payload: Map<String, dynamic>` é o contrato. `json_serializable`'s default `toJson()` é **shallow** — DTOs aninhados (ex: `DiagnosisDraftDto` dentro de `RegisterAppointmentRequest`) ficam como instâncias Dart, não viram `Map<String, dynamic>` recursivo. Tests que constroem `OutboxEntry` direto via `m.toPayload()` (bypassando o SQL TEXT round-trip de produção) falham com `type 'DiagnosisDraftDto' is not a subtype of type 'Map<String, dynamic>'`.

**4-point analysis:**
- **Intenção:** payload do Outbox honra o contrato `Map<String, dynamic>` recursivo.
- **Falha:** json_serializable shallow + nested DTOs.
- **Veredito:** **violação de contrato em produção**, não bug de teste. Test pega real foot-gun pra futuros consumers de `payload`.
- **Resolução (impl-side):** `_toJsonClean(Map)` faz `jsonDecode(jsonEncode(map))` em `toPayload()` time. Honra contrato literalmente, sem alterar tests.

**Não é test cheating** — é proteção de contrato. Reviewer aprovou. Documentado inline em `sync_mutation.dart:7-15`.

### 12. Pubspec — novas dependências

```yaml
dependencies:
  drift: ^2.31.0                # já presente (A17)
  sqlite3_flutter_libs: ^0.5.28 # já presente (A17)
  path_provider: ^2.1.0         # NOVO (D3 default file paths)
  connectivity_plus: ^7.0.0     # NOVO (D5 γ — listener para trigger drain)
```

**Bump `connectivity_plus: ^6 → ^7`** justificado pelo constraint solver: `packages/network` pina `^7.0.0`. Aceito como pragmatic bump.

### 13. Testes — 52 RED → 52 GREEN

```
flutter test test/sync/
00:00 +52: All tests passed!

flutter test (full BFF Desktop)
00:01 +286: All tests passed!
```

Por arquivo:
- outbox_repository_test: 13/13 (CRUD + state transitions)
- sync_mutation_test: 12/12 (sealed round-trip + 27 discriminators)
- sync_engine_test: 11/11 (drain state machine + single-flight + FIFO)
- retry_policy_test: 9/9 (exp backoff math)
- conflict_resolver_test: 7/7 (error → decision mapping)

**Full BFF Desktop suite (cache + remote + sync):** **286/286 GREEN** — zero regressão A16-v2 / A17-v2.

### 14. Library exports

```dart
// lib/social_care_desktop.dart
export 'src/sync/_shared/failures.dart' show SyncFailure;
export 'src/sync/outbox/sync_mutation.dart';                       // sealed + 27 finals
export 'src/sync/outbox/outbox_repository.dart' show OutboxRepository, OutboxEntry, OutboxStatus;
export 'src/sync/engine/sync_engine.dart' show SyncEngine, DrainSummary;
export 'src/sync/engine/retry_policy.dart' show RetryPolicy;
export 'src/sync/engine/conflict_resolver.dart' show ConflictResolver, SyncDecision, ...;
```

`DriftOutboxRepository` e `SyncDatabase` permanecem **library-private** — A18c facade vai instanciar.

## Decisões pinadas (consequência operacional)

1. **Outbox Pattern + Read Model separation.** Cache armazena projection (read model); Outbox armazena intent (mutation). Não misturar.
2. **Database files são separados fisicamente.** Drop de cache é safe; drop de Outbox = Data Loss. Header docstring documenta.
3. **27 mutations sealed-class é o canonical pattern para CQRS no monorepo.** Compiler enforça exhaustividade. Adicionar 28ª mutation no futuro requer touching todo switch — by design.
4. **Conflict resolution conservadora.** Auto-merge volta como evolução, não como default. Healthcare data first.
5. **Optimistic locking forward-compat.** Header `expectedVersion` enviado mesmo que backend ignore. Frontend pronto pra concurrency control quando backend implementar.
6. **`_toJsonClean` é o pattern para JSON-blob normalization no monorepo.** Generaliza para qualquer Outbox-like com nested DTOs.

## Pipeline 3-agent — performance

| Wave | Agente | Saída | Tempo aprox. |
|---|---|---|---|
| W0 | test-writer | 52 RED tests + locked contracts + 3 open questions | ~10 min |
| W1 | flutter-bff-implementer | 8 impl + 2 codegen + 1 REGRA #2 resolvida | ~14 min |
| W2 | flutter-code-reviewer | Auditoria 14 checks, APPROVED Round 1 | ~4 min |

**Round 1 sem rejeição** — quarto ticket consecutivo (A15, A16-v2, A17-v2, A18a-v2). Pipeline maturado.

## Insights não-óbvios capturados

1. **Pattern: Database isolation by mutability.** Read Models (cache) vs Mutations (outbox) → arquivos `.sqlite` separados. Generaliza além do desktop.

2. **Pattern: `_toJsonClean` for nested DTO contracts.** `jsonDecode(jsonEncode(...))` round-trip é o canon para honrar `Map<String, dynamic>` recursivo contra json_serializable shallow `toJson`.

3. **Pattern: Sealed-class state machine + compiler-enforced switch.** SyncEngine drain dispatch sobre 27 mutations sem possibilidade de regression silenciosa. Adicionar 28ª = compile error.

4. **Pattern: Single-flight async via shared Future.** `_inFlight` Future shared evita double-dispatch sem mutex/lock. Generalizable para qualquer drain/refresh logic.

5. **Pattern: Composite B-Tree index match para query plan O(log N).** `(status, createdAt)` com status primeiro permite SQLite servir `WHERE status=? ORDER BY createdAt ASC` sem sort step. Generalizable para qualquer outbox/queue table.

## Próximos passos (Onda 4 — em fechamento)

- **A18b-v2 (use cases — ~42 orchestrators):**
  - Read use cases: cache-first (5min stale threshold) + write-through refresh.
  - Write use cases: optimistic write-through + enqueue mutation + trigger drain.
  - Sem state global; tudo via constructor injection.
  - REGRA #2 antecipadas relevantes aqui: stale threshold, optimistic write rollback, concurrent writes ao mesmo aggregate, lookups por chaves alternativas.

- **A18c-v2 (facade pública + shell rewire):**
  - `SocialCareDesktop.create()` factory com path_provider defaults.
  - 7 sub-facades organizadas por bounded context.
  - `startSync()`/`stopSync()`/`close()` controlados pelo app (D4 α).
  - `connectivity_plus` listener wireado pra trigger drain on restore.
  - Rewire de 7 arquivos do `apps/acdg_system/`: providers + sync_detail_panel + integration test.

- **Onda 5 (gate final A19-A21):** após A18 fechado, dart analyze bff/ zero, atualizar `handbook/architecture/CONTRACT_A_PUBLIC_API.md`, deletar resto de código legado.

## Follow-ups identificados (não-bloqueantes)

- **`markFailedRetriable` race em concurrent producers** — single-flight drain protege hoje; A18b adiciona write use cases que fazem enqueue durante drain. Wrap em Drift `transaction` se observar inconsistência. NICE_TO_HAVE flagado pelo W2.
- **`_toJsonClean` performance** — `jsonDecode(jsonEncode(...))` em todo `toPayload()`. Healthcare-scale rates fazem isso irrelevante; profiling marker se A18b throughput tests mostrarem hot path.
- **Backend `If-Match`/`expectedVersion`** — frontend já envia header; backend Swift/Vapor pode adotar concurrency control quando Phase 6+ priorizar.
- **Drift indexação por chaves alternativas (CPF)** — flagado pelo usuário como radar. Adicionar `@TableIndex` quando A18b descobrir use case.
- **Background isolate para SyncEngine (D5 β)** — evolução se medirmos UI jank em produção.
