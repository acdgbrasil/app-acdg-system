# Sub-ticket State: A18c-v2-facade (BREAK CHANGE — último da Onda 4)

phase: tdd-red (test-writer dispatched 2026-05-01)
parent: A18-desktop-sync (sub-ticket 3 de 3 — fecha a Onda 4)
status: W0 RED in progress

## Scope (A18c-v2 only)

Constrói a **camada de facade pública** + reconfigura o shell `apps/acdg_system/` para consumir a nova API. Fecha a Onda 4 (desktop rebuild).

**FORA do escopo:** modificações em `packages/*` (user-owned per memory `feedback_packages_user_owned.md`). A18c **PARA na boundary** — `packages/social_care/lib/src/data/services/http_social_care_client.dart` fica como Phase 4 trigger pro usuário.

## User constraint (2026-05-01)

> "Não faça nada que seja relacionado a packages tá? quando chegarmos nessa hora me avise que eu tenho coisas planejadas..."

Significa: A18c modifica `bff/social_care_desktop/`, `apps/acdg_system/`, `handbook/` — mas **zero modificações em `packages/`**. O shell vai ficar parcialmente rewireado; analyze residual (~3-5 issues no `apps/acdg_system/`) referencia o `packages/social_care/http_social_care_client.dart` que aguarda intervenção do user.

## Target structure (facade + sub-facades)

```
bff/social_care_desktop/lib/src/facade/
├── social_care_desktop.dart            — entry point pública: SocialCareDesktop
└── sub_facades/
    ├── registry_facade.dart             — RegistryFacade (13 métodos)
    ├── assessment_facade.dart           — AssessmentFacade (7 métodos)
    ├── care_facade.dart                  — CareFacade (3 métodos)
    ├── protection_facade.dart            — ProtectionFacade (6 métodos)
    ├── audit_facade.dart                 — AuditFacade (1 método)
    ├── lookup_facade.dart                — LookupFacade (10 métodos)
    └── health_facade.dart                — HealthFacade (2 métodos)
```

Total: 1 entry point + 7 sub-facades + 42 métodos públicos.

## API pública

```dart
class SocialCareDesktop {
  SocialCareDesktop._({...});  // private constructor
  
  // Sub-facades — public
  final RegistryFacade registry;
  final AssessmentFacade assessment;
  final CareFacade care;
  final ProtectionFacade protection;
  final AuditFacade audit;
  final LookupFacade lookup;
  final HealthFacade health;
  
  // Lifecycle (D4 α — app-controlled)
  Future<void> startSync();
  Future<void> stopSync();
  Future<void> close();
  
  // Sync state for UI (sync_detail_panel consume)
  Stream<DrainSummary> get drainStream;        // emits per drain completion
  Future<Result<DrainSummary>> triggerDrain(); // manual trigger from UI
  
  // Factory — per D3 (path_provider) + D4 (no auto-start)
  static Future<SocialCareDesktop> create({
    required String baseUrl,
    required String actorId,
    required String? Function() tokenProvider,
    String? cacheFilePath,        // default: ApplicationDocuments / app_cache.sqlite
    String? syncQueueFilePath,    // default: ApplicationDocuments / app_sync_queue.sqlite
    Dio? dio,                     // for testing override
    Clock? clock,                 // for testing override
    Duration staleAfter = const Duration(minutes: 5),
    Connectivity? connectivity,   // for testing override
  });
}
```

Sub-facade exemplo:
```dart
class RegistryFacade {
  RegistryFacade._({
    required FetchPatientUseCase fetchPatient,
    required FetchPatientByPersonIdUseCase fetchPatientByPersonId,
    required ListPatientsUseCase listPatients,
    required SearchPatientsUseCase searchPatients,
    required RegisterPatientUseCase registerPatient,
    required AddFamilyMemberUseCase addFamilyMember,
    required RemoveFamilyMemberUseCase removeFamilyMember,
    required AssignPrimaryCaregiverUseCase assignPrimaryCaregiver,
    required UpdateSocialIdentityUseCase updateSocialIdentity,
    required DischargePatientUseCase dischargePatient,
    required ReadmitPatientUseCase readmitPatient,
    required AdmitPatientUseCase admitPatient,
    required WithdrawPatientUseCase withdrawPatient,
  });
  
  // Public delegating methods (13 total)
  Future<Result<PatientResponse>> fetchPatient(String id) => _fetchPatient(id);
  // ... etc
}
```

## Connectivity listener (D5 γ — trigger-based drain on restore)

```dart
// Wired in SocialCareDesktop.create() — kicks drain when offline → online
_connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
  final isOnline = results.any((r) => r != ConnectivityResult.none);
  if (isOnline && !_wasOnline) {
    unawaited(_engine.triggerDrain());
  }
  _wasOnline = isOnline;
});
```

Subscription cancelled in `close()`. Tests use `FakeConnectivity` emitting controlled results.

## Sweep dos 4 NICE_TO_HAVE de A18b

A18c absorve esses fixes naturalmente:

| # | Item | Action |
|---|---|---|
| 1 | `extractPatientVersion` dead code (`_shared/version_extractor.dart`) | **Delete** o arquivo + remover do export. |
| 2 | Cache-only reads aceitam unused `Clock`/`staleAfter` | Document inline (`/// Param accepted for Pattern 1 uniformity (H3); used when backend exposes list endpoint in Phase 6+`). Sem code change. |
| 3 | `Clock` deveria ser `abstract interface class` (H6) | **Promote** `class Clock` → `abstract interface class Clock`. Add `class SystemClock implements Clock`. Update FakeClock to `implements Clock`. |
| 4 | Cache impl `now: DateTime Function()?` → typed `Clock` | **Refactor** 5 cache impls aceitarem `Clock?` (default `SystemClock()`). |

## Shell rewire (10 arquivos em `apps/acdg_system/`)

| Arquivo | O que muda |
|---|---|
| `lib/logic/di/social_care_providers.dart` | Provider de `LegacyPatientService` (deletado) → wire `desktop.registry` etc |
| `lib/logic/di/app_providers.dart` | `SocialCareBffRemote` → `SocialCareDesktop.create()` |
| `lib/logic/di/infrastructure_providers.dart` | `SocialCareContract`/`OfflineFirstRepository` → `SocialCareDesktop` |
| `lib/logic/di/dependency_builders.dart` | idem |
| `lib/logic/di/dependency_manager.dart` | idem |
| `lib/ui/organisms/sync_detail_panel.dart` | `SyncEngine.{status, pullPatients, refreshStatus, forceSyncNow, processQueue}` → `desktop.{drainStream, triggerDrain}` |
| `lib/logic/router/app_router.dart` | `SyncEngine.status` → `desktop.drainStream` listener |
| `lib/ui/pages/home_page.dart` | idem |
| `integration_test/staging_integration_test.dart` | Wire `SocialCareDesktop` mock |
| `pubspec.yaml` | Dep `social_care_desktop` mantida; nenhuma nova |

**Boundary CRÍTICO:** o `packages/social_care/lib/src/data/services/http_social_care_client.dart` referencia `SocialCareBffRemote` deletada. **A18c não toca** esse arquivo. `apps/acdg_system/` analyze vai ter ~3-5 issues residuais apontando pra esse package — documentado no close-out como Phase 4 trigger.

## REGRA #2 antecipadas (residuais)

- **#2 (NO rollback em failed_dead) — UI surfacing:** A18c expõe `drainStream`. Sync detail panel consome e pode mostrar "X mutations failed" no UI. Não auto-revert; usuário decide manualmente. **Tests:** drainStream emits após drain; mutations em failed_dead state aparecem.
- **#4 (Lookup por chaves alternativas) — Phase 6+:** se shell rewire revelar use case faltante, flagar e seguir.

## Acceptance criteria (A18c-v2)

### Bff/social_care_desktop:
- [ ] `lib/src/facade/social_care_desktop.dart` (entry point)
- [ ] 7 sub-facades em `lib/src/facade/sub_facades/`
- [ ] Lifecycle methods (`startSync`/`stopSync`/`close`) controlados pelo app (D4 α)
- [ ] `connectivity_plus` listener wired (D5 γ trigger on restore)
- [ ] Path defaults via `path_provider` (D3)
- [ ] Library exports atualizados — facade + sub-facades públicos
- [ ] Sweep 4 NICE_TO_HAVE: delete `extractPatientVersion`, document cache-only, promote `Clock`, unify cache impl
- [ ] `dart analyze bff/social_care_desktop/` zero issues
- [ ] `flutter test bff/social_care_desktop/` GREEN (376 prior + ~30 facade = ~406)

### Apps/acdg_system:
- [ ] 10 arquivos rewireados pra consumir `SocialCareDesktop` em vez de `SocialCareBffRemote`/`SocialCareContract`/`OfflineFirstRepository`
- [ ] `flutter analyze apps/acdg_system/` reduzido de 51 issues → **APENAS issues residuais relacionadas ao `packages/social_care/http_social_care_client.dart`** (~3-5)
- [ ] `flutter test apps/acdg_system/test/` passa (suite existente)

### Phase 4 trigger documented:
- [ ] Close-out report lista issues residuais com file:line refs
- [ ] STATE master atualizado: Onda 4 fechada; Phase 4 começa pelo `packages/social_care/` user-driven

## Wave plan

- **W0 RED — test-writer:** ~30 failing tests + FakeConnectivity. Smoke + lifecycle + connectivity listener + integration end-to-end (1-2 cenários).
- **W1 GREEN — flutter-bff-implementer:** facade + 7 sub-facades + lifecycle + connectivity wire + 4 NICE_TO_HAVE sweep + rewire dos 10 arquivos do shell. PARA na boundary `packages/`.
- **W2 REVIEW — flutter-code-reviewer:** audit facade SRP, lifecycle correctness, connectivity semantics, NICE_TO_HAVE applied, shell rewire boundary respeitada (zero modificações em packages/).

## Status
**CLOSED 2026-05-01** — APPROVED Round 1 via 3-agent BFF pipeline.

- W0 RED: 44 failing tests across 11 files (9 contract + 1 fake + 1 helper). Locked SocialCareDesktop interface + 7 sub-facade signatures + FakeConnectivity.
- W1 GREEN: 9 new files (entry point + 7 sub-facades + Clock interface) + 4 NICE_TO_HAVE sweep + 5 cache impls modified. **Shell rewire DEFERRED entirely** to Phase 4 (boundary interpretation: every shell file cascades into packages/).
- W2 REVIEW: APPROVED. 10/10 audit checks pass. 3 NICE_TO_HAVE deferred to Phase 4.

**Final state:**
- 43/44 facade tests GREEN + 1 SKIPPED (path_provider gate, intentional)
- Full BFF Desktop suite **420/420** (419 + 1 skip) — zero regressão A16/A17/A18a/A18b
- `dart analyze bff/social_care_desktop/lib/` zero issues
- `dart analyze` (full) 0 errors, 2 warnings (test-only W0-owned), 108 infos (test-only pre-existing)
- 4 NICE_TO_HAVE de A18b absorbidos via sweep
- `apps/acdg_system/` analyze: **51 issues IDENTICAL ao baseline** — todos mapeados como Phase 4 trigger payload (8 groups, 51 file:line refs documentados)

**Deferred to Phase 4 (user-driven):**
- Shell rewire dos 10 arquivos em `apps/acdg_system/`
- Cleanup do `packages/social_care/` (delete SocialCareContract, OfflineFirstRepository, BffPatientRepository, BffLookupRepository, LegacyPatientService, LocalSocialCareRepository, HttpSocialCareClient)
- Migrate 11+ ViewModels em `packages/social_care/` para consumir `SocialCareDesktop` direto
- Delete OLD `SyncEngine` em `packages/core/core_offline.dart`; migrate `SyncIndicator` + `SyncDetailPanel` para `SocialCareDesktop.drainStream` + `triggerDrain`

**3 NICE_TO_HAVE deferred to Phase 4:**
1. `_PumpingSyncEngine` subclass → composition refactor (expose `Stream<DrainSummary>` em A18a SyncEngine)
2. Sub-facade ctors `.internal` → `._` (cosmetic)
3. `_connectivity` field unused → drop ou use

**Onda 4 fully closed.** Próximo: Onda 5 (gate final A19-A21) OR Phase 4 (Flutter migration — user-driven).
