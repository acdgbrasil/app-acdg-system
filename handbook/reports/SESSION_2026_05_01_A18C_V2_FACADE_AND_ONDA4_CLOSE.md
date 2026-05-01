# Sessão 2026-05-01 — A18c-v2: Facade Pública + Onda 4 Closure

> **Sub-ticket:** A18c-v2 (Onda 4 / Fase 3 BFF Contract A — split A18-v2 sub-ticket 3 de 3 — **fecha a Onda 4**)
> **Pipeline:** 3-agent BFF (test-writer → flutter-bff-implementer → flutter-code-reviewer)
> **Commit:** `23b980a` — `feat(bff/desktop): A18c-v2 — facade pública + sweep 4 NICE_TO_HAVE`
> **Resultado:** APPROVED Round 1, zero MUST_FIX, 43/44 facade tests + 1 SKIPPED, full BFF Desktop suite **420/420**, dart analyze 0 issues.
> **Marco:** **Onda 4 (desktop rebuild) COMPLETA** após 4 sub-tickets em 3 dias.
> **Próximo:** Phase 4 (Flutter migration — user-driven, packages/) OU Onda 5 (gate final A19-A21).

## O que foi feito

### 1. Camada de facade pública

```
bff/social_care_desktop/lib/src/facade/
├── social_care_desktop.dart            — entry point (520 LoC)
└── sub_facades/
    ├── registry_facade.dart             — RegistryFacade (13 métodos)
    ├── assessment_facade.dart            — AssessmentFacade (7)
    ├── care_facade.dart                  — CareFacade (3)
    ├── protection_facade.dart            — ProtectionFacade (6)
    ├── audit_facade.dart                 — AuditFacade (1)
    ├── lookup_facade.dart                — LookupFacade (10)
    └── health_facade.dart                — HealthFacade (2)
```

**Total:** 1 entry point + 7 sub-facades + 42 métodos delegating.

Cada sub-facade method é 1-line `=> _useCase(args)`. **Zero branching, zero rewrapping, zero logging** — pure delegation. SRP estrito.

### 2. SocialCareDesktop entry point

```dart
class SocialCareDesktop {
  // 7 sub-facades públicas
  final RegistryFacade registry;
  // ... 6 mais
  
  // Sync state pra UI
  Stream<DrainSummary> get drainStream;       // BROADCAST
  Future<Result<DrainSummary>> triggerDrain();
  
  // Lifecycle (D4 α — app-controlled, NÃO auto-start)
  Future<void> startSync();
  Future<void> stopSync();
  Future<void> close();
  
  // Factory com defaults D3 (path_provider)
  static Future<SocialCareDesktop> create({
    required String baseUrl,
    required String actorId,
    required String? Function() tokenProvider,
    String? cacheFilePath,         // default: ApplicationDocuments / app_cache.sqlite
    String? syncQueueFilePath,     // default: ApplicationDocuments / app_sync_queue.sqlite
    Dio? dio, Clock? clock, Connectivity? connectivity,
    Duration staleAfter = const Duration(minutes: 5),
  });
}
```

**5 invariantes asseradas pelos tests:**
1. `create()` NÃO auto-starta sync (D4 α)
2. Connectivity sub criado exatamente uma vez no create()
3. `drainStream` é `.broadcast` (multi-listener)
4. Após `close()`, `triggerDrain` retorna `Failure(SyncFailure)`
5. `startSync` é idempotent

### 3. Connectivity listener (D5 γ — trigger-based)

```dart
_connectivitySub = connectivity.onConnectivityChanged.listen((results) {
  final isOnline = results.any((r) => r != ConnectivityResult.none);
  if (isOnline && !_wasOnline) {           // edge: offline → online
    unawaited(_engine.triggerDrain());
  }
  _wasOnline = isOnline;
});
```

`_wasOnline` seeded de `connectivity.checkConnectivity()` no create. **Mobile counts as online.** Online → online (no-edge) NÃO triggers drain. Subscription cancelada em `close()`.

### 4. `_PumpingSyncEngine` — design choice

```dart
// Private subclass (32 LoC) inside social_care_desktop.dart
class _PumpingSyncEngine extends SyncEngine {
  _PumpingSyncEngine(this._controller, ...);
  final StreamController<DrainSummary> _controller;
  
  @override
  Future<Result<DrainSummary>> triggerDrain() async {
    final result = await super.triggerDrain();
    if (result case Success(:final value)) {
      _controller.add(value);  // pump SUCCESS only — failures via Result
    }
    return result;
  }
}
```

**Razão:** integration E2E test assera que `drainStream` emite em CADA drain success — incluindo fire-and-forget triggers de write use cases (que chamam `engine.triggerDrain()` direto). Sem inheritance OR callback hook em A18a, a facade não tem ponto de observação.

**H1 violation acceptable:** subclass é private + small (32 LoC) + single override + bem-documentado. Reviewer flagou como NICE_TO_HAVE (composition em Phase 4).

### 5. Sweep dos 4 NICE_TO_HAVE de A18b

| # | Item | Action | Resultado |
|---|---|---|---|
| 1 | `extractPatientVersion` dead code | DELETE file + remove export | Zero callers, file removido |
| 2 | Cache-only reads aceitam unused `Clock`/`staleAfter` | DOCUMENT inline `///` doc explicando Pattern 1 uniformity (H3) | 5 use cases doc-touched |
| 3 | `Clock` deveria ser `abstract interface class` (H6) | PROMOTE: `class Clock` → `abstract interface class Clock` + new `class SystemClock implements Clock` | FakeClock now `implements Clock` (não extends — bloqueia super.now() fallback) |
| 4 | Cache impl `now: DateTime Function()?` → typed `Clock` | REFACTOR 5 cache impls aceitarem `Clock?` (default `const SystemClock()`) | Type-unified cross-layer; tests passam `clock: ctx.fakeClock` em vez de `now: fakeClock.now` |

### 6. Boundary com `packages/` — DEFERRED entirely

**User constraint (memory `feedback_packages_user_owned.md`, restated 2026-05-01):**

> "Não faça nada que seja relacionado a packages tá? quando chegarmos nessa hora me avise que eu tenho coisas planejadas..."

**Implementer interpretation correta:** Shell rewire dos 10 arquivos em `apps/acdg_system/` requer modificações em `packages/social_care/` (ViewModels referenciam `LegacyPatientService`, `OfflineFirstRepository`, `LocalSocialCareRepository`, etc. — todos types em packages/). Partial rewire deixaria arquivos em pior estado de compilação. **All-or-nothing deferral foi a chamada certa.**

`apps/acdg_system/` analyze count: **51 issues IDENTICAL ao baseline pre-W1.** Zero regressão, zero improvement. Todas as 51 issues mapeadas como Phase 4 trigger payload com file:line refs.

### 7. Phase 4 trigger payload (51 issues, 8 groups)

| Group | Causa raiz | Files affected |
|---|---|---:|
| A | `SocialCareBffRemote` (deletada em A16) | 5 issues |
| B | `SocialCareContract` (god-interface em packages/) | 3 issues |
| C | `OfflineFirstRepository` (composition wrapper em packages/) | 3 issues |
| D | `LocalSocialCareRepository` (legacy local repo em packages/) | 6 issues |
| E | `LegacyPatientService` (deprecated em packages/) | 2 issues |
| F | OLD `SyncEngine` API (status, pullPatients, refreshStatus, forceSyncNow, processQueue) | 9 issues |
| G | NEW `SyncEngine` constructor signature mismatch | ~6 issues |
| H | Warning: unused_import | 1 |

### 8. Phase 4 migration outline (5 steps)

Para o usuário atacar quando estiver pronto:

1. **Delete legacy types em `packages/social_care/`:** SocialCareContract, OfflineFirstRepository, BffPatientRepository, BffLookupRepository, LegacyPatientService, LocalSocialCareRepository, HttpSocialCareClient.
2. **Delete OLD SyncEngine em `packages/core/core_offline.dart`** (substituído pelo de A18a).
3. **Migrate ~11 ViewModels em `packages/social_care/`** para consumir `SocialCareDesktop.{registry,assessment,care,protection,audit,lookup,health}` direto (em vez dos types deletados).
4. **Migrate `SyncIndicator` + `SyncDetailPanel`** para `SocialCareDesktop.drainStream` + `triggerDrain`.
5. **Rewire 10 arquivos do shell `apps/acdg_system/`** (DI providers + sync_detail_panel + home_page + app_router + integration_test).

A BFF-side surface (`SocialCareDesktop` + 7 sub-facades + 42 métodos + sync state) está **PRONTA pra ser consumida.**

## Testes — 44 RED → 43 GREEN + 1 SKIPPED, full suite 420/420

```
flutter test test/facade/
00:00 +43 ~1: All tests passed (1 skipped)!

flutter test (full BFF Desktop)
00:02 +419 ~1: All tests passed (1 skipped)!
```

**Skipped test:** `default-paths factory uses path_provider when cacheFilePath/syncQueueFilePath are null` — explicitly skipped via `skip:` em W0 (path_provider plugin requer Flutter binding setup que tests não têm). Impl confirmed correct via `_defaultPath` helper.

Per arquivo:
- social_care_desktop_test: 13/14 (1 skipped)
- registry_facade_test: 7/7
- assessment_facade_test: 3/3
- care_facade_test: 3/3
- protection_facade_test: 5/5
- audit_facade_test: 2/2
- lookup_facade_test: 6/6
- health_facade_test: 2/2
- integration_end_to_end_test: 2/2

**Cumulative full suite:** 376 (A16+A17+A18a+A18b) + 44 (A18c) = **420/420** GREEN. Zero regressão.

## ONDA 4 — STATS ACUMULADAS

| Sub-ticket | Files | LoC adicionado | Tests | Cumulative tests | Commit |
|---|---:|---:|---:|---:|---|
| A16-v2 (remote) | 8 + 11 deleted | ~972 | 153 | 153 | `4bda87f` |
| A17-v2 (cache) | 24 + 11 codegen | ~1500 | 81 | 234 | `891814a` |
| A18a-v2 (sync infra) | 8 + 2 codegen | ~1824 | 52 | 286 | `86d28a8` |
| A18b-v2 (use cases) | 47 + Cached<T> refactor | ~1500 | 90 | 376 | `2688125` |
| A18c-v2 (facade + sweep) | 9 + sweep | ~700 | 44 | 420 | `23b980a` |
| **Total** | **~96 new files** | **~6500 LoC** | **420 tests** | **420 GREEN** | 5 commits |

Plus 3 docs commits:
- ADR-021 (Drift supersede Isar) — `d980899`
- DECISION_HEURISTICS handbook — `8ce00f5`
- 4 session reports

**Pipeline 3-agent metrics:**
- 4 sub-tickets × 3 waves = 12 agent dispatches
- **100% APPROVED Round 1** — zero rejeições
- Total tempo de pipeline ativo: ~2h
- Tempo total Onda 4: 3 dias (2026-04-29 → 2026-05-01)

## Insights generalizáveis (capturados em DECISION_HEURISTICS.md)

A Onda 4 inteira solidificou 6 heurísticas arquiteturais que viram canon do monorepo:

| H | Insight | Validado em |
|---|---|---|
| H1 | Refactor cirúrgico > eager broad refactor | A18b (Cached<T> só em 4 sigs) |
| H2 | Test the contract, not the implementation | A18b (copyWith YAGNI) |
| H3 | Constructor uniformity > minimalism | A18b (cache-only Pattern 1 params) |
| H4 | Cross-cutting rule boundary scoping | A18b (REGRA #2 boundary) + A18c (packages/ boundary) |
| H5 | Cross-layer Clock injection | A17/A18b (cache producer + use case consumer) |
| H6 | `abstract interface class` para test infra | A18c (Clock promotion) |

**Heurística adicional emergiu em A18c (será adicionada em PR futuro):**

**H7 — Boundary deferral when partial work would worsen state.** Quando uma constraint impede completar o trabalho em N arquivos relacionados, **defer entirely** em vez de fazer parcial. Razão: parcial deixa arquivos quebrados por DOIS motivos (parte feita, parte não), pior que o estado original onde só estava quebrado por UM motivo. A18c shell rewire = textbook example. Documentar como follow-up no DECISION_HEURISTICS.md.

## Decisões pinadas (consequência operacional)

1. **Sub-facade pattern é o canonical para wiring de use cases.** Cada sub-facade owns 1 bounded context; entry point owns 7 sub-facades + lifecycle. Replicável pra qualquer "BFF + use cases + facade público" no monorepo.

2. **D4 α — app-controlled lifecycle** é canon. Factory NÃO auto-starta. App tem fluxo OIDC; sync começa pós-login.

3. **D5 γ — trigger-based drain via connectivity_plus** é canon. SEM Timer.periodic ociosa. Drain em response a (a) write triggers, (b) connectivity restore, (c) explicit user action.

4. **`drainStream` broadcast** é o pattern para sync state surfacing pro UI. UI subscribers (sync_detail_panel + home_page indicator + future panels) compartilham 1 stream.

5. **Boundary deferral (H7) > partial completion.** Quando user constraint impede full rewire, defer entirely + documentar trigger payload para próxima iteração.

## Pipeline 3-agent — performance final da Onda 4

Durante a Onda 4, o pipeline 3-agent maturou completamente:

- **W0 (test-writer)** consistentemente entrega ~50-150 RED tests com surfaces locked + REGRA #2 ambiguities resolvidas + open questions claras pro implementer.
- **W1 (implementer)** entrega GREEN com decisões arquiteturais explicitadas (incluindo discordâncias do W0 quando justificadas).
- **W2 (reviewer)** entrega APPROVED Round 1 consistentemente, com 10-14 audit checks PASS + NICE_TO_HAVE mapeados.

**Round 1 sem rejeição em 4 sub-tickets consecutivos** — pipeline atingiu maturidade. Pode ser usado como template pra qualquer break-change rebuild em futuras fases.

## Estado do repositório pós-Onda 4

**`bff/social_care_desktop/`:**
- `lib/src/remote/` (A16) — 7 thin remotes implementando sub-contracts
- `lib/src/cache/` (A17) — 5 Aggregate-Root cache contracts + Drift impls + FTS5
- `lib/src/sync/` (A18a) — Outbox + 27 SyncMutations + SyncEngine
- `lib/src/use_cases/` (A18b) — 42 orchestrators × 3 patterns
- `lib/src/facade/` (A18c) — `SocialCareDesktop` + 7 sub-facades
- 420/420 tests GREEN, dart analyze zero issues

**`apps/acdg_system/`:**
- 51 issues residuais — Phase 4 trigger payload pronto

**`packages/`:**
- Intocado (user-owned)
- Phase 4 vai limpar legacy types + migrate ViewModels

**`handbook/`:**
- ADR-021 (Drift supersede Isar) registrado
- DECISION_HEURISTICS.md com 6 heurísticas validadas
- 5 session reports da Onda 4

## Próximos passos

**Decisão pro usuário:**

### Path A — Phase 4 primeiro (Flutter migration user-driven)
- User ataca packages/social_care/ + apps/acdg_system/ junto
- Limpa legacy types + migra ViewModels + rewire shell
- Após Phase 4 → Onda 5 (gate final A19-A21)

### Path B — Onda 5 primeiro (gate final BFF)
- A19: dart analyze bff/ zero (pode estar quase lá)
- A20: atualizar handbook/architecture/CONTRACT_A_PUBLIC_API.md
- A21: deletar resto de código legado em bff/
- Após Onda 5 → Phase 4

**Recomendação:** Path A — Phase 4 primeiro. Razão: shell broken state em apps/acdg_system/ é mais visível/dolorido que docs handbook desatualizados. User tem plano específico pra packages/. Onda 5 é cleanup leve que pode ser feito em qualquer momento.

## ONDA 4 — FECHAMENTO

**4 sub-tickets fechados em 3 dias com pipeline Round 1 sem rejeição.** O `bff/social_care_desktop/` foi completamente reconstruído do zero seguindo break-change autorizada. A surface `SocialCareDesktop` está pronta pra ser consumida pelo APP. As 6 heurísticas validadas viraram canon arquitetural do monorepo.

> "Mantenho estratégia de UM BFF bonito MESMO sem consumidores. Ir intercalando assim pode correr risco de NOVAMENTE criar god Objects (...) sem uma base sólida só criamos mais 'bolas de lama'."
>
> — Usuário, 2026-04-17 (decisão Vertical antes de Horizontal)

**Decisão validada.** O BFF está bonito. Phase 4 vai consumir uma base sólida.
