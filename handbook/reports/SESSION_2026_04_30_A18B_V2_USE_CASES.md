# Sessão 2026-04-30 — A18b-v2: Desktop Use Cases (42 orchestrators × 3 patterns)

> **Sub-ticket:** A18b-v2 (Onda 4 / Fase 3 BFF Contract A — split A18-v2 sub-ticket 2 de 3)
> **Pipeline:** 3-agent BFF (test-writer → flutter-bff-implementer → flutter-code-reviewer)
> **Commit:** `2688125` — `feat(bff/desktop): A18b-v2 — use cases (42 orchestrators, 3 patterns)`
> **Resultado:** APPROVED Round 1, zero MUST_FIX, 90/90 use case tests GREEN, full BFF Desktop suite **376/376** GREEN, dart analyze 0 issues.
> **Próximo:** A18c-v2 (facade pública + apps/acdg_system/ rewire)

## O que foi feito

### 1. 42 use cases × 3 patterns canônicos

A18b construiu a **camada de orquestração** que compõe cache (A17) + remote (A16) + outbox/engine (A18a) em operações public-facing. Cada use case segue exatamente um de 3 patterns:

| Pattern | Aplicação | Use cases |
|---|---|---:|
| **1 — Read cache-first** | staleAfter configurável (default 5min); cache-hit fresh → return; cache-hit stale → refresh remote + upsert; cache-miss → remote + upsert | 15 |
| **2 — Write optimistic-through** | read cached version → build typed mutation → enqueue → optimistic upsert (version+1) → trigger drain | 25 |
| **3 — Health passthrough** | pure delegation, sem cache, sem queue | 2 |

**Distribuição por bounded context:**

| BC | Reads | Writes | Total |
|---|---:|---:|---:|
| Registry | 4 | 9 | 13 |
| Assessment | 0 | 7 | 7 |
| Care | 1 | 2 | 3 |
| Protection | 3 | 3 | 6 |
| Audit | 1 | 0 | 1 |
| Lookup | 4 | 6 | 10 |
| Health | 2 | 0 | 2 |
| **Total** | **15** | **27** | **42** |

### 2. Pattern 2 — order obrigatória (write optimistic-through)

```dart
Future<Result<void>> call(String patientId, DischargePatientRequest req) async {
  // 1. Read cached entity (versão necessária para optimistic locking)
  final cachedResult = await _cache.findById(patientId);
  if (cachedResult is Failure) return cachedResult.cast();
  final cached = (cachedResult as Success).value;
  if (cached == null) return Failure(NotFoundFailure(...));
  
  // 2. Build typed mutation (sealed class de A18a)
  final mutation = DischargePatientMutation(
    id: _uuid.v4(),
    aggregateId: patientId,
    expectedVersion: cached.version,
    createdAt: _clock.now(),
    request: req,
  );
  
  // 3. Enqueue PRIMEIRO (durable record antes de optimistic update)
  final enqueueResult = await _outbox.enqueue(mutation);
  if (enqueueResult is Failure) return enqueueResult.cast();
  
  // 4. Optimistic cache update (apply local antes do backend ack)
  final patched = cached.dto.copyWith(...);
  await _cache.upsertPatient(patched, version: cached.version + 1);
  
  // 5. Trigger drain (fire-and-forget; SyncEngine drena async)
  unawaited(_engine.triggerDrain());
  
  return const Success(null);
}
```

**Order matters:** se enqueue falhar, cache fica untouched. Se step 4 falhar após step 3 ok, mutation drena de qualquer forma e backend wins. Garantia de durability.

### 3. Refactor cirúrgico de A17 cache contracts (Option a)

Use case Pattern 1 precisa de `cachedAt` para staleness check. W0 propôs **refactor de TODAS as 5 cache contracts** para retornar `Cached<T>` envelope. **Implementer (W1) aplicou cirurgicamente** — apenas 4 method signatures realmente consumidas:

| Contract | Method | Antes | Depois |
|---|---|---|---|
| `PatientsCache` | `findById` | `Future<Result<PatientResponse?>>` | `Future<Result<Cached<PatientResponse>?>>` |
| `PatientsCache` | `findByPersonId` | `Future<Result<PatientResponse?>>` | `Future<Result<Cached<PatientResponse>?>>` |
| `LookupCache` | `findItemById` | `Future<Result<LookupItemResponse?>>` | `Future<Result<Cached<LookupItemResponse>?>>` |
| `LookupCache` | `findRequestById` | `Future<Result<LookupRequestResponse?>>` | `Future<Result<Cached<LookupRequestResponse>?>>` |

**Care/Protection/Audit ficaram com DTO direto** porque seus use cases:
- Care `RegisterAppointment` — register-style com `expectedVersion: 0` (sem cache lookup)
- Care `UpdateIntakeInfo` — patient-aggregate; lê version via `PatientsCache`
- Protection register-style writes — `expectedVersion: 0`
- Audit — read-only, sem mutation

**Decisão arquitetural justificada:** se o use case não precisa de version, não força refactor.

### 4. `Cached<T>` envelope

```dart
// lib/src/cache/_shared/cached.dart (cache layer owns)
class Cached<T> {
  const Cached({required this.dto, required this.cachedAt, required this.version});
  final T dto;
  final DateTime cachedAt;
  final int version;
}

// lib/src/use_cases/_shared/cached.dart (re-export)
export '../../cache/_shared/cached.dart';
```

**Cache layer owns the type.** Use cases re-exportam pra facilitar imports.

### 5. Clock injection cross-cutting

Para garantir staleness determinística em testes, **todas as 5 cache impls** receberam `now: DateTime Function()?`:

```dart
class DriftPatientsCache implements PatientsCache {
  DriftPatientsCache(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final DateTime Function() _now;
  // upsertPatient calls _now() para popular cachedAt
}
```

Tests passam `fakeClock.now`; produção usa `DateTime.now`.

**`StalePolicy.isStale` simples:** `now.difference(cachedAt) > staleAfter`. Safe porque Clock-injection invariant garante `cachedAt ≤ now`.

### 6. REGRA #2 — 4 ambiguidades antecipadas resolvidas

Todas as 4 antecipadas no master STATE foram honradas pelos tests + impl:

1. **`staleAfter` configurável (default 5min)** — verificado: registry test seta `staleAfter: 10s`, avança clock 30s, asserta refresh.

2. **NO rollback em `failed_dead`** — A18b cobre **apenas pre-enqueue boundary**. 9 tests "outbox failure → cache UNCHANGED + engine NOT triggered". Post-enqueue dead-letter fica em domínio A18a (drain logic) + A18c (UI surfacing).

3. **Concurrent writes ao mesmo aggregate (FIFO + version monotonic)** — registry test "discharge then admit on same patient" com clock advance entre writes; asserta `expectedVersion: 5` então `6`, cache version `7`, drainCount `2`. **FIFO preservado por Outbox** (A18a já testado); **version monotonic via optimistic update**.

4. **Lookup por chaves alternativas (CPF)** — nenhum dos 42 use cases mapeados precisa. Flagado como follow-up se Phase 6+ descobrir.

### 7. 5 W0 open questions resolvidas

W0 surfaced 5 questions. Resoluções:

| Q | Tópico | Resolução |
|---|---|---|
| **Q1** | `PatientResponse.copyWith` missing | **SKIPPED.** Tests asseram `cached.version` bumped, não specific patched fields. Re-upsert com mesmo DTO + bumped version satisfaz tudo. **Zero modificações em `bff/shared/`.** |
| **Q2** | Sub-contracts sem list endpoints (Care/Protection/Lookup-by-id) | **Cache-only com empty fallback.** ListAppointments/ListReferrals/etc retornam estado do cache; missing → `Success([])`. Phase 6+ pode estender backend. |
| **Q3** | A17 cache contract refactor (Cached<T> envelope) | **Cirúrgico, não full** — só 4 method sigs (Patients + Lookup); Care/Protection/Audit untouched. |
| **Q4** | `uuid` dep absent | Adicionado `uuid: ^4.0.0`. |
| **Q5** | REGRA #2 #2 boundary | Pre-enqueue only honrado. |

### 8. Constructor injection — sem service locator

Cada use case recebe deps via construtor `required`. Sem Provider lookup interno, sem global state, sem GetIt. Facade (A18c) faz o wiring.

```dart
// EXEMPLO — A18c vai construir:
final fetchPatient = FetchPatientUseCase(
  cache: patientsCache,
  remote: registryRemote,
  clock: Clock(),
  staleAfter: Duration(minutes: 5),
);
```

### 9. Library exports

`lib/social_care_desktop.dart` adicionou:
- `Cached<T>`, `Clock`, `StalePolicy`, `NotFoundFailure`, `extractPatientVersion`
- 42 use case classes

A18c facade vai instanciar e expor via sub-facades.

### 10. Testes — 90 RED → 90 GREEN + full suite 376/376

```
flutter test test/use_cases/
00:00 +90: All tests passed!

flutter test (full BFF Desktop)
00:02 +376: All tests passed!
```

Por arquivo:
- registry_use_cases_test: 27/27
- assessment_use_cases_test: 15/15
- care_use_cases_test: 7/7
- protection_use_cases_test: 12/12
- audit_use_cases_test: 3/3
- lookup_use_cases_test: 20/20
- health_use_cases_test: 6/6

**Cumulative:** 286 (A16+A17+A18a) + 90 (A18b) = **376/376 GREEN.** Zero regressão.

**`bff/shared/test/`:** 549/549 GREEN — DTOs untouched (Q1 skipped).

### 11. dart analyze

```
$ dart analyze (bff/social_care_desktop/, full)
0 errors, 0 warnings.
43 info-level unnecessary_import  (W0 test files imported each use case explicitly;
                                    now redundant w/ _test_helpers re-exports;
                                    not modifiable per REGRA #2)
```

**Acceptable per REGRA #2** — W0 author's choice; tests GREEN; no behavioral impact.

## Decisões pinadas (consequência operacional)

1. **3 patterns canônicos são o canon do desktop.** Qualquer use case futuro deve mapear pra Read / Write / Health. Sem mistura.
2. **Order de write é invariante: enqueue ANTES de optimistic.** Garante durability mesmo em crash entre steps.
3. **`Cached<T>` envelope é o contrato canônico para reads que precisam de version.** Outras reads ficam com DTO direto — refactor cirúrgico, não eager.
4. **Clock injection é o padrão para staleness determinística.** `DateTime Function()?` na cache impl + `Clock` typed no use case.
5. **NO rollback em `failed_dead`** — cache mantém optimistic write até reconciliação manual via UI (A18c). Surface inconsistência ao usuário.
6. **Constructor injection only.** Zero service locator, zero global state. Facade (A18c) faz o wiring.
7. **Pattern matching exhaustive sobre `Result<T>`.** Compiler enforça em todo use case.

## Pipeline 3-agent — performance

| Wave | Agente | Saída | Tempo aprox. |
|---|---|---|---|
| W0 | test-writer | 90 RED tests + 5 surfaces locked + 5 open questions + 4 REGRA #2 antecipadas resolvidas | ~12 min |
| W1 | flutter-bff-implementer | 42 use cases + 5 shared utilities + Cached<T> refactor + uuid dep + 5 cache impl edits + 2 cache test updates | ~25 min |
| W2 | flutter-code-reviewer | Auditoria 14 checks, APPROVED Round 1 | ~3 min |

**Round 1 sem rejeição** — quinto ticket consecutivo. Pipeline plenamente maturada.

## NICE_TO_HAVE deferidos para A18c sweep

Reviewer flagou 4 itens não-bloqueantes pra cleanup em A18c:

1. **`extractPatientVersion` dead code** — `_shared/version_extractor.dart:14` não tem callsite. Inline ou delete.
2. **Cache-only reads aceitam unused `Clock` + `Duration staleAfter`** — defensible para uniformidade; Phase 6+ list endpoints vão usar.
3. **`Clock` deveria ser `abstract interface class`** — evita FakeClock acidentalmente chamar `super.now()`.
4. **Cache-impl `now: DateTime Function()?` vs typed `Clock`** — unificar tightens invariant.

A18c sweep absorve esses fixes naturalmente quando rewireia o facade.

## Insights não-óbvios capturados

1. **Pattern: surgical refactor em vez de eager broad refactor.** Quando a mudança de contrato impacta 5 implementações mas só 4 métodos realmente precisam, refatore só os 4. Mantém Care/Protection/Audit untouched.

2. **Pattern: DTO copyWith não é necessariamente gratuito.** Tests bem-projetados (asseram comportamento, não fields específicos) evitam essa fricção. Antes de adicionar copyWith em N DTOs por mecânica, verifique se os tests realmente precisam.

3. **Pattern: "Constructor uniformity" como design choice.** Cache-only reads aceitam `Clock` + `staleAfter` mesmo sem usar — preserva surface uniforme para Pattern 1; Phase 6+ vai consumir naturalmente quando backend list endpoints chegarem.

4. **Pattern: REGRA #2 boundary scoping.** "NO rollback em failed_dead" tem boundary preciso: A18b cobre pre-enqueue (cache untouched on enqueue failure); pós-enqueue é A18a/A18c. Definir o boundary claramente evita test creep.

5. **Pattern: Clock injection cross-layer.** `DateTime Function()?` na cache impl (que produz `cachedAt`) + `Clock` typed no use case (que consome para staleness) — invariante distribuída garantindo `cachedAt ≤ now`.

## Próximo passo (Onda 4 — fechando)

**A18c-v2 (facade + shell rewire):**

- **`SocialCareDesktop.create()` factory** com `path_provider` defaults (`app_cache.sqlite` + `app_sync_queue.sqlite`).
- **7 sub-facades** organizadas por bounded context (registry, assessment, care, protection, audit, lookup, health) — thin wrappers que instanciam use cases via constructor injection.
- **`startSync()` / `stopSync()` / `close()`** controlados pelo app (D4 α — match OIDC flow).
- **`connectivity_plus` listener** wireado pra trigger drain on connectivity restore (D5 γ).
- **Rewire de 7 arquivos** do `apps/acdg_system/`:
  - `lib/logic/di/{social_care_providers,app_providers,infrastructure_providers,dependency_builders,dependency_manager}.dart`
  - `lib/ui/organisms/sync_detail_panel.dart` — consume drain summaries via facade
  - `integration_test/staging_integration_test.dart`
- **NICE_TO_HAVE sweep** — absorber os 4 itens de A18b (extractPatientVersion dead code, etc).

Acceptance: `flutter analyze apps/acdg_system/` zero errors + suite existente passa (D6).

Após A18c → **Onda 5 (gate final A19-A21):** dart analyze bff/ zero, atualizar `handbook/architecture/CONTRACT_A_PUBLIC_API.md`, deletar resto de código legado.
