# Sessão 2026-04-30 — A17-v2: Desktop Cache Layer (Drift + FTS5)

> **Ticket:** A17-v2 (Onda 4 / Fase 3 BFF Contract A)
> **Pipeline:** 3-agent BFF (test-writer → flutter-bff-implementer → flutter-code-reviewer)
> **Commit:** `891814a` — `feat(bff/desktop): A17-v2 — desktop cache layer (Drift + FTS5)`
> **Resultado:** APPROVED Round 1, zero MUST_FIX, 81/81 cache tests GREEN, full BFF Desktop suite 234/234 GREEN, dart analyze 0 issues.
> **Próximo:** A18-v2 (sync + use_cases + facade — restaura `apps/acdg_system/`)

## O que foi feito

### 1. Alinhamento arquitetural com Architect (rigor literatura)

Antes de despachar o test-writer, o usuário (assumindo papel de Arquiteto de Dados purista) revisou as 3 decisões propostas e aplicou correções implacáveis baseadas em literatura de Engenharia de Software:

**Decisão 1 — Cache Contract Surface (CRUD per entity):** *Aprovado com Louvor.* Essencialmente o **Padrão Outbox** misturado com **Write-Through Cache**. SyncQueue armazena a intenção/evento; Cache armazena o **Read Model** (Projeção). DDD + CQRS aplicados corretamente.

**Decisão 2 — 5 cache contracts, não 7 (Aggregate Roots):** *Aprovado.* Eric Evans (DDD blue book) define Aggregate Root como cluster de entidades tratadas como unidade de consistência transacional. Assessment não faz sentido sem Patient → Patient é o Aggregate Root. Banco local modela **Agregados**, não espelha cegamente endpoints REST. Health excluído por ser intrinsecamente volátil sem valor offline (regra de ouro de bancos em memória).

**Decisão 3 — Drift Schema:** *Aprovado na essência, REPROVADO no detalhe técnico.* Três correções obrigatórias:

#### Correção A: FTS5 substitui `searchTerms LIKE`

> "Se você fizer buscas usando `WHERE searchTerms LIKE '%termo%'`, o banco de dados **ignora qualquer índice B-Tree tradicional**. Isso força um *Full Table Scan* (O(N)), o que é um crime em livros de otimização de banco de dados."

**Solução rigorosa:** SQLite FTS5 cria *Inverted Index* (como Elasticsearch). Drift suporta via virtual tables + triggers para sincronização automática. Search vira O(log N).

#### Correção B: Separação física do SyncQueue (Outbox protection)

> "Se o cache quebrar, recria. Se a fila quebrar, você tem perda de dados (Data Loss). A SyncQueue **deve** ter migração estruturada e ser indestrutível, ou deve morrer em um arquivo de banco de dados `.sqlite` fisicamente separado do arquivo de Cache."

**Solução rigorosa:** A17-v2 cria APENAS `CacheDatabase` (em `app_cache.sqlite`, droppable). A18-v2 vai criar `SyncDatabase` em arquivo físico separado (`app_sync_queue.sqlite`) com migration strategy versionada. Header docstring obrigatório no `cache_database.dart` documenta a separação para que ninguém futuramente misture.

#### Correção C: Optimistic Locking (versão futura)

> "O *Optimistic Locking* via controle de versão é obrigatório em sistemas distribuídos offline-first para evitar 'Lost Updates'. Certifique-se apenas de que a SyncEngine injete a cláusula `WHERE id = X AND version = Y` na hora de fazer o UPDATE no servidor."

**A17-v2 escopo:** apenas armazena `version` (int) em todas as tabelas; tests assertam round-trip.
**A18-v2 escopo:** SyncEngine injeta a cláusula `WHERE id=X AND version=Y` no UPDATE remoto.

### 2. Estrutura final do `lib/src/cache/`

```
bff/social_care_desktop/lib/src/cache/
├── _shared/
│   ├── cache_database.dart          — @DriftDatabase + MigrationStrategy + FTS5 setup
│   ├── cache_database.drift.dart     — codegen
│   ├── failures.dart                 — CacheFailure (mirror de BackendErrorResponse)
│   └── tables/
│       ├── patients_table.dart       — Patients + PatientSummaries
│       ├── care_table.dart           — Appointments
│       ├── protection_tables.dart    — Referrals + Violations + PlacementHistories
│       ├── audit_table.dart          — AuditEntries
│       └── lookup_tables.dart        — LookupItems + LookupRequests
├── contracts/
│   ├── patients_cache.dart           — abstract interface PatientsCache (9 métodos)
│   ├── care_cache.dart               — CareCache (5 métodos)
│   ├── protection_cache.dart         — ProtectionCache (12 métodos)
│   ├── audit_cache.dart              — AuditCache (5 métodos)
│   └── lookup_cache.dart             — LookupCache (12 métodos)
├── daos/
│   ├── patient_dao.dart              — Drift @DriftAccessor + FTS5 search
│   ├── care_dao.dart
│   ├── protection_dao.dart
│   ├── audit_dao.dart
│   └── lookup_dao.dart
└── impls/
    ├── drift_patients_cache.dart     — implements PatientsCache; thin wrapper
    ├── drift_care_cache.dart
    ├── drift_protection_cache.dart
    ├── drift_audit_cache.dart
    └── drift_lookup_cache.dart
```

**Total:** 24 impl files (5 contracts + 1 DB + 1 failures + 5 tables + 5 DAOs + 5 impls + 2 codegen helpers) + 11 codegen `.drift.dart` files (build_runner).

### 3. Schema strategy: denormalized JSON-blob + B-Tree + FTS5

Cada tabela tem:
- **Indexed B-Tree columns** para lookups O(log N): `id` (PK), `personId`, `status`, `eventType`, etc.
- **`payload` (TEXT)** com o DTO completo serializado em JSON (`PatientResponse.toJson()` round-trip).
- **`cachedAt` (DATETIME)** — last-seen-at; A18 use cases decidem refresh policy.
- **`version` (INT)** — caller-controlled; A18 SyncEngine usa para optimistic locking.

**FTS5 virtual tables:** apenas para contextos onde busca textual é semântica:

| Virtual Table | Indexes | Derivação |
|---|---|---|
| `patient_summaries_fts` | `terms` | `lower(coalesce(first_name,'') \|\| ' ' \|\| coalesce(last_name,'') \|\| ' ' \|\| coalesce(primary_diagnosis,''))` |
| `lookup_tables_fts` | `terms` | `lower(lookup_name)` por row de `lookup_items` |

**6 triggers** (3 por FTS5: AI/AU/AD) usando external-content protocol:

```sql
CREATE TRIGGER patient_summaries_ai AFTER INSERT ON patient_summaries BEGIN
  INSERT INTO patient_summaries_fts(rowid, terms) VALUES (new.rowid, ...);
END;
CREATE TRIGGER patient_summaries_ad AFTER DELETE ON patient_summaries BEGIN
  INSERT INTO patient_summaries_fts(patient_summaries_fts, rowid, terms) VALUES ('delete', old.rowid, ...);
END;
CREATE TRIGGER patient_summaries_au AFTER UPDATE ON patient_summaries BEGIN
  INSERT INTO patient_summaries_fts(patient_summaries_fts, rowid, terms) VALUES ('delete', old.rowid, ...);
  INSERT INTO patient_summaries_fts(rowid, terms) VALUES (new.rowid, ...);
END;
```

**Search query** vira:
```sql
SELECT * FROM patient_summaries WHERE rowid IN (
  SELECT rowid FROM patient_summaries_fts WHERE patient_summaries_fts MATCH 'mari*'
)
```

O(log N) ao invés de O(N) com `LIKE`.

### 4. Cache contract surface — CRUD per entity (CQRS-aligned)

Cache é **persistência pura** — separada da intenção de negócio. Não tem `dischargePatient`; tem `upsertPatient(PatientResponse)`. Mutações de domínio passam pelo SyncQueue (A18-v2), não tocam cache diretamente.

**Surface canônica por contract:**
- `find*(id)` — single-row lookup
- `findBy*(...)` — alternate-key lookup (e.g. `findByPersonId`)
- `list*(...)` — collection com filtros (`status`, `cursor`, `limit`)
- `search*(term)` — FTS5-powered (Patients summaries, Lookup tableNames)
- `upsert*(dto, {required int version})` — write-through, idempotent, full row replacement
- `delete*(id)` — single-row delete
- `clear*()` — wipe whole table

**Missing rows = `Success(null)`**, NEVER `Failure`. **DB I/O failures = `Failure(CacheFailure)`** com stackTrace capture.

### 5. Padrão Result<T> + try/catch boundary

Cada método público segue o shape:

```dart
@override
Future<Result<PatientResponse?>> findById(String patientId) async {
  try {
    await _ready;
    final row = await _dao.findPatientById(patientId);
    if (row == null) return const Success(null);
    return Success(PatientResponse.fromJson(jsonDecode(row.payload) as Map<String, dynamic>));
  } catch (e, stackTrace) {
    return Failure<PatientResponse?>(CacheFailure(e), stackTrace: stackTrace);
  }
}
```

**Cache é a SEGUNDA camada do BFF onde try/catch é permitido** (boundary de adapter — Drift exceptions são unchecked). Mirror do que `RemoteBase` fez para HTTP.

### 6. REGRA #2 surfaceada e resolvida no W1 (sem alterar tests)

**Problema:** test "DB I/O failure" simulava falha fechando o database mid-test. Drift tem quirk de lazy-init que silenciosamente re-abre o DB e retorna `Success(null)`. Teste esperava `Failure`.

**4-point analysis:**
- **Intenção:** verificar que DB I/O failure path propaga como `Failure`.
- **Falha:** o trigger (close-before-any-op) não exercita confiavelmente sem warmup.
- **Veredito:** intenção do teste é sólida; trigger é frágil.
- **Resolução (impl-side, sem alterar testes):** cada `Drift*Cache` constructor agenda `db.customSelect('SELECT 1').get()` como `_ready` future; cada método público awaits antes da chamada DAO. Isto força `MigrationStrategy.onCreate` (incluindo FTS5 setup) a rodar antes do `database.close()` do teste. Pós-close, calls hit um executor opened-then-closed e jogam `StateError`, que o impl wrappa em `Failure(CacheFailure)`.

**Não é test cheating** — adaptação pragmática a quirk do Drift; impl agora exercita a falha path que o teste pretendia. Documentado inline em todos os 5 impls.

### 7. Pubspec — dependências Drift adicionadas

```yaml
dependencies:
  drift: ^2.31.0                # já presente
  sqlite3_flutter_libs: ^0.5.28 # production: SQLite com FTS5 enabled

dev_dependencies:
  drift_dev: ^2.31.0            # codegen
  build_runner: ^2.4.0          # codegen orchestrator
  sqlite3: ^2.7.4               # tests: in-process SQLite com FTS5 para NativeDatabase.memory()
```

Plus `build.yaml` mirroring `packages/persistence/build.yaml` (modular drift codegen).

### 8. Library exports

`lib/social_care_desktop.dart` exporta apenas os **5 contracts**:

```dart
export 'src/cache/contracts/patients_cache.dart';
export 'src/cache/contracts/care_cache.dart';
export 'src/cache/contracts/protection_cache.dart';
export 'src/cache/contracts/audit_cache.dart';
export 'src/cache/contracts/lookup_cache.dart';
```

**Impls são library-private** — A18-v2 facade vai instanciar e wirear via DI. Os 7 A16-v2 remote exports são preservados.

### 9. Testes — 81 RED → 81 GREEN + 234/234 full suite

```
flutter test bff/social_care_desktop/test/cache/
00:00 +81: All tests passed!
```

Por arquivo: patients 21/21 · care 12/12 · protection 16/16 · audit 13/13 · lookup 19/19.

**Full BFF Desktop suite (cache + A16-v2 remote):** **234/234 GREEN** — zero regressão.

Cada método é testado em 5 axes (quando aplicável):
1. **Round-trip** — `upsert(dto); findById == dto` (incluindo nested objects).
2. **Optimistic-locking field** — `version` round-trip caller-controlled.
3. **`cachedAt` round-trip** — set por upsert.
4. **FTS5 search** (Patients + Lookup): token match, prefix match (`MATCH 'term*'`), no-match returns empty, sync após upsert (re-indexa), sync após delete (de-indexa).
5. **B-Tree index queries** — `list(status: 'discharged')` retorna apenas discharged.

Plus negative paths:
- `findById('nonexistent')` retorna `Success(null)`, NÃO `Failure`.
- DB I/O failure (closing DB mid-test após warmup) → `Failure(CacheFailure)`.

**MockDio NÃO usado** — testes do cache são **integração real com Drift** via `NativeDatabase.memory()`. Mockar Drift derrotaria o propósito.

## Decisões pinadas (consequência operacional)

1. **Drift é a engine de cache do desktop.** ADR-005 será atualizado para v2 (follow-up). Não recomendar Isar em novos contextos.

2. **5 cache contracts, não 7.** Aggregate Root alignment — Assessment é embedded em Patient; Health não cacheia.

3. **Cache é CRUD-only.** Sem ações de negócio. Mutações vão pelo SyncQueue (A18).

4. **SyncQueue VAI VIVER em arquivo físico separado** (`app_sync_queue.sqlite`). Header docstring no `cache_database.dart` documenta. A18-v2 cria `SyncDatabase` com migration strategy versionada.

5. **`version` é caller-controlled.** A18 owns increment via optimistic-locking writes. Cache só armazena.

6. **`cachedAt` set por upsert via `DateTime.now()`.** Sem Clock injection (A18 concern).

7. **FTS5 é o padrão para text search no monorepo.** B-Tree + LIKE proibido — viola O(log N) gold rule.

8. **Tests usam `NativeDatabase.memory()`.** Sem file I/O. Estado limpo por teste.

## Pipeline 3-agent — performance

| Wave | Agente | Saída | Tempo aprox. |
|---|---|---|---|
| W0 | test-writer | 81 RED tests, in-memory DB helper, 5 surfaces locked, 3 REGRA #2 ambiguities pre-resolvidas | ~10 min |
| W1 | flutter-bff-implementer | 24 impl files + 11 codegen, FTS5 + triggers, build_runner integration, 1 REGRA #2 resolvida (`_ready` warmup) | ~17 min |
| W2 | flutter-code-reviewer | Auditoria 13 checks, APPROVED Round 1 | ~4 min |

**Round 1 sem rejeição** — terceiro ticket consecutivo (A15, A16-v2, A17-v2). Pipeline está convergindo.

## Observação não-óbvia: Drift quirk + warmup pattern

O `_ready` warmup é uma descoberta valiosa para todo código Drift no monorepo: **um `NativeDatabase.memory()` recém-criado faz lazy init na PRIMEIRA query, não no construtor**. Se o caller fechar o DB antes de qualquer query, a próxima query silenciosamente re-abre porque o init nunca rodou. Para garantir que `database.close()` realmente feche um DB pronto, agende uma query trivial (`SELECT 1`) no construtor do consumer.

**Generalização:** qualquer adapter que envolva Drift e queira garantir comportamento determinístico de close deveria seguir este pattern.

## Próximos passos (Onda 4 — fechando)

- **A18-v2 (sync + use_cases + facade):**
  - **`SyncDatabase` em arquivo SEPARADO** (`app_sync_queue.sqlite`) — migration-protected.
  - **`SyncQueue` tipado** via sealed-class de mutações: `RegisterPatient`, `UpdateHealthStatus`, `RegisterAppointment`, etc. — uma per ação que muta backend.
  - **`SyncEngine`** drena queue por bounded context com optimistic locking: `WHERE id=X AND version=Y` no UPDATE remoto. Conflict resolution policy a definir.
  - **~40 use cases** em `use_cases/<bounded_context>/` — orquestram cache+remote+queue. Padrão write-through (write cache → enqueue → trigger sync) ou read-through (cache-first, fallback remote).
  - **Facade público** (`facade/social_care_desktop.dart`) — API que `apps/acdg_system/` consome. Restaura compilação do shell.

- **Onda 5 (gate final A19-A21):** após A18, dart analyze bff/ zero, atualizar `handbook/architecture/CONTRACT_A_PUBLIC_API.md`, deletar resto de código legado.

- **A24 (débito Flutter, primeiro ticket da Fase 4):** retrofit dos 13 arquivos que ficaram fora do canon V2 do A23.

- **ADR-005-v2 (follow-up handbook):** atualizar declarando pivot Isar → Drift, citando abandono do upstream + SPM-incompat como drivers.
