# Sub-ticket State: A18a-v2-sync-infra (BREAK CHANGE)

phase: tdd-red (test-writer dispatched 2026-04-30)
parent: A18-desktop-sync (split em 3 sub-tickets)
status: W0 RED in progress

## Scope (A18a-v2 only)

Constrói a **infraestrutura de sync** do desktop:
- `SyncDatabase` em arquivo físico **separado** (`app_sync_queue.sqlite`) com migration strategy versionada
- Outbox table (Pattern: Transactional Outbox)
- `SyncMutation` sealed class hierarchy (27 mutações tipadas)
- `OutboxRepository` (CRUD da fila) + `DriftOutboxRepository` impl
- `SyncEngine` (drain logic state machine)
- `RetryPolicy` (exponential backoff)
- `ConflictResolver` (mapeamento de erros → state transitions)

**FORA do escopo A18a-v2:** use cases (A18b), facade pública (A18c), shell rewire (A18c).

## Target structure

```
bff/social_care_desktop/lib/src/sync/
├── _shared/
│   ├── sync_database.dart              — @DriftDatabase MIGRATION-PROTECTED
│   ├── sync_database.drift.dart        — codegen
│   ├── tables/
│   │   └── outbox_table.dart            — Outbox table
│   └── failures.dart                     — SyncFailure (mirror de CacheFailure)
├── outbox/
│   ├── sync_mutation.dart               — sealed class + 27 final classes
│   ├── outbox_dao.dart                   — @DriftAccessor
│   └── outbox_repository.dart            — abstract + DriftOutboxRepository
└── engine/
    ├── sync_engine.dart                  — drain logic + state machine
    ├── retry_policy.dart                 — exponential backoff
    └── conflict_resolver.dart            — error → status mapping
```

## Schema da Outbox

```dart
class Outbox extends Table {
  TextColumn get id => text()();                     // PK, UUID v4 (idempotência)
  TextColumn get aggregateType => text()();          // 'patient', 'appointment', ...
  TextColumn get aggregateId => text()();            // entity being mutated
  TextColumn get mutationType => text()();           // discriminator (27 valores)
  TextColumn get payload => text()();                // serialized JSON request body
  IntColumn get expectedVersion => integer()();      // optimistic locking (D1: forward-compat)
  DateTimeColumn get createdAt => dateTime()();      // FIFO ordering
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  TextColumn get status => text()();                 // pending|in_flight|failed_retriable|failed_dead|completed
  @override Set<Column> get primaryKey => {id};
}
```

**Indexed:** `status` + `createdAt` (composite — drain query "pending ORDER BY createdAt").

## SyncMutation sealed class

Hierarchy: 1 base sealed + **27 final classes** mapeando 1:1 os write methods dos sub-contracts:

| Bounded Context | Mutations | Quantidade |
|---|---|---:|
| Registry | RegisterPatient, AddFamilyMember, RemoveFamilyMember, AssignPrimaryCaregiver, UpdateSocialIdentity, DischargePatient, ReadmitPatient, AdmitPatient, WithdrawPatient | 9 |
| Assessment | UpdateHealthStatus, UpdateHousingCondition, UpdateEducationalStatus, UpdateSocioEconomicSituation, UpdateWorkAndIncome, UpdateCommunitySupportNetwork, UpdateSocialHealthSummary | 7 |
| Care | RegisterAppointment, UpdateIntakeInfo | 2 |
| Protection | UpdatePlacementHistory, ReportViolation, CreateReferral | 3 |
| Lookup | CreateLookupItem, UpdateLookupItem, ToggleLookupItem, CreateLookupRequest, ApproveLookupRequest, RejectLookupRequest | 6 |
| **Total** | | **27** |

**Audit & Health:** zero mutations (read-only contexts).

```dart
sealed class SyncMutation {
  const SyncMutation({
    required this.id,
    required this.aggregateId,
    required this.expectedVersion,
    required this.createdAt,
  });
  final String id;
  final String aggregateId;
  final int expectedVersion;
  final DateTime createdAt;
  String get aggregateType;     // const per subclass
  String get mutationType;       // const per subclass discriminator
  Map<String, dynamic> toPayload();
  
  // Round-trip do Outbox row (sealed pattern matching obrigatório)
  factory SyncMutation.fromOutboxRow(OutboxRow row) => switch (row.mutationType) {
    'register_patient' => RegisterPatientMutation.fromPayload(row),
    // ... 26 mais (exhaustive)
    _ => throw StateError('Unknown mutationType: ${row.mutationType}'),
  };
}
```

## SyncEngine state machine

```
[pending] ─pickup─→ [in_flight] ─success─→ [completed]
                          ├─409/OPTIMISTIC_LOCK_CONFLICT─→ [failed_dead]    ← D2 (B): manual reconciliation
                          ├─5xx/network─────────────────→ [failed_retriable] ──backoff──→ [pending]
                          └─4xx other───────────────────→ [failed_dead]
```

- Drenagem **FIFO por createdAt ASC**.
- **Single-flight:** drain protegido por mutex; chamadas concorrentes a `triggerDrain()` viram no-op se um drain já está rodando.
- **Trigger-based (D5 γ):** sem `Timer.periodic`. Drain só roda quando:
  - `engine.start()` chamado pela primeira vez após `desktop.startSync()` (D4 α)
  - Write use case chama `engine.triggerDrain()` após enqueue
  - Connectivity restore listener (`connectivity_plus`) detecta volta de rede

- **On Success:** mark mutation completed. Cache version increment para o aggregate correspondente é **opcional** — write use case já fez optimistic update; SyncEngine apenas valida que aceitou.

## RetryPolicy

```dart
Duration nextRetryDelay(int attemptCount) {
  // 2^attemptCount * 1s, capped at 30min
  final exponent = math.min(attemptCount, 11);  // 2^11 = 2048s ≈ 34min
  final base = Duration(seconds: math.pow(2, exponent).toInt());
  return Duration(milliseconds: math.min(base.inMilliseconds, 30 * 60 * 1000));
}

bool shouldRetry(int attemptCount) => attemptCount < 10;  // max 10 attempts
```

Após 10 attempts → `failed_dead`.

## ConflictResolver

Mapeia falhas para state transitions:

```dart
SyncDecision decide(Object error) => switch (error) {
  BackendErrorResponse(error: BackendError(http: 409)) => SyncDecision.deadOnConflict(),
  BackendErrorResponse(error: BackendError(http: >= 500)) => SyncDecision.retriable(),
  BackendErrorResponse(error: BackendError(http: >= 400 && < 500)) => SyncDecision.deadOnClientError(),
  DioException() => SyncDecision.retriable(),  // network / timeout
  _ => SyncDecision.retriable(),                // unknown — retry conservatively
};
```

## Pubspec changes (A18a)

```yaml
dependencies:
  drift: ^2.31.0                # já presente
  sqlite3_flutter_libs: ^0.5.28 # já presente (A17)
  path_provider: ^2.1.0         # NEW (D3)
  connectivity_plus: ^6.0.0     # NEW (D5 γ — trigger on connectivity restore)
dev_dependencies:
  drift_dev: ^2.31.0            # já presente
  build_runner: ^2.4.0          # já presente
  sqlite3: ^2.7.4               # já presente
```

## Header docstring obrigatório (sync_database.dart)

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

## Acceptance criteria (A18a-v2)

- [ ] `SyncDatabase` em arquivo físico separado (`app_sync_queue.sqlite`)
- [ ] Header docstring exact-match acima
- [ ] Outbox table com 11 colunas + composite index `(status, createdAt)`
- [ ] `MigrationStrategy.onCreate` cria a tabela; schemaVersion = 1
- [ ] 27 SyncMutation final classes implementando o sealed
- [ ] `SyncMutation.fromOutboxRow` exhaustive (compiler enforça)
- [ ] `OutboxRepository` abstract + `DriftOutboxRepository` impl com `Result<T>` discipline
- [ ] `SyncEngine.drain()` ordena FIFO, single-flight, transitions corretas
- [ ] `RetryPolicy` matemática correta (capped exp backoff, max 10)
- [ ] `ConflictResolver` mapping conforme switch acima
- [ ] `dart analyze bff/social_care_desktop/` zero errors zero warnings
- [ ] `flutter test bff/social_care_desktop/test/sync/` GREEN (~50 tests)
- [ ] Library exports atualizados (sync types acessíveis para A18b consumir)
- [ ] Pubspec adiciona `path_provider` e `connectivity_plus`

## Out of scope

- Use cases de orquestração (A18b)
- Facade pública (A18c)
- Shell rewire (A18c)
- Background isolate (evolução futura — D5 (β) opcional)
- ADR-005 update (closed em ADR-021 já)

## Wave plan

- **W0 RED — test-writer:** ~50 failing tests covering Outbox CRUD, SyncMutation sealed class round-trip, SyncEngine state machine, RetryPolicy math, ConflictResolver mapping.
- **W1 GREEN — flutter-bff-implementer:** SyncDatabase + 27 mutations + OutboxRepository + SyncEngine + RetryPolicy + ConflictResolver. Tests pass.
- **W2 REVIEW — flutter-code-reviewer:** audit separação física, sealed-class exaustividade, FIFO ordering, single-flight, retry math, conflict mapping, header docstring.

## Status
**CLOSED 2026-04-30** — APPROVED Round 1 via 3-agent BFF pipeline.

- W0 RED: 52 failing tests across 6 files (5 test + 1 helper). Locked contracts for OutboxRepository, 27 SyncMutation discriminators, SyncEngine, RetryPolicy, ConflictResolver. 3 open questions resolved in W1 briefing.
- W1 GREEN: 8 impl files (1824 LoC) + 2 codegen `.drift.dart`. 27 final mutation classes, sealed-class exhaustive switch, single-flight drain, FIFO ordering, composite index, header docstring exact-match. 1 REGRA #2 surfaced and resolved in impl-side (`_toJsonClean` normalizer for nested DTO payload contract).
- W2 REVIEW: APPROVED. 14/14 audit checks pass. 2 NICE_TO_HAVE deferred to A18b/c.

**Final state:**
- 52/52 sync tests GREEN
- 286/286 full BFF Desktop suite GREEN (zero regressão A16-v2 / A17-v2)
- `dart analyze bff/social_care_desktop/` zero issues
- Physical separation enforced: zero cross-imports `cache/` ↔ `sync/` (only mutual docstring warnings)
- `path_provider ^2.1.0` + `connectivity_plus ^7.0.0` adicionados ao pubspec

**Next:** A18b-v2 (use cases — ~42 orchestrators).
