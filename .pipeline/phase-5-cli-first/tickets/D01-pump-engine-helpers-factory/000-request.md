# D01 — PumpingSyncEngine extract + DriftExecutorFactory + helpers

## Onda: 1.5 (refactor débito) | Profile: refactor | Depende de: C00 | Não bloqueia: C01

## Motivação

`apps/social_care_bff/desktop/lib/src/facade/social_care_desktop.dart` acumulou 718 linhas com 6 responsabilidades (composition root, lifecycle, connectivity, drain pump, helpers, entry class). Análise completa em conversa-sessão 2026-05-02.

D01 é a **primeira de 3 ondas de refactor cirúrgico** (D01 → D02 → D03) que decompõem o catch-all sem alterar comportamento. Nenhuma das 3 muda surface pública nem regrida testes.

## Padrões aplicados (GoF)

- **Factory Method** — `DriftExecutorFactory` encapsula a decisão `:memory:` vs `createInBackground`. Nome formal pra um if que existe.
- (Observer + Builder ficam pra D03)
- (Decorator + Strategy reservados — D6/D7, sem demanda real hoje)

## Escopo

### NEW: `apps/social_care_bff/desktop/lib/src/sync/engine/pumping_sync_engine.dart`

Move a classe `_PumpingSyncEngine` (linhas 120-146 do `social_care_desktop.dart`) pra arquivo próprio dentro de `sync/engine/` — perto do `SyncEngine` que ela estende. Renomeia pra `PumpingSyncEngine` (sem underscore — não é mais privada do facade).

```dart
// Antes (oculto no facade):
class _PumpingSyncEngine extends SyncEngine { ... }

// Depois (público no sync layer):
class PumpingSyncEngine extends SyncEngine {
  PumpingSyncEngine({
    required super.outbox,
    required super.registry,
    required super.assessment,
    required super.care,
    required super.protection,
    required super.lookup,
    required StreamController<DrainSummary> drainController,
  }) : _drainController = drainController;
  // ... resto idêntico
}
```

### NEW: `apps/social_care_bff/desktop/lib/src/facade/composition/db_executor.dart`

`DriftExecutorFactory` (Factory Method) encapsula a decisão `:memory:` vs disk:

```dart
abstract interface class DriftExecutorFactory {
  QueryExecutor open(String filePath);

  /// Production: opens disk-backed databases via `NativeDatabase.createInBackground`,
  /// spawning a dedicated isolate per database. See ADR-021 for rationale on
  /// Drift's first-class multi-isolate support over Isar.
  static const DriftExecutorFactory production = _ProductionFactory();

  /// In-memory: opens transient databases via `NativeDatabase.memory()`. Used
  /// only by tests; in-memory databases stay on the calling isolate by design
  /// (Drift has no `createInBackground` for memory-backed databases).
  static const DriftExecutorFactory inMemory = _InMemoryFactory();
}

class _ProductionFactory implements DriftExecutorFactory {
  const _ProductionFactory();
  @override
  QueryExecutor open(String filePath) =>
      NativeDatabase.createInBackground(File(filePath));
}

class _InMemoryFactory implements DriftExecutorFactory {
  const _InMemoryFactory();
  @override
  QueryExecutor open(String filePath) => NativeDatabase.memory();
}
```

Também move `_defaultPath` (linha 684 do facade) pra esse mesmo arquivo como helper:

```dart
/// Resolves a file under `path_provider`'s `getApplicationDocumentsDirectory()`.
/// Tests that rely on the in-memory factory bypass this (they pass `:memory:`
/// directly).
Future<String> defaultDesktopFilePath(String fileName) async {
  final dir = await getApplicationDocumentsDirectory();
  return '${dir.path}/$fileName';
}
```

### NEW: `apps/social_care_bff/desktop/lib/src/facade/composition/connectivity_helpers.dart`

Move `_resultsAreOnline` (linha 716 do facade):

```dart
/// True if any [ConnectivityResult] in the list is non-`none`. The
/// `connectivity_plus` v7 plugin emits a list per change to support
/// devices with multiple active interfaces.
bool resultsAreOnline(List<ConnectivityResult> results) =>
    results.any((r) => r != ConnectivityResult.none);
```

### MOD: `apps/social_care_bff/desktop/lib/src/facade/social_care_desktop.dart`

- Remove a definição de `_PumpingSyncEngine` (substituída por import)
- Remove `_openDriftExecutor` (substituído por `DriftExecutorFactory.production.open(...)`)
- Remove `_defaultPath` (substituído por import)
- Remove `_resultsAreOnline` (substituído por import)
- Adiciona imports dos 3 novos arquivos
- **`create()` ganha parâmetro opcional `DriftExecutorFactory? executorFactory`** — default `production`. Tests passam `inMemory`. Backward-compatible (testes existentes continuam passando paths como `:memory:` literal e o factory production reconhece o marker).

**Edge case:** o factory `production` precisa também aceitar o marker `:memory:` pra preservar o contrato atual onde `cacheFilePath: ':memory:'` força in-memory. Solução: `_ProductionFactory.open()` chama `_InMemoryFactory.open()` quando recebe `':memory:'`. Documentar.

## Pipeline de refactor (3 waves — sem TDD RED, comportamento preservado)

| Wave | Agent | Output |
|------|-------|--------|
| W0 — Baseline | maestro:tester (ou Bash direto) | Confirma 426 GREEN no `apps/social_care_bff/desktop/` |
| W1 — Refactor | maestro:refactor OU flutter-bff-implementer | Move + rename + extract; behavior preserved |
| W2 — Review | flutter-code-reviewer | Audit: surface pública intocada, imports limpos, factory respeita `:memory:` marker |
| W3 — Quality | flutter-quality-checker | dart analyze 0; dart format clean; 426 GREEN preservados |

## Critérios de aceitação

- [ ] `apps/social_care_bff/desktop/lib/src/facade/social_care_desktop.dart` reduz de **718L → ~600L** (delta esperado ~118L)
- [ ] 3 arquivos novos criados (PumpingSyncEngine + db_executor + connectivity_helpers)
- [ ] Surface pública de `SocialCareDesktop` intocada — `create()`, `startSync()`, `stopSync()`, `close()`, `triggerDrain()`, sub-facades, `drainStream` mantidos
- [ ] `apps/social_care_bff/desktop/` test count **426 GREEN +1 skip** (mesmo baseline)
- [ ] `dart analyze apps/social_care_bff/desktop/lib/` zero issues
- [ ] BFF Web não regride — 1137 GREEN preservados
- [ ] Total BFF preservado — 2098 GREEN +1 skip

## NÃO fazer

- Não tocar em sub-facades (registry/assessment/...) — D02 é quem mexe nelas indiretamente via builders
- Não criar `DesktopAssembler` aqui — D03
- Não criar `AutoDrainObserver` aqui — D03
- Não adicionar Decorator a use cases — D6 reservado
- Não introduzir Strategy no SyncEngine — D7 reservado

## Status
ready — kickoff aguardando green light
