# Sub-ticket State: A18b-v2-use-cases (BREAK CHANGE)

phase: tdd-red (test-writer dispatched 2026-04-30)
parent: A18-desktop-sync (sub-ticket 2 de 3)
status: W0 RED in progress

## Scope (A18b-v2 only)

Constrói a **camada de orquestração** — ~42 use cases organizados por 7 bounded contexts. Cada use case orquestra cache + remote + queue seguindo um de 3 patterns canônicos.

**FORA do escopo:** SyncDatabase / Outbox / SyncEngine / mutations (A18a closed); facade pública (A18c); shell rewire (A18c).

## Target structure

```
bff/social_care_desktop/lib/src/use_cases/
├── _shared/
│   ├── stale_policy.dart                    — StalePolicy + isStale(cachedAt, threshold)
│   ├── version_extractor.dart                — extractVersion(StandardResponse) helper
│   └── use_case_failures.dart                — NotFoundFailure + UseCaseFailure
├── registry/                                 — 13 use cases (4 reads + 9 writes)
├── assessment/                                — 7 use cases (all writes)
├── care/                                      — 3 use cases (1 read + 2 writes)
├── protection/                                — 6 use cases (3 reads + 3 writes)
├── audit/                                     — 1 use case (read with filters)
├── lookup/                                    — 10 use cases (4 reads + 6 writes)
└── health/                                    — 2 use cases (passthroughs)
```

**Total: 42 use cases.**

## Patterns canônicos (3)

### Pattern 1 — Read use case (cache-first, write-through refresh)

```dart
class FetchPatientUseCase {
  FetchPatientUseCase({
    required this.cache,
    required this.remote,
    this.staleAfter = const Duration(minutes: 5),  // configurable per use case
  });
  final PatientsCache cache;
  final RegistryContract remote;
  final Duration staleAfter;
  
  Future<Result<PatientResponse>> call(String patientId) async {
    final cached = await cache.findById(patientId);
    if (cached case Success(:final value?)) {
      // CachedAt is on the OutboxEntry-like wrapper, NOT on PatientResponse itself.
      // Cache impl must expose cachedAt (A17 row already has it).
      // Test: if !isStale(value.cachedAt) => return cached; else => refresh
      if (!_isStale(value.cachedAt)) return Success(value.dto);
    }
    final fresh = await remote.fetchPatient(patientId);
    return switch (fresh) {
      Success(:final value) async {
        await cache.upsertPatient(value.data, version: extractVersion(value));
        return Success(value.data);
      },
      Failure() => fresh.cast(),
    };
  }
  
  bool _isStale(DateTime cachedAt) =>
    DateTime.now().difference(cachedAt) > staleAfter;
}
```

**Note:** A17 cache contracts return DTOs not `Cached<T>` wrappers. The use case needs `cachedAt` to compute staleness. **Either** (a) cache returns `Cached<T>` wrapper, **or** (b) cache exposes `findByIdWithMeta` returning DTO + cachedAt. The test-writer will propose ONE option in W0; implementer can challenge.

### Pattern 2 — Write use case (optimistic write-through + enqueue + trigger drain)

```dart
class DischargePatientUseCase {
  DischargePatientUseCase({
    required this.cache,
    required this.outbox,
    required this.engine,
    Uuid? uuid,
    Clock? clock,
  });
  final PatientsCache cache;
  final OutboxRepository outbox;
  final SyncEngine engine;
  final Uuid _uuid;     // for mutation.id generation
  final Clock _clock;   // for createdAt
  
  Future<Result<void>> call(String patientId, DischargePatientRequest req) async {
    // 1. Read cached version (for expectedVersion in mutation)
    final cachedResult = await cache.findById(patientId);
    if (cachedResult case Failure()) return cachedResult.cast();
    final cached = (cachedResult as Success).value;
    if (cached == null) return Failure(NotFoundFailure('Patient $patientId not in cache'));
    
    // 2. Build mutation
    final mutation = DischargePatientMutation(
      id: _uuid.v4(),
      aggregateId: patientId,
      expectedVersion: cached.version,
      createdAt: _clock.now(),
      request: req,
    );
    
    // 3. Enqueue (Outbox first — durable record before optimistic update)
    final enqueueResult = await outbox.enqueue(mutation);
    if (enqueueResult case Failure()) return enqueueResult.cast();
    
    // 4. Optimistic cache update (apply locally before backend ack)
    final patched = cached.dto.copyWith(status: 'discharged');  // domain-specific patch
    await cache.upsertPatient(patched, version: cached.version + 1);
    
    // 5. Trigger drain (fire-and-forget; SyncEngine drains async)
    unawaited(engine.triggerDrain());
    
    return const Success(null);
  }
}
```

**Order matters:** enqueue BEFORE optimistic cache update. If enqueue fails, cache is untouched. If optimistic update fails after enqueue, mutation still drains and backend wins.

### Pattern 3 — Health passthrough (no cache, no queue)

```dart
class CheckHealthUseCase {
  CheckHealthUseCase({required this.remote});
  final HealthContract remote;
  Future<Result<void>> call() => remote.checkHealth();
}
```

Liveness is real-time; cache makes no sense.

## Use case enumeration (42 total)

### Registry (13)

**Reads (4):**
- `FetchPatientUseCase` — cache-first by patientId
- `FetchPatientByPersonIdUseCase` — cache-first by personId (uses A17's personId B-Tree index)
- `ListPatientsUseCase` — cache-first by status/cursor/limit
- `SearchPatientsUseCase` — cache-first via FTS5 (A17's `patient_summaries_fts`)

**Writes (9):**
- `RegisterPatientUseCase` — special case: no cached version yet; mutation has `expectedVersion: 0`; optimistic cache upsert with version 1
- `AddFamilyMemberUseCase`, `RemoveFamilyMemberUseCase` — patient-aggregate mutations, expectedVersion read from cache
- `AssignPrimaryCaregiverUseCase`, `UpdateSocialIdentityUseCase`
- `DischargePatientUseCase`, `ReadmitPatientUseCase`, `AdmitPatientUseCase`, `WithdrawPatientUseCase`

### Assessment (7 — all writes)

All follow Pattern 2 with `Patient` aggregate (`expectedVersion` read from PatientsCache):
- `UpdateHealthStatusUseCase`, `UpdateHousingConditionUseCase`, `UpdateEducationalStatusUseCase`, `UpdateSocioEconomicSituationUseCase`, `UpdateWorkAndIncomeUseCase`, `UpdateCommunitySupportNetworkUseCase`, `UpdateSocialHealthSummaryUseCase`

### Care (3)

- `RegisterAppointmentUseCase` — write, mutation has `expectedVersion: 0` (new entity)
- `UpdateIntakeInfoUseCase` — write, intake is a per-patient blob (expectedVersion from PatientsCache)
- `ListAppointmentsUseCase` — read, cache-first by patientId via CareCache.listByPatient

### Protection (6)

**Reads (3):** `ListReferralsUseCase`, `ListViolationReportsUseCase`, `FetchPlacementHistoryUseCase`
**Writes (3):** `CreateReferralUseCase`, `ReportViolationUseCase`, `UpdatePlacementHistoryUseCase`

### Audit (1)

- `FetchAuditTrailUseCase` — cache-first via AuditCache.listByPatient with filters (eventType, limit, offset)

### Lookup (10)

**Reads (4):**
- `GetLookupTableUseCase` — cache-first by tableName via LookupCache.listItems
- `GetLookupsBatchUseCase` — fan-out via N parallel `GetLookupTableUseCase` calls
- `ListLookupRequestsUseCase` — cache-first with optional status/tableName filters
- `FindLookupRequestByIdUseCase` — cache-first by requestId

**Writes (6):**
- `CreateLookupItemUseCase`, `UpdateLookupItemUseCase`, `ToggleLookupItemUseCase`
- `CreateLookupRequestUseCase`, `ApproveLookupRequestUseCase`, `RejectLookupRequestUseCase`

### Health (2 — passthroughs)

- `CheckHealthUseCase`, `CheckReadyUseCase`

## REGRA #2 — 4 ambiguidades antecipadas

### #1 — Stale data threshold (5min default, configurable)

`StalePolicy` em `_shared/stale_policy.dart`:
```dart
class StalePolicy {
  const StalePolicy({this.staleAfter = const Duration(minutes: 5)});
  final Duration staleAfter;
  bool isStale(DateTime cachedAt, {DateTime? now}) =>
    (now ?? DateTime.now()).difference(cachedAt) > staleAfter;
}
```

Cada read use case aceita `Duration? staleAfter` no construtor; default 5min.

### #2 — NO rollback em failed_dead

Optimistic cache update **NÃO é revertido** se SyncEngine marcar mutation como `failed_dead`. Decision rationale (master STATE):
> "Surface inconsistência cache↔backend para o usuário resolver via UI. Cache é Read Model; mantém o que o user escreveu localmente até reconciliação manual."

Tests asseram: write use case retorna `Success` mesmo se mutation eventualmente falhar (SyncEngine é async, fire-and-forget). Reconciliação UI é A18c.

### #3 — Concurrent writes ao mesmo aggregate (FIFO preserva ordem)

User chama `dischargePatient` seguido por `admitPatient` rapidamente. Ambos enqueueam no Outbox; SyncEngine drena FIFO por `createdAt ASC` (A18a já testado). Cache reflete o ÚLTIMO optimistic update. Conflito real (409) cai em D2 (B): manual reconciliation.

Tests asseram: 2 writes consecutivos enqueueam 2 mutations ordenadas; cache reflete o segundo optimistic update; ambas mutations chamam `engine.triggerDrain` (idempotente — single-flight).

### #4 — Lookup por chaves alternativas (CPF/etc) — flagar como follow-up

A17 indexa apenas `id` / `personId` / `status` / `tableName` / `eventType`. **Se A18b descobrir use case `findReferralByCpf` ou similar:** flagar em REPORT.md como follow-up para criar `@TableIndex` no Drift schema. Por enquanto não há esses use cases mapeados na lista de 42.

## Constructor injection — sem service locator

Cada use case recebe deps via construtor nomeado (`required`). NO Provider lookups, NO ambient state. Facade (A18c) faz o wiring.

```dart
// EXEMPLO de wiring (A18c vai construir):
final fetchPatient = FetchPatientUseCase(
  cache: patientsCache,         // DriftPatientsCache instance
  remote: registryRemote,        // RegistryRemote instance
  staleAfter: Duration(minutes: 5),
);
```

## Tests strategy (~120 tests em 7 files)

Organização: 1 test file por bounded context (~17 tests/file médio).

```
bff/social_care_desktop/test/use_cases/
├── _fakes/
│   └── fake_sync_engine.dart       — recording stub: triggerDrainCount, started, closed
├── _test_helpers.dart                — shared setup: in-memory caches + outbox + fake engine + fake remotes
├── registry_use_cases_test.dart      — ~30 tests (13 use cases × ~2-3 axes)
├── assessment_use_cases_test.dart    — ~21 tests
├── care_use_cases_test.dart          — ~9 tests
├── protection_use_cases_test.dart    — ~18 tests
├── audit_use_cases_test.dart         — ~3 tests
├── lookup_use_cases_test.dart        — ~30 tests
└── health_use_cases_test.dart        — ~6 tests
```

Test axes per use case:
- **Read use case (~3 axes):** cache-hit fresh / cache-miss → remote → upsert / cache-hit stale → remote refresh / remote-failure
- **Write use case (~4 axes):** mutation enqueued correctly / optimistic cache update applied / triggerDrain called / cache-miss → NotFoundFailure (for non-Register writes)
- **Health (~1 axis):** delegates to remote.checkHealth/checkReady, returns Result<void>

Dependencies:
- **Real cache impls** (`DriftPatientsCache` etc) backed by **in-memory Drift** (mirrors A17 test pattern).
- **Real OutboxRepository** (`DriftOutboxRepository`) with in-memory `SyncDatabase`.
- **Fake remotes** from `bff/shared/lib/src/testing/fake_*_bff.dart` (already used in A18a).
- **Fake SyncEngine** in `_fakes/fake_sync_engine.dart` — implements `SyncEngine` interface, records `triggerDrainCount`, no real drain.

## Cache-with-meta open question (W0 → W1)

A17's contracts return DTOs (e.g. `findById` → `Future<Result<PatientResponse?>>`). Use case Pattern 1 needs `cachedAt` for staleness check. Options:

- **(a) Wrap return type:** change cache contract to `Future<Result<Cached<PatientResponse>?>>` where `Cached<T> { T dto; DateTime cachedAt; int version; }`. **Breaking change** to A17 contracts.
- **(b) Add `findByIdWithMeta`:** new method returning `Cached<T>`, keep `findById` returning DTO. Non-breaking but redundant surface.
- **(c) Use case takes both `cache` AND `cacheRowReader`:** cacheRowReader exposes raw row metadata. More plumbing.

**Test-writer proposes (a)** — wrap return type, refactor A17 cache contracts. It's a small surface change (~20 method signatures across 5 caches) and the use case needs the metadata anyway. **W0 tests assume option (a).** Implementer (W1) can challenge if there's a cleaner path.

## Acceptance criteria (A18b-v2)

- [ ] 42 use case classes em `lib/src/use_cases/<bounded_context>/`
- [ ] `_shared/stale_policy.dart` + `_shared/version_extractor.dart` + `_shared/use_case_failures.dart`
- [ ] Constructor injection em todas as classes (sem Provider lookup interno)
- [ ] Read use cases: cache-first com `staleAfter` configurável (default 5min)
- [ ] Write use cases: enqueue → optimistic cache update → triggerDrain (in this order); cache-miss em non-Register writes retorna `NotFoundFailure`
- [ ] Health use cases: passthroughs puros
- [ ] `Result<T>` end-to-end; sem throw para caller
- [ ] Cache contracts (A17) refatoradas para retornar `Cached<T>` wrapper (opção a) — somente se W1 confirmar
- [ ] `dart analyze bff/social_care_desktop/` zero issues
- [ ] `flutter test bff/social_care_desktop/test/use_cases/` GREEN (~120 tests)
- [ ] Full BFF Desktop suite GREEN (cache + remote + sync + use_cases)
- [ ] Library exports atualizados — use cases públicos para A18c facade consumir

## Out of scope

- Facade pública e sub-facades (A18c)
- Shell rewire (A18c)
- Connectivity restore listener (A18c)
- Drift indexação por chaves alternativas (CPF) — follow-up se descoberto

## Wave plan

- **W0 RED — test-writer:** ~120 failing tests cobrindo os 3 patterns × 42 use cases. Locked surfaces.
- **W1 GREEN — flutter-bff-implementer:** 42 use case impls + 3 shared helpers. Possível refactor de A17 cache contracts (option a do open question).
- **W2 REVIEW — flutter-code-reviewer:** audit pattern fidelity (3 patterns puros, sem mistura), enqueue order (mutation BEFORE optimistic cache), no rollback em failed_dead, constructor injection, no service locator.

## Status
**CLOSED 2026-04-30** — APPROVED Round 1 via 3-agent BFF pipeline.

- W0 RED: 90 failing tests across 9 files (7 contract + 1 fake + 1 helper). 5 surfaces locked. 4 REGRA #2 antecipadas resolvidas. 5 open questions for W1.
- W1 GREEN: 42 use cases + 5 shared utilities + Cached<T> surgical refactor (4 cache contract methods) + uuid dep. Q1 (DTO copyWith) skipped — tests assert version, not patched fields. Q3 (Cached<T>) applied surgically — only PatientsCache/LookupCache findById methods.
- W2 REVIEW: APPROVED. 14/14 audit checks pass. 4 NICE_TO_HAVE deferred to A18c sweep.

**Final state:**
- 90/90 use case tests GREEN
- 376/376 full BFF Desktop suite GREEN (286 prior + 90 new — zero regressão A16/A17/A18a)
- 549/549 bff/shared tests GREEN (no DTO modifications)
- `dart analyze bff/social_care_desktop/` zero errors zero warnings (43 info acceptable)
- 42 use cases × 3 canonical patterns (Read cache-first / Write optimistic-through / Health passthrough)
- Cached<T> envelope com Clock injection cross-cutting
- uuid: ^4.0.0 added

**NICE_TO_HAVE deferred to A18c (non-blocking):**
1. Delete `extractPatientVersion` dead code OR inline at callsite
2. Cache-only reads accept unused `Clock`/`staleAfter` — Phase 6+ list-endpoint follow-up uses them
3. Promote `Clock` to `abstract interface class`
4. Unify cache-impl `now: DateTime Function()?` to typed `Clock`

**Next:** A18c-v2 (facade + shell rewire — restaura `apps/acdg_system/`).
